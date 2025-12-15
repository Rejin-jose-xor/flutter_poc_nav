import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_route_constants.dart' show MyAppRouteConstants;
import 'provider/theme_provider.dart' show themeProvider;
import 'pages/budget.dart' show BudgetPage;
import 'pages/expense_create.dart' show ExpenseCreate;
import 'pages/expense_details.dart' show ExpenseDetails;
import 'pages/expense_edit.dart' show ExpenseEdit;
import 'pages/expenses.dart' show ExpensesPage;
import 'pages/profile.dart' show ProfilePage;
import '../splash_screen.dart' show SplashScreen;


class MyAppRouter {

  final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => const MaterialPage(child: SplashScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {

          final rawLoc =  GoRouter.of(context).location;
          final loc = Uri.parse(rawLoc).path.replaceAll(RegExp(r'/$'), '');

          return Consumer(builder: (context, ref, _){
            final themeMode = ref.watch(themeProvider);
            final notifier = ref.read(themeProvider.notifier);

            String titleFor(String loc) {
            if (loc.startsWith('/budget')) return 'Budget';
            if (loc.startsWith('/profile')) return 'Profile';
            if (loc.startsWith('/expenses/create')) return 'Create Expense';
            if (loc.startsWith('/expenses/details')) return 'Single Expense';
            if (loc.startsWith('/expenses/edit')) return 'Edit Expense';
            return 'Expenses';
          }

          List<Widget> actionsFor(String loc) {
            if(loc.startsWith('/expenses/create')) return const [];
            if (loc.startsWith('/expenses') || loc.startsWith('/budget')) {
              return [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {context.push('/expenses/create');}, // example
                  tooltip: 'Create Expense',
                )
              ];
            }
            return const [];
          }

          int locationToIndex(String location) {
            if (location.startsWith('/budget')) return 1;
            if (location.startsWith('/profile')) return 2;
            return 0;
          }

          final currentIndex = locationToIndex(state.location);

          // Decide whether this is an "inner" page where back should appear.
          // Here we treat any /expense/* (except exactly '/expense') as inner,
          // or you can add other rules (e.g. '/budget/*') if needed.
          final isExpenseInner = loc != '/expenses' && loc.startsWith('/expenses');
          const  isOtherInner = false; // add other rules if you want back for other tabs
          final showBack = isExpenseInner || isOtherInner;

          return Scaffold(
            appBar: AppBar(
              title: Text(titleFor(rawLoc)), 
              actions: [
                ...actionsFor(rawLoc),
                IconButton(
                  tooltip: 'Toggle theme',
                  icon: Icon(
                    themeMode == ThemeMode.dark ? Icons.wb_sunny : Icons.nights_stay,
                  ),
                  onPressed: () => notifier.toggle(),
                ),
              ],
              leading: showBack ? BackButton(onPressed: () => context.pop()) : null,
            ),
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: currentIndex,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Expenses'),
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    // go to expenses (root)
                    context.go('/expenses');
                    break;
                  case 1:
                    context.go('/budget');
                    break;
                  case 2:
                    context.go('/profile'); 
                    break;
                }
              },
            ),
          );
          });      
        },
        routes: [
          GoRoute(
            name: MyAppRouteConstants.expenseRouteName,
            path: '/expenses',
            pageBuilder: (context, state) {
              return const MaterialPage(child: ExpensesPage());
            },
            routes: [
              GoRoute(
                name: MyAppRouteConstants.expenseCreateRouteName,
                path: 'create',
                pageBuilder: (context, state) => const MaterialPage(child: ExpenseCreate())
              ),
              GoRoute(
                name: MyAppRouteConstants.expenseEditRouteName,
                path: 'edit/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(child: ExpenseEdit(expenseId: id));
                } 
              ),
              GoRoute(
                name: MyAppRouteConstants.expenseDetailsRouteName,
                path: 'details/:id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return MaterialPage(child: ExpenseDetails(expenseId: id));
                } 
              )
            ],
          ),
          GoRoute(
            name: MyAppRouteConstants.budgetRouteName,
            path: '/budget',
            pageBuilder: (context, state) {
              return const MaterialPage(child: BudgetPage());
            }
          ),
          GoRoute(
            name: MyAppRouteConstants.profileRouteName,
            path: '/profile',
            pageBuilder: (context, state) {
              return const MaterialPage(child: ProfilePage());
            }
          ),
        ],
      ),     
    ],
    errorPageBuilder: (context, state) {
      return const MaterialPage(child: ExpensesPage()); // Error page
    }
  );

}