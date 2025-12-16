import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart' show GoRouter, GoRoute;
import 'package:flutter_poc_nav/main.dart';
import 'package:flutter_poc_nav/provider/theme_provider.dart' show initialThemeModeProvider;


GoRouter createTestRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const Scaffold(
            body: Text('Home'),
          );
        },
      ),
    ],
  );
}


void main() {
  testWidgets('MyApp builds with light theme', (WidgetTester tester) async {
    final router = createTestRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.light),
        ],
        child: MyApp(router: router),
      ),
    );

     // Just verify app structure
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.light);
    expect(find.byType(MaterialApp), findsOneWidget);

  });

  testWidgets('MyApp builds with dark theme', (WidgetTester tester) async {
    final router = createTestRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialThemeModeProvider.overrideWithValue(ThemeMode.dark),
        ],
        child: MyApp(router: router),
      ),
    );

     // Just verify app structure
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(find.byType(MaterialApp), findsOneWidget);

  });
}