// widgets/expense_bar_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;

import '../models/expense_model.dart' show Expense;
import '../provider/expense_provider.dart' show expensesProvider;

class ExpenseBarChart extends ConsumerWidget {
  const ExpenseBarChart({super.key});

  /// Group expenses by day (last 7 days) — accepts the expenses list.
  List<Map<String, Object>> _groupedByDay(List<Expense> expenses) {
    final now = DateTime.now();
    final List<Map<String, Object>> list = [];

    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      double total = 0;

      for (final expense in expenses) {
        final sameDay =
            expense.date.year == day.year &&
            expense.date.month == day.month &&
            expense.date.day == day.day;

        if (sameDay) {
          total += expense.amount;
        }
      }

      final weekdayLabel = weekDays[day.weekday - 1];

      list.add({
        'label': weekdayLabel,
        'amount': total,
      });
    }

    return list.reversed.toList(); // oldest on left, newest on right
  }

double _maxDaySpending(List<Map<String, Object>> grouped) {
  return grouped.fold<double>(0.0, (max, dayData) {
    final amount = dayData['amount'] as double;
    return amount > max ? amount : max;
  });
}


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // get expenses here (inside build)
    final List<Expense> expenses = ref.watch(expensesProvider);

    // compute grouped data and maximum
    final data = _groupedByDay(expenses);
    final double maxY = _maxDaySpending(data) == 0
        ? 100
        : (_maxDaySpending(data) * 1.2).ceil().toDouble();

    // theme-driven colors & styles
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final barColor = cs.primary;
    final axisLabelColor = cs.onSurfaceVariant;
    final gridColor = Color.alphaBlend(cs.outline.withAlpha(30), Colors.transparent)
;
    final leftTitleStyle = textTheme.bodySmall?.copyWith(color: axisLabelColor);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Weekly Spending (Last 7 Days)',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: gridColor,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          final label = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(0);
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Text(label, style: leftTitleStyle),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) return const SizedBox.shrink();
                          final label = data[index]['label'] as String? ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              label,
                              style: textTheme.bodySmall?.copyWith(color: axisLabelColor, fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final amount = entry.value['amount'] as double;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: amount,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          color: barColor,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
