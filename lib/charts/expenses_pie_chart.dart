import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'package:fl_chart/fl_chart.dart' as fl;
import '../constants/common.dart' show Category;
import '../provider/expense_provider.dart' show expensesProvider;
import '../models/expense_model.dart' show Expense;

class ExpensesPieChart extends ConsumerWidget {
  const ExpensesPieChart({super.key});

  Map<Category, double> _categoryTotals(List<Expense> expenses) {
    final Map<Category, double> totals = {
      Category.food: 0.0,
      Category.leisure: 0.0,
      Category.travel: 0.0,
      Category.work: 0.0,
    };

    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0.0) + expense.amount;
    }

    return totals;
  }

  List<fl.PieChartSectionData> _buildSections(
      Map<Category, double> totals, Map<Category, Color> categoryColors, Color labelColor) {
    final double totalAmount = totals.values.fold(0.0, (sum, v) => sum + v);
    if (totalAmount == 0) return [];

    return totals.entries
        .where((e) => e.value > 0)
        .map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = (amount / totalAmount) * 100;
          final color = categoryColors[category] ?? Colors.grey;

          return fl.PieChartSectionData(
            value: amount,
            title: '${percentage.toStringAsFixed(0)}%',
            color: color,
            radius: 60,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          );
        })
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Expense> expenses = ref.watch(expensesProvider);
    final totals = _categoryTotals(expenses);

    // derive colors from the current theme's ColorScheme
    final cs = Theme.of(context).colorScheme;

    final Map<Category, Color> categoryColors = {
      Category.food: cs.primary,              // main accent
      Category.leisure: cs.secondary,         // secondary accent
      Category.travel: cs.error,   // a container/variant color
      Category.work: cs.onSurface,   // another container/variant
    };

    // label color — pick high-contrast text for slice titles
    final labelColor = cs.onPrimary; // usually white on colored slices; tweak if needed

    final sections = _buildSections(totals, categoryColors, labelColor);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: sections.isEmpty
                  ? const Center(child: Text('No data'))
                  : fl.PieChart(
                      fl.PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: Category.values.map((cat) {
                final color = categoryColors[cat] ?? Theme.of(context).colorScheme.onSurfaceVariant;
                final label = cat.name[0].toUpperCase() + cat.name.substring(1);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 6),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
