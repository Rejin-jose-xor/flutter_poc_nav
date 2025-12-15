import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerWidget, WidgetRef;
import 'provider/theme_provider.dart' show themeProvider;


class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final double? titleSpacing;
  final VoidCallback? onAddExpense;
  const CustomAppBar({
    super.key,
    required this.title,
    this.titleSpacing,
    this.onAddExpense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);
    return AppBar(
      title: Text(title),
      titleSpacing: titleSpacing,
      actions: [
        // Toggle button
        IconButton(
          tooltip: 'Toggle theme',
          icon: Icon(
            themeMode == ThemeMode.dark ? Icons.wb_sunny : Icons.nights_stay,
          ),
          onPressed: () => notifier.toggle(),
        ),
        //Add Expense
        if (onAddExpense != null)
          IconButton(
            tooltip: 'Add Expense',
            icon: const Icon(Icons.add),
            onPressed: onAddExpense,
          ),
  
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


