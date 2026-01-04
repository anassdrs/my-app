import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color primary = Colors.blue; // Vibrant Purple
  static const Color secondary = Color(0xFF03DAC6); // Teal
  static const Color error = Color(0xFFCF6679);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSecondary = Color(0xFF6B7280);
}

class AppTextStyles {
  static TextStyle get heading1 =>
      const TextStyle(fontSize: 28, fontWeight: FontWeight.bold);

  static TextStyle get heading2 =>
      const TextStyle(fontSize: 22, fontWeight: FontWeight.w600);

  static TextStyle get bodyLarge => const TextStyle(fontSize: 16);

  static TextStyle get bodyMedium => const TextStyle(fontSize: 14);
}

class AppThemes {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF222831),
    fontFamily: 'Arial',
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    useMaterial3: true,
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,

    primaryColor: Colors.blue,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      onSurface: AppColors.lightTextPrimary,
    ),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: AppColors.lightTextPrimary,
      displayColor: AppColors.lightTextPrimary,
    ),
    useMaterial3: true,
  );

  static ThemeData themedWithAccent({required bool isDark, Color? accent}) {
    final base = isDark ? darkTheme : lightTheme;
    final resolvedAccent = accent ?? AppColors.primary;
    return base.copyWith(
      primaryColor: resolvedAccent,
      colorScheme: base.colorScheme.copyWith(primary: resolvedAccent),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: resolvedAccent,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: resolvedAccent,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
