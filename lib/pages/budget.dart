import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import '../charts/expense_bar_chart.dart' show ExpenseBarChart;
import '../charts/expenses_pie_chart.dart' show ExpensesPieChart;
import '../provider/expense_provider.dart' show expensesProvider;
import '../models/expense_model.dart' show Expense;

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Expense> expenses = ref.watch(expensesProvider);

    // compute total
    final double total = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    // formatted string (adjust currency symbol if needed)
    final String totalText = 'Total expenses: ₹${total.toStringAsFixed(2)}';

    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TOTAL row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          totalText,
                          style: textTheme.headlineSmall?.copyWith(color: cs.primary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const RepaintBoundary(child: ExpensesPieChart()),
                    const SizedBox(height: 12),
                    const RepaintBoundary(child: ExpenseBarChart()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}