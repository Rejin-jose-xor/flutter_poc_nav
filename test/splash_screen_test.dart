import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_poc_nav/splash_screen.dart';
import 'package:flutter_poc_nav/provider/theme_provider.dart'
    show initialThemeModeProvider;

/// Simple stub page for navigation verification
class TestExpensesPage extends StatelessWidget {
  const TestExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Expenses Page')),
    );
  }
}

void main() {
  testWidgets(
    'SplashScreen Continue navigates to Expenses route',
    (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const TestExpensesPage(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialThemeModeProvider.overrideWithValue(ThemeMode.light),
          ],
          child: MaterialApp.router(
            routerDelegate: router.routerDelegate,
            routeInformationParser: router.routeInformationParser,
            routeInformationProvider: router.routeInformationProvider,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Splash is visible
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Navigation successful
      expect(find.text('Expenses Page'), findsOneWidget);
    },
  );
}
