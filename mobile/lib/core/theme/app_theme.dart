import 'package:flutter/material.dart';

/// Brand greens: forest for primary actions and headers, meadow for accents.
abstract final class AppColors {
  static const forest = Color(0xFF1B5E3B);
  static const forestDark = Color(0xFF0F3D26);
  static const meadow = Color(0xFF4CAF6E);
  static const mist = Color(0xFFF4F8F4);
}

abstract final class AppTheme {
  static ThemeData get light => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      primary: AppColors.forest,
      secondary: AppColors.meadow,
      surface: AppColors.mist,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
    );
  }
}
