import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'package:go_router/go_router.dart';
import '../provider/expense_provider.dart' show expensesProvider;
import '../sections/expense_form.dart' show ExpenseForm;
import '../models/expense_model.dart' show Expense;

class ExpenseEdit extends ConsumerWidget {
  final String expenseId;
  const ExpenseEdit({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final original = ref.read(expensesProvider.notifier).getById(expenseId);
    if (original == null) {
      // show fallback UI
      return const Scaffold(
        body: Center(child: Text('Expense not found')),
      );
    }

    return Scaffold(
      body: ExpenseForm(
        initialExpense: original,
        onSaved: (Expense updated) async {
          final messenger = ScaffoldMessenger.of(context);
          final router = GoRouter.of(context);

          try {
            final replaced =
                await ref.read(expensesProvider.notifier).replaceExpense(updated);

            if (!replaced) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Failed to update expense')),
              );
              return;
            }

            router.pop(); // success → close edit screen
          } catch (e) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Failed to update expense')),
            );
          }
        },

        onCancelled: () => Navigator.of(context).pop(),
      ),
    );
  }
}