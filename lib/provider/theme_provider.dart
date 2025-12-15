import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart' show Notifier, NotifierProvider, Provider;
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

// Notifier version
// A small provider that supplies the initial theme mode. This can be
// overridden in `ProviderScope(overrides: [...])` from `main.dart`.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Read the initial value from `initialThemeModeProvider` so callers
    // can override that provider to set the startup theme synchronously.
    return ref.read(initialThemeModeProvider);
  }

  Future<void> toggle() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_theme_mode', newMode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }

}

// Provider using the Notifier pattern
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
