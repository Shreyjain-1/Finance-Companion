import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  /// 🌞 LIGHT THEME
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.expense,
      onError: Colors.white,
      background: AppColors.bgLight,
      onBackground: AppColors.textPrimLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimLight,
    ),

    scaffoldBackgroundColor: AppColors.bgLight,

    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),

    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dividerColor: AppColors.dividerLight,

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimLight),
      bodyMedium: TextStyle(color: AppColors.textMuted),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  /// 🌙 DARK THEME
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Colors.black,
      secondary: AppColors.secondary,
      onSecondary: Colors.black,
      error: AppColors.expense,
      onError: Colors.black,
      background: AppColors.bgDark,
      onBackground: AppColors.textPrimDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimDark,
    ),

    scaffoldBackgroundColor: AppColors.bgDark,

    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),

    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dividerColor: AppColors.dividerDark,

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimDark),
      bodyMedium: TextStyle(color: AppColors.textMuted),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primaryLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
