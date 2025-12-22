import 'package:flutter/material.dart';
import '../sections/expenses_list.dart' show ExpensesSliverList;  
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerState, ConsumerStatefulWidget;
import '../provider/expense_provider.dart' show expensesProvider;
import '../sections/expenses_paging_header.dart' show ExpensesPagingHeader;

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  @override
  void initState() {
    super.initState();

    // Load FIRST PAGE once on app start
    Future.microtask(() {
      ref.read(expensesProvider.notifier).loadFirstPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            ExpensesPagingHeader(),
            ExpensesSliverList(),
          ],
        ),
      ),
    );
  }
}
