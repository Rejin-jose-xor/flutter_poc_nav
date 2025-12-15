import 'package:flutter/material.dart';
import '../sections/expenses_list.dart' show ExpensesSliverList;  

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            ExpensesSliverList(),
          ],
        ),
      ),
    );
  }
}
