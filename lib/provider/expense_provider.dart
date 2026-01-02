import 'package:flutter_riverpod/flutter_riverpod.dart'show Notifier, NotifierProvider, Provider;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart' show Expense;
import '../services/expense_remote_service.dart'show ExpenseRemoteService;
import 'internet_status_provider.dart' show isOnlineProvider;

class ExpensesNotifier extends Notifier<List<Expense>> {
  static const String _boxName = 'expensesBox';

  static const String _expensePrefix = 'expense:'; // expense:{id}
  static const String _metaLastSync = 'meta:lastSyncAt';
  static const String _metaPendingOps = 'meta:pendingOps';

  static const int _maxLocalRecords = 2000;

  static const int _pageSize = 3;
  final int fetchSize = _pageSize + 1;

  Box<dynamic> get _box => Hive.box(_boxName);

  /// Stack of cursors (enteredAt millis)
  /// Each entry represents the LAST item of a page
  final List<int> _cursorStack = [];

  /// Whether another page exists AFTER the current page
  bool _hasNextPage = false;
  bool _isPagingStable = true;

  bool get _useLocalPaging => !_isOnline;
  int _localPageIndex = 0;

  bool get _isOnline => ref.read(isOnlineProvider);




  void resetLocalPaging() {
    _localPageIndex = 0;
  }

  String? getSyncStatus(String id) {
    final raw = _box.get('$_expensePrefix$id');
    return raw is Map ? raw['_sync'] as String? : null;
  }


  // ---------------------------------------------------------------------------
  // Paging getters (UI-safe)
  // ---------------------------------------------------------------------------

  bool get canGoNext {
    if (_useLocalPaging) {
      final total = _getLocalSortedExpenses().length;
      return (_localPageIndex + 1) * _pageSize < total;
    }
    return _hasNextPage;
  }

  bool get canGoPrev {
    if (_useLocalPaging) {
      return _localPageIndex > 0;
    }
    return _isPagingStable && _cursorStack.length > 1;
  }

  bool get canGoFirst {
    return !_isPagingStable;
  }

  bool get isOnFirstPage => _cursorStack.length <= 1;

  // ---------------------------------------------------------------------------
  // Build (Hive hydration)
  // ---------------------------------------------------------------------------

  @override
  List<Expense> build() {
    final expenses = <Expense>[];

    for (final key in _box.keys) {
      if (key is String && key.startsWith(_expensePrefix)) {
        final raw = _box.get(key);
        if (raw is Map) {
          try {
            expenses.add(
              Expense.fromMap(Map<String, dynamic>.from(raw)),
            );
          } catch (_) {}
        }
      }
    }

    // Sort newest → oldest (same behavior as Firebase)
    expenses.sort((a, b) => b.enteredAt.compareTo(a.enteredAt));

    return expenses;
  }



  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Force Riverpod rebuild when only paging metadata changed
  void _emitSameState() {
    state = [...state];
  }

