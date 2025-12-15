import 'package:flutter/material.dart';
import 'text_theme.dart' show textThemeFromColorScheme;

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF87D2DF),
  onPrimary: Color(0xFF00363E),
  secondary: Color(0xFFB1CBD1),
  onSecondary: Color(0xFF1C3439),
  surface: Color(0xFF101415),
  onSurface: Colors.white,
  error: Colors.redAccent,
  onError: Colors.black,
  primaryContainer: Color(0xFF004F59),
  onPrimaryContainer: Color(0xFFBFE9F0),
  secondaryContainer: Color(0xFF324A4F),
  onSecondaryContainer: Color(0xFFCDE7ED),
  surfaceContainerHighest: Color(0xFF40484B),
  onSurfaceVariant: Color(0xFFDCE4E7),
  outline: Color(0xFF8A9296),
  shadow: Colors.black,
  inverseSurface: Color(0xFFE1E3E4),
  onInverseSurface: Color(0xFF2F3133),
  inversePrimary: Color(0xFF006879),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
  textTheme: textThemeFromColorScheme(darkColorScheme),
  primaryTextTheme: textThemeFromColorScheme(
    darkColorScheme,
  ).apply(bodyColor: darkColorScheme.onPrimary),
  iconTheme: IconThemeData(color: darkColorScheme.onSurfaceVariant),
  appBarTheme: AppBarTheme(
    backgroundColor: darkColorScheme.primary,
    foregroundColor: darkColorScheme.onPrimary,
    titleTextStyle: textThemeFromColorScheme(darkColorScheme).headlineSmall?.copyWith(color: darkColorScheme.onPrimary),
    elevation: 1,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
      textStyle: textThemeFromColorScheme(darkColorScheme).labelLarge,
    ),
  ),
);
