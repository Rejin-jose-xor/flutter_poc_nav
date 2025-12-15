import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'package:flutter_riverpod/flutter_riverpod.dart' show  ProviderScope, ConsumerWidget, WidgetRef;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import 'provider/theme_provider.dart' show initialThemeModeProvider, themeProvider;
import 'themes/dark_theme.dart' show darkTheme;
import 'themes/light_theme.dart' show lightTheme;
import 'app_route_configuration.dart' show MyAppRouter;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThemeMode initialMode = ThemeMode.system;
   // initialize Hive for Flutter
  await Hive.initFlutter();
  await Hive.openBox('expensesBox');

  try{
    final pref = await SharedPreferences.getInstance();
    final saved = pref.getString('app_theme_mode');
    if(saved == 'dark') {
      initialMode = ThemeMode.dark;
    }
    if(saved == 'light') {
      initialMode = ThemeMode.light;
    }
  } catch(_){}

  final router = MyAppRouter().router;

  runApp(ProviderScope(overrides: [
    // override the initial-mode provider with the saved initial mode
    initialThemeModeProvider.overrideWithValue(initialMode),
  ], child: MyApp(router: router)));
}

class MyApp extends ConsumerWidget {
  final GoRouter router;
  const MyApp({
    super.key,
    required this.router
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
  
    return MaterialApp.router(
      title: 'Expense Tracker',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
      debugShowCheckedModeBanner: false,
    );
  }
}

