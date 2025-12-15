import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'package:go_router/go_router.dart';
import '../provider/expense_provider.dart' show expensesProvider;
import '../sections/expense_form.dart' show ExpenseForm;
import '../models/expense_model.dart' show Expense;

class ExpenseCreate extends ConsumerWidget {
  const ExpenseCreate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ExpenseForm(
        onSaved: (Expense e) {
          ref.read(expensesProvider.notifier).addExpense(e);
          context.pop();
        },
        onCancelled: () => Navigator.of(context).pop(),
      ),
    );
  }
}