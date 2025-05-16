import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor =
      Color(0xFF00A651); // Green like a football field
  static const Color primaryDarkColor = Color(0xFF008240);
  static const Color primaryLightColor = Color(0xFF4AD97F);

  // Secondary colors
  static const Color secondaryColor =
      Color(0xFFE53935); // Red like jersey in the images
  static const Color secondaryDarkColor = Color(0xFFC62828);
  static const Color secondaryLightColor = Color(0xFFEF5350);

  // Background colors
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color darkBackgroundColor = Color(0xFF121212);

  // Text colors
  static const Color lightTextColor = Color(0xFF212121);
  static const Color darkTextColor = Color(0xFFF5F5F5);
  static const Color lightSecondaryTextColor = Color(0xFF757575);
  static const Color darkSecondaryTextColor = Color(0xFFBDBDBD);

  // Light theme
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        surface: lightBackgroundColor,
      ),
      scaffoldBackgroundColor: lightBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: lightTextColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
    );
  }

  // Dark theme
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color.fromRGBO(0, 166, 81, 1),
        secondary: secondaryColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        surface: darkBackgroundColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: darkTextColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A651),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4AD97F),
        ),
      ),
    );
  }
}
