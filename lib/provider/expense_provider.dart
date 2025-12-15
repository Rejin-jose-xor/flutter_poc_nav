import 'package:flutter_riverpod/flutter_riverpod.dart' show Notifier, NotifierProvider;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart' show Expense;
import '../constants/common.dart' show Category;

class ExpensesNotifier extends Notifier<List<Expense>> {
  static const String _boxName = 'expensesBox';
  static const String _key = 'expenses';

  Box<dynamic> get _box => Hive.box(_boxName);

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
  void addExpense(Expense expense) {
    state = [...state, expense];
    _saveToHive();
  }

  /// Delete by id
  bool deleteById(String id) {
    final before = state.length;
    state = state.where((e) => e.id != id).toList();
    final after = state.length;
    final changed = before != after;
    if (changed) _saveToHive();
    return changed;
  }

  /// Edit using copyWith
  bool editExpense(
    String id, {
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
    String? description,
  }) {
    bool found = false;

    state = state.map((e) {
      if (e.id != id) return e;
      found = true;
      return e.copyWith(
        title: title,
        amount: amount,
        date: date,
        category: category,
        description: description,
      );
    }).toList();

    if (found) _saveToHive();
    return found;
  }

  /// Replace whole expense with updated object (shortcut)
  bool replaceExpense(Expense updated) {
    bool exists = false;

    state = state.map((e) {
      if (e.id == updated.id) {
        exists = true;
        return updated;
      }
      return e;
    }).toList();

    if (exists) _saveToHive();

    return exists;
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
  void clear() {
    state = [];
    _saveToHive();
  }
}

final expensesProvider =
    NotifierProvider<ExpensesNotifier, List<Expense>>(ExpensesNotifier.new);
