import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'package:go_router/go_router.dart';
import '../app_route_constants.dart' show MyAppRouteConstants;
import '../provider/expense_provider.dart' show expensesProvider;
import 'expense_list_item.dart' show ExpenseListItem;



class ExpensesSliverList extends ConsumerWidget {
  const ExpensesSliverList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final expenses = ref.watch(expensesProvider);
    if (expenses.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false, // **makes vertical centering work**
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ensures exact centering
              children: [
                const Icon(Icons.receipt_long_outlined, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No expenses yet. Add one to get started!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    GoRouter.of(context).pushNamed(MyAppRouteConstants.expenseCreateRouteName);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Expense"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final e = expenses[index];
            return ExpenseListItem(expense: e);
          },
          childCount: expenses.length,
        ),
      ),
    );
  }
}