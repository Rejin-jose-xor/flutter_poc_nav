import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import '../provider/expense_provider.dart' show expensesProvider, canGoFirstProvider, canGoNextProvider, canGoPrevProvider;

class ExpensesPagingHeader extends ConsumerWidget {
  const ExpensesPagingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);
    final notifier = ref.read(expensesProvider.notifier);
    final canGoNext = ref.watch(canGoNextProvider);
    final canGoPrev = ref.watch(canGoPrevProvider);
    final canGoFirst = ref.watch(canGoFirstProvider);

    // Hide header if no data
    if (expenses.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (canGoFirst)
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: () {
                  notifier.loadFirstPage();
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: canGoPrev ? notifier.loadPrevPage : null,
              ), 

            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: canGoNext ? notifier.loadNextPage : null,
            ),
          ],
        ),
      ),
    );
  }
}
