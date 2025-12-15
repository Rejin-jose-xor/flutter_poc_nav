import 'package:flutter/material.dart';
import 'text_theme.dart' show textThemeFromColorScheme;

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF006879),
  onPrimary: Colors.white,
  secondary: Color(0xFF4A6268),
  onSecondary: Colors.white,
  surface: Colors.white,
  onSurface: Color(0xFF191C1D),
  error: Colors.red,
  onError: Colors.white,
  primaryContainer: Color(0xFFBFE9F0),
  onPrimaryContainer: Color(0xFF001F26),
  secondaryContainer: Color(0xFFCDE7ED),
  onSecondaryContainer: Color(0xFF051F23),
  surfaceContainerHighest: Color(0xFFDCE4E7),
  onSurfaceVariant: Color(0xFF40484B),
  outline: Color(0xFF70787C),
  shadow: Colors.black,
  inverseSurface: Color(0xFF2F3133),
  onInverseSurface: Colors.white,
  inversePrimary: Color(0xFF87D2DF),
);

final lightTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  textTheme: textThemeFromColorScheme(lightColorScheme),
  primaryTextTheme: textThemeFromColorScheme(lightColorScheme).apply(bodyColor: lightColorScheme.onPrimary),
  iconTheme: IconThemeData(color: lightColorScheme.onSurfaceVariant),
  appBarTheme: AppBarTheme(
    backgroundColor: lightColorScheme.primary,
    foregroundColor: lightColorScheme.onPrimary,
    titleTextStyle: textThemeFromColorScheme(lightColorScheme).headlineSmall?.copyWith(color: lightColorScheme.onPrimary),
    elevation: 1,
  ),
  // small visual tweaks
  elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
  backgroundColor: lightColorScheme.primary,
  foregroundColor: lightColorScheme.onPrimary,
  textStyle: textThemeFromColorScheme(lightColorScheme).labelLarge,
  ),
  ),
);