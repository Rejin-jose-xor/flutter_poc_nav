import 'package:flutter_riverpod/flutter_riverpod.dart' show Notifier, NotifierProvider, Provider;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart' show Expense;
import '../services/expense_remote_service.dart' show ExpenseRemoteService;

class ExpensesNotifier extends Notifier<List<Expense>> {
  static const String _boxName = 'expensesBox';
  static const String _key = 'expenses';

  Box<dynamic> get _box => Hive.box(_boxName);

  final List<int> _cursorStack = [];
  // enteredAt of last item
  static const _pageSize = 3;
  bool get canGoNext => _hasNextPage; 
  bool get canGoPrev => _pagingStable && _cursorStack.length > 1;
  bool get canGoFirst => !_pagingStable && !isOnFirstPage;
  bool _pagingStable = true;
  bool _hasNextPage = false;
  bool get isOnFirstPage => _cursorStack.length <= 1;
  final fetchSize = _pageSize + 1;






  @override
  List<Expense> build() {

    final stored = _box.get(_key) as List<dynamic>?;
    if (stored == null) return <Expense>[];

    try {
      // Each item expected to be Map<String, dynamic>
      final expenses = stored.map((e) {
        // be tolerant to types (if map was stored as Map)
        if (e is Map) {
          // convert to Map<String, dynamic>
          final map = Map<String, dynamic>.from(e);
          return Expense.fromMap(map);
        } else {
          // if it's something unexpected, skip by returning null
          return null;
        }
      }).whereType<Expense>().toList();

      return expenses;
    } catch (err) {
      // If parse errors happen, log and return empty list
      // (you can optionally clear the stored data)
      // print('Error loading expenses from hive: $err');
      return <Expense>[];
    }

  }

  // helper to persist current state to Hive
  void _saveToHive() {
    final listOfMaps = state.map((e) => e.toMap()).toList();
    _box.put(_key, listOfMaps);
  }

  /// Add an expense
  Future<void> addExpense(Expense expense) async {
    // 1. Save to Firebase first
    await ExpenseRemoteService.createExpense(expense);

    // 2. Re-sync paging from backend
    await loadFirstPage();

    // 3. Persist to Hive
    _saveToHive();
  }

  /// Delete by id
  Future<bool> deleteById(String id) async {
    await ExpenseRemoteService.deleteExpense(id);

    _pagingStable = false;
    await _reloadCurrentPage();
    return true;
  }


  /// Replace whole expense with updated object (shortcut)
  Future<bool> replaceExpense(Expense updated) async {
    await ExpenseRemoteService.updateExpense(updated);

    _pagingStable = false;
    await _reloadCurrentPage();
    return true;
  }


  /// Get a single expense
  Expense? getById(String id) {
    try {
      return state.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clear all
  Future<void> clear() async {
    await ExpenseRemoteService.clearAll();

    state = [];
    _saveToHive();
  }

  Future<void> loadFirstPage() async {
    _pagingStable = true;
    _cursorStack.clear();

    final fetched = await ExpenseRemoteService.fetchExpensesPage(
      pageSize: _pageSize + 1, // lookahead
    );

    // Determine next page existence
    _hasNextPage = fetched.length > _pageSize;

    // Trim to visible page
    final expenses = fetched.take(_pageSize).toList();

    state = expenses;
    _saveToHive();

    if (expenses.isNotEmpty) {
      _cursorStack.add(
        expenses.last.enteredAt.millisecondsSinceEpoch,
      );
    }
  }




  Future<void> loadNextPage() async {
    if (!canGoNext) return;

    final currentCursor = _cursorStack.last;

    final fetched = await ExpenseRemoteService.fetchExpensesPage(
      pageSize: _pageSize + 1, // lookahead
      endAt: currentCursor - 1,
    );

    _hasNextPage = fetched.length > _pageSize;

    final expenses = fetched.take(_pageSize).toList();

    if (expenses.isEmpty) return;

    state = expenses;
    _saveToHive();

    _cursorStack.add(
      expenses.last.enteredAt.millisecondsSinceEpoch,
    );
  }




  Future<void> loadPrevPage() async {
    // Cannot go back from first page
    if (_cursorStack.length <= 1) return;

    // Remove current page cursor
    _cursorStack.removeLast();

    final prevCursor = _cursorStack.length == 1
        ? null
        : _cursorStack[_cursorStack.length - 2];

    final fetched = await ExpenseRemoteService.fetchExpensesPage(
      pageSize: _pageSize + 1, // 👈 LOOKAHEAD
      endAt: prevCursor != null ? prevCursor - 1 : null,
    );

    _hasNextPage = fetched.length > _pageSize;

    final expenses = fetched.take(_pageSize).toList();

    state = expenses;
    _saveToHive();
  }

  Future<void> _reloadCurrentPage() async {
    // Always re-fetch based on CURRENT visible page,
    // not historical cursor stack

    int? endAt;

    if (_cursorStack.length > 1) {
      // Current page boundary
      endAt = _cursorStack[_cursorStack.length - 2] - 1;
    }

    final fetched = await ExpenseRemoteService.fetchExpensesPage(
    pageSize: _pageSize + 1, // LOOKAHEAD
    endAt: endAt,
  );

  _hasNextPage = fetched.length > _pageSize;

  final expenses = fetched.take(_pageSize).toList();

    // Always update state (even empty)
    state = expenses;
    _saveToHive();

    // Rebuild cursor stack from fresh data
    _resetCursorFromCurrentPage(expenses);
  }


  void _resetCursorFromCurrentPage(List<Expense> expenses) {
  _cursorStack.clear();

  if (expenses.isEmpty) return;

  final lastCursor =
      expenses.last.enteredAt.millisecondsSinceEpoch;

  _cursorStack.add(lastCursor);
}


}

final expensesProvider =
    NotifierProvider<ExpensesNotifier, List<Expense>>(ExpensesNotifier.new);



final canGoNextProvider = Provider<bool>((ref) {
  final notifier = ref.read(expensesProvider.notifier);
  return notifier.canGoNext;
});

final canGoPrevProvider = Provider<bool>((ref) {
  final notifier = ref.read(expensesProvider.notifier);
  return notifier.canGoPrev;
});

final canGoFirstProvider = Provider<bool>((ref) {
  final notifier = ref.read(expensesProvider.notifier);
  return notifier.canGoFirst;
});
