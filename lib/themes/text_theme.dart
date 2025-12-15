import 'package:flutter/material.dart';

// --- Helper: build a TextTheme from a ColorScheme ---
TextTheme textThemeFromColorScheme(ColorScheme cs) {
// Use the Material typography scale and wire the colors to the scheme.
// Adjust font sizes/weights to taste.
return TextTheme(
displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, color: cs.onSurface),
displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, color: cs.onSurface),
displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: cs.onSurface),


headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: cs.onSurface),
headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: cs.onSurface),
headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: cs.onSurface),


titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: cs.onSurface),
titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),


bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: cs.onSurface),
bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),


labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.primary),
labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cs.primary),
labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
);
}