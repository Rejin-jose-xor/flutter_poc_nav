import 'expense_model.dart' show Expense;

class ExpensesPageState {
  final List<Expense> expenses;
  final bool canGoNext;
  final bool canGoPrev;
  final bool canGoFirst;

  const ExpensesPageState({
    required this.expenses,
    required this.canGoNext,
    required this.canGoPrev,
    required this.canGoFirst,
  });
}