  void _putExpense(Expense e, {String sync = 'synced'}) {
    final map = e.toMap()
      ..['_sync'] = sync
      ..['_updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    _box.put('$_expensePrefix${e.id}', map);
  }

  void _deleteExpenseLocal(String id) {
    _box.delete('$_expensePrefix$id');
  }

  void _enforceLimit() {
    final keys = _box.keys
        .whereType<String>()
        .where((k) => k.startsWith(_expensePrefix))
        .toList();

    if (keys.length <= _maxLocalRecords) return;

    final expenses = keys.map((k) {
      final m = _box.get(k) as Map;
      return MapEntry(
        k,
        m['enteredAt'] as int? ?? 0,
      );
    }).toList();

    // Oldest first
    expenses.sort((a, b) => a.value.compareTo(b.value));

    final toRemove = expenses.take(expenses.length - _maxLocalRecords);

    for (final e in toRemove) {
      _box.delete(e.key);
    }
  }

  // ---------------------------------------------------------------------------
  // OFFLINE PENDING OPERATIONS
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _getPendingOps() {
    final raw = _box.get(_metaPendingOps, defaultValue: []);

    return (raw as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }


  void _savePendingOps(List<Map<String, dynamic>> ops) {
    _box.put(_metaPendingOps, ops);
  }

  void _addPendingOp(Map<String, dynamic> op) {
    final ops = _getPendingOps();
    ops.add(op);
    _savePendingOps(ops);
  }


  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> addExpense(Expense expense) async {
    //  Always write locally first
    _putExpense(expense, sync: 'pendingCreate');

    //  Try remote write
    try {
      await ExpenseRemoteService.createExpense(expense);
      _putExpense(expense, sync: 'synced');
    } catch (_) {
      _addPendingOp({
        'type': 'create',
        'expenseId': expense.id,
        'payload': expense.toMap(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    //  Reload page instead of mutating state
    await loadFirstPage();
  }





  Future<bool> deleteById(String id) async {
    final isOnline = _isOnline;

    //  Remove from Hive immediately
    _deleteExpenseLocal(id);

    // DO NOT touch state here

    //  Offline → queue and exit
    if (!isOnline) {
      _addPendingOp({
        'type': 'delete',
        'expenseId': id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      await _reloadLocalPageAfterDelete();
      return true;
    }

    // Online → delete remotely
    try {
      await ExpenseRemoteService.deleteExpense(id);
       _isPagingStable = false;
    } catch (_) {
      _addPendingOp({
        'type': 'delete',
        'expenseId': id,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    }

    // Reload page atomically
    await _reloadCurrentPage();

    return true;
  }




  Future<bool> replaceExpense(Expense updated) async {
    // Optimistic local update — ALWAYS pending first
    _putExpense(updated, sync: 'pendingUpdate');

    state = [
      for (final e in state)
        if (e.id == updated.id) updated else e
    ];
    _emitSameState();

    // ALWAYS try remote update
    try {
      await ExpenseRemoteService.updateExpense(updated);

      //  Mark as synced ONLY on success
      _putExpense(updated, sync: 'synced');
      _emitSameState();
    } catch (e) {
      //  Queue if remote fails
      _addPendingOp({
        'type': 'update',
        'expenseId': updated.id,
        'payload': updated.toMap(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }

    return true;
  }



  Expense? getById(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    if (_isOnline) {
      await ExpenseRemoteService.clearAll();
    }

    final keys = _box.keys
      .whereType<String>()
      .where((k) => k.startsWith(_expensePrefix))
      .toList();

    for (final k in keys) {
      _box.delete(k);
    }
    state = [];
    _cursorStack.clear();
    _hasNextPage = false;
  }

  // ---------------------------------------------------------------------------
  //FRONT END - BACK END SYNCHRONIZATION
  // ---------------------------------------------------------------------------

  Future<void> syncPendingOps() async {
    // Use a copy to avoid concurrent modification issues
    final ops = List<Map<String, dynamic>>.from(_getPendingOps());
    if (ops.isEmpty) return;

    final remainingOps = List<Map<String, dynamic>>.from(ops);

    for (final op in ops) {
      try {
        final type = op['type'];
        final payload = op['payload'] != null ? Map<String, dynamic>.from(op['payload']) : null;

       if (type == 'create') {
        final expense = Expense.fromMap(payload!);
        await ExpenseRemoteService.createExpense(expense);
        _putExpense(expense, sync: 'synced');
      } 
      else if (type == 'update') {
        final expense = Expense.fromMap(payload!);
        await ExpenseRemoteService.updateExpense(expense);
        _putExpense(expense, sync: 'synced');
      }
      else if (type == 'delete') {
          await ExpenseRemoteService.deleteExpense(op['expenseId']);
        }

        // Success! Remove ONLY this specific operation from the queue
        remainingOps.remove(op);
        _savePendingOps(remainingOps); 
               
      } catch (e) {
        // Network failed? Stop and keep remaining items in the queue for next time
        return; 
      }
    }

    if (remainingOps.isEmpty) {
      _box.put(
        _metaLastSync,
        DateTime.now().millisecondsSinceEpoch,
      );
    }

  }


  // ---------------------------------------------------------------------------
  // Paging
  // ---------------------------------------------------------------------------

  /// Load the latest page
  Future<void> loadFirstPage() async {
    // If offline, ALWAYS use local data
    if (_useLocalPaging) {
      _localPageIndex = 0;
      final all = _getLocalSortedExpenses();
      state = all.take(_pageSize).toList();
      _emitSameState();
      return;
    }

    // Online path guarded with try/catch
    try {
      _cursorStack.clear();
      _isPagingStable = true;

      final fetched = await ExpenseRemoteService.fetchExpensesPage(
        pageSize: fetchSize,
      );

      _hasNextPage = fetched.length > _pageSize;

      final expenses = fetched.take(_pageSize).toList();
      for (final e in expenses) {
        _putExpense(e);
      }

      _enforceLimit();
      state = expenses;

      if (expenses.isNotEmpty) {
        _cursorStack.add(
          expenses.last.enteredAt.millisecondsSinceEpoch,
        );
      }

      _emitSameState();
    } catch (_) {
      // Network failed → fallback to local
      _localPageIndex = 0;
      final all = _getLocalSortedExpenses();
      state = all.take(_pageSize).toList();
      _emitSameState();
    }
  }



  /// Load next (older) page
  Future<void> loadNextPage() async {

    if (_useLocalPaging) {
      _localPageIndex++;

      final all = _getLocalSortedExpenses();
      final start = _localPageIndex * _pageSize;
      final page = all.skip(start).take(_pageSize).toList();

      state = page;
      _emitSameState();
      return;
    }

    if (!canGoNext) return;

    final endAt = _cursorStack.last - 1;

    final fetched = await ExpenseRemoteService.fetchExpensesPage(
      pageSize: fetchSize,
      endAt: endAt,
    );

    _hasNextPage = fetched.length > _pageSize;

    final expenses = fetched.take(_pageSize).toList();
    if (expenses.isEmpty) return;

    for (final e in expenses) {
      _putExpense(e);
    }

    _enforceLimit();

    state = expenses;

    _cursorStack.add(
      expenses.last.enteredAt.millisecondsSinceEpoch,
    );

    _emitSameState();
  }

  /// Load previous (newer) page
  Future<void> loadPrevPage() async {
    
    if (_useLocalPaging) {
      if (_localPageIndex == 0) return;

      _localPageIndex--;

      final all = _getLocalSortedExpenses();
      final start = _localPageIndex * _pageSize;
      state = all.skip(start).take(_pageSize).toList();
      _emitSameState();
      return;
    }

    if (_cursorStack.length <= 1) return;

    // Remove current page cursor
    _cursorStack.removeLast();

    final prevCursor =
        _cursorStack.length == 1 ? null : _cursorStack.last - 1;

    final fetched = await ExpenseRemoteService.fetchExpensesPage(
      pageSize: fetchSize,
      endAt: prevCursor,
    );

    _hasNextPage = fetched.length > _pageSize;

    final expenses = fetched.take(_pageSize).toList();
        for (final e in expenses) {
      _putExpense(e);
    }

    _enforceLimit();

    state = expenses;

    _emitSameState();
  }

  // ---------------------------------------------------------------------------
  // LOCAL PAGINATION LOGIC
  // ---------------------------------------------------------------------------

  List<Expense> _getLocalSortedExpenses() {
    final expenses = <Expense>[];

    for (final key in _box.keys) {
      if (key is String && key.startsWith(_expensePrefix)) {
        final raw = _box.get(key);
        if (raw is Map) {
          try {
            expenses.add(
              Expense.fromMap(Map<String, dynamic>.from(raw)),
            );
          } catch (_) {}
        }
      }
    }

    expenses.sort((a, b) => b.enteredAt.compareTo(a.enteredAt));
    return expenses;
  }

  // ---------------------------------------------------------------------------
  // LOCAL DELETE LOGIC
  // ---------------------------------------------------------------------------

  Future<void> _reloadLocalPageAfterDelete() async {
    final all = _getLocalSortedExpenses();

    // If current page became invalid, go back one page
    final start = _localPageIndex * _pageSize;
    if (start >= all.length && _localPageIndex > 0) {
      _localPageIndex--;
    }

    final page = all
        .skip(_localPageIndex * _pageSize)
        .take(_pageSize)
        .toList();

    state = page;
    _emitSameState();
  }


  // ---------------------------------------------------------------------------
  // Internal reload (used after delete/update)
  // ---------------------------------------------------------------------------

  Future<void> _reloadCurrentPage() async {
    int? endAt;

    // Case: we are on page > 1
    if (_cursorStack.length > 1) {
      endAt = _cursorStack[_cursorStack.length - 2] - 1;
    }

    // Try to reload CURRENT page
    final fetched = await ExpenseRemoteService.fetchExpensesPage(
      pageSize: fetchSize,
      endAt: endAt,
    );

    final expenses = fetched.take(_pageSize).toList();

    // Case 1: page still has items → stay on same page
    if (expenses.isNotEmpty) {
      _hasNextPage = fetched.length > _pageSize;

      for (final e in expenses) {
        _putExpense(e);
      }

      _enforceLimit();
      state = expenses;
      _emitSameState();
      return;
    }

    // Case 2: page is empty → go back ONE page
    if (_cursorStack.length > 1) {
      _cursorStack.removeLast(); // remove empty page cursor

      final prevEndAt =
          _cursorStack.length > 1 ? _cursorStack[_cursorStack.length - 2] - 1 : null;

      final prevFetched = await ExpenseRemoteService.fetchExpensesPage(
        pageSize: fetchSize,
        endAt: prevEndAt,
      );

      final prevExpenses = prevFetched.take(_pageSize).toList();

      _hasNextPage = false;

      for (final e in prevExpenses) {
        _putExpense(e);
      }

      _enforceLimit();
      state = prevExpenses;
      _emitSameState();
      return;
    }

    // Case 3: first page & empty → no data left
    state = [];
    _hasNextPage = false;
    _emitSameState();
  }


}

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

final expensesProvider =
    NotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

final canGoNextProvider = Provider<bool>((ref) {
  ref.watch(expensesProvider); // makes it reactive
  return ref.read(expensesProvider.notifier).canGoNext;
});

final canGoPrevProvider = Provider<bool>((ref) {
  ref.watch(expensesProvider);
  return ref.read(expensesProvider.notifier).canGoPrev;
});

final canGoFirstProvider = Provider<bool>((ref) {
  ref.watch(expensesProvider);
  return ref.read(expensesProvider.notifier).canGoFirst;
});

final expenseSyncStatusProvider = Provider.family<String?, String>((ref, id) {
  ref.watch(expensesProvider); // react to changes
  return ref.read(expensesProvider.notifier).getSyncStatus(id);
});
