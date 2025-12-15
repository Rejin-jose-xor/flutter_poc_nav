import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'package:intl/intl.dart' show DateFormat;
import 'package:go_router/go_router.dart';
import '../app_route_constants.dart' show MyAppRouteConstants;
import '../models/expense_model.dart' show Expense;
import '../provider/expense_provider.dart' show expensesProvider;

class ExpenseListItem extends ConsumerWidget {
  final Expense expense;

  const ExpenseListItem({
    super.key,
    required this.expense
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(expensesProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        title: Text(
          expense.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${DateFormat('yyyy-MM-dd').format(expense.date)} -- ${expense.category.name}'),
            Text('Amount: ₹${expense.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 15,),
            ElevatedButton(
              onPressed: (){
                GoRouter.of(context).pushNamed(MyAppRouteConstants.expenseDetailsRouteName,pathParameters: {'id': expense.id});
              }, 
              child: const Text('View Item'),
            )
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () {
                GoRouter.of(context).pushNamed(MyAppRouteConstants.expenseEditRouteName, pathParameters: {'id': expense.id});
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () {
                // simple delete confirmation
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete expense?'),
                    content: Text('Delete "${expense.title}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          notifier.deleteById(expense.id);
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}