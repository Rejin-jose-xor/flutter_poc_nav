import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Notifier, NotifierProvider, Provider;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/expense_model.dart' show Expense;
import '../services/expense_remote_service.dart'
    show ExpenseRemoteService;

class ExpensesNotifier extends Notifier<List<Expense>> {
  static const String _boxName = 'expensesBox';
  static const String _key = 'expenses';

  static const int _pageSize = 3;
  final int fetchSize = _pageSize + 1;

  Box<dynamic> get _box => Hive.box(_boxName);

  /// Stack of cursors (enteredAt millis)
  /// Each entry represents the LAST item of a page
  final List<int> _cursorStack = [];

  /// Whether another page exists AFTER the current page
  bool _hasNextPage = false;
  bool _isPagingStable = true;


  // ---------------------------------------------------------------------------
  // Paging getters (UI-safe)
  // ---------------------------------------------------------------------------

  bool get canGoNext => _hasNextPage;
  bool get canGoFirst => !_isPagingStable;
  bool get canGoPrev  => _isPagingStable && _cursorStack.length > 1;
  bool get isOnFirstPage => _cursorStack.length <= 1;

  // ---------------------------------------------------------------------------
  // Build (Hive hydration)
  // ---------------------------------------------------------------------------

  @override
  List<Expense> build() {
    final stored = _box.get(_key) as List<dynamic>?;
    if (stored == null) return <Expense>[];

    try {
      return stored
          .whereType<Map>()
          .map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <Expense>[];
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _saveToHive() {
    final listOfMaps = state.map((e) => e.toMap()).toList();
    _box.put(_key, listOfMaps);
  }

  /// Force Riverpod rebuild when only paging metadata changed
  void _emitSameState() {
    state = [...state];
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> addExpense(Expense expense) async {
    await ExpenseRemoteService.createExpense(expense);
    await loadFirstPage();
  }

Future<bool> deleteById(String id) async {
  await ExpenseRemoteService.deleteExpense(id);

  _isPagingStable = false; // history invalid
  _emitSameState();        // FORCE UI UPDATE NOW

  await _reloadCurrentPage();
  return true;
}

Future<bool> replaceExpense(Expense updated) async {
  await ExpenseRemoteService.updateExpense(updated);

  _isPagingStable = false;
  _emitSameState();        // FORCE UI UPDATE NOW

  await _reloadCurrentPage();
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
    await ExpenseRemoteService.clearAll();
    state = [];
    _cursorStack.clear();
    _hasNextPage = false;
    _saveToHive();
  }

  // ---------------------------------------------------------------------------
  // Paging
  // ---------------------------------------------------------------------------

  /// Load the latest page
  Future<void> loadFirstPage() async {
    _cursorStack.clear();
    _isPagingStable = true; // history rebuilt from source of truth

    final fetched = await ExpenseRemoteService.fetchExpensesPage(
      pageSize: fetchSize,
    );

    _hasNextPage = fetched.length > _pageSize;

    final expenses = fetched.take(_pageSize).toList();
    state = expenses;
    _saveToHive();

    if (expenses.isNotEmpty) {
      _cursorStack.add(
        expenses.last.enteredAt.millisecondsSinceEpoch,
      );
    }

    _emitSameState();
  }


  /// Load next (older) page
  Future<void> loadNextPage() async {
    if (!canGoNext) return;

    final endAt = _cursorStack.last - 1;

    final fetched = await ExpenseRemoteService.fetchExpensesPage(
      pageSize: fetchSize,
      endAt: endAt,
    );

    _hasNextPage = fetched.length > _pageSize;

    final expenses = fetched.take(_pageSize).toList();
    if (expenses.isEmpty) return;

    state = expenses;
    _saveToHive();

    _cursorStack.add(
      expenses.last.enteredAt.millisecondsSinceEpoch,
    );

    _emitSameState();
  }

  /// Load previous (newer) page
  Future<void> loadPrevPage() async {
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
    state = expenses;
    _saveToHive();

    _emitSameState();
  }

  // ---------------------------------------------------------------------------
  // Internal reload (used after delete/update)
  // ---------------------------------------------------------------------------

  Future<void> _reloadCurrentPage() async {
    int? endAt;

    if (_cursorStack.length > 1) {
      endAt = _cursorStack[_cursorStack.length - 2] - 1;
    }

    final fetched = await ExpenseRemoteService.fetchExpensesPage(
      pageSize: fetchSize,
      endAt: endAt,
    );

    _hasNextPage = fetched.length > _pageSize;

    final expenses = fetched.take(_pageSize).toList();

    // Edge case: page became empty after delete → go back
    if (expenses.isEmpty && _cursorStack.length > 1) {
      _cursorStack.removeLast();
      await loadPrevPage();
      return;
    }

    state = expenses;
    _saveToHive();
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
