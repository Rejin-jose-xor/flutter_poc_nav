import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_poc_nav/app_route_configuration.dart';
import 'fakes/fake_providers.dart' show FakeExpensesNotifier, FakeProfileNotifier;
import 'package:flutter_poc_nav/provider/theme_provider.dart' show initialThemeModeProvider;
import 'package:flutter_poc_nav/provider/profile_provider.dart' show profileProvider;
import 'package:flutter_poc_nav/provider/expense_provider.dart' show expensesProvider;
import 'package:flutter_poc_nav/splash_screen.dart';



void main() {
  testWidgets(
    'Main navigation uses real router and switches tabs correctly',
    (WidgetTester tester) async {
      final router = MyAppRouter().router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileProvider.overrideWith(FakeProfileNotifier.new),
            expensesProvider.overrideWith(FakeExpensesNotifier.new),
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

      // Splash screen is shown
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // // Enter the app
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Expenses should be default (AppBar title)
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Expenses'),
        ),
        findsOneWidget,
      );

      // Bottom nav icon exists
      expect(find.byIcon(Icons.list), findsWidgets);

      await tester.tap(find.text('Budget'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Budget'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Profile'),
        ),
        findsOneWidget,
      );
    },
  );
}
