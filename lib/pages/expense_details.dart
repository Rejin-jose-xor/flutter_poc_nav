import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'package:intl/intl.dart' show DateFormat;
import 'package:go_router/go_router.dart';
import '../app_route_constants.dart' show MyAppRouteConstants;
import '../models/expense_model.dart' show Expense;
import '../provider/expense_provider.dart' show expensesProvider;

class ExpenseDetails extends ConsumerWidget {
  final String expenseId;
  const ExpenseDetails({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider so the UI updates when the list changes
    final expenses = ref.watch(expensesProvider);
    // Find the expense safely
    Expense? expenseData;
    for (final e in expenses) {
      if (e.id == expenseId) {
        expenseData = e;
        break;
      }
    }

    // If item not found, schedule a safe pop and show placeholder
    if (expenseData == null) {
      final router = GoRouter.of(context);
      final navigator = Navigator.of(context);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.canPop()) {
          router.pop();
        } else {
          router.go('/expenses');
        }
      });

      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('This expense was removed. Returning...')),
        ),
      );
    }


    // Non-null: show the details UI
    final notifier = ref.read(expensesProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            title: Text(
              expenseData.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  expenseData.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text('${DateFormat('yyyy-MM-dd').format(expenseData.date)} -- ${expenseData.category.name}'),
                Text('Amount: ₹${expenseData.amount.toStringAsFixed(2)}'),
                const SizedBox(height: 15),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        GoRouter.of(context).pushNamed(
                          MyAppRouteConstants.expenseEditRouteName,
                          pathParameters: {'id': expenseData!.id},
                        );
                      },
                      child: const Text('Edit this expense'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        // simple delete confirmation
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete expense?'),
                            content: Text('Delete "${expenseData!.title}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () async {
                                  // Close dialog first (sync, safe)
                                  Navigator.of(ctx).pop();

                                  final router = GoRouter.of(context);
                                  final messenger = ScaffoldMessenger.of(context);

                                  try {
                                    final deleted =
                                        await notifier.deleteById(expenseData!.id);

                                    if (deleted) {
                                      // Navigate back safely
                                      router.pop();
                                    }
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Failed to delete expense')),
                                    );
                                  }
                                },
                                child: const Text('Delete'),
                              ),

                            ],
                          ),
                        );
                      },
                      child: const Text('Delete This?'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
