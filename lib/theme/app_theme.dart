import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF8AAFE2);
  static const Color accentPink = Color(0xFFE58ACD);
  static const Color background = Color(0xFFF6F7FB);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentPink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 54,
          fontWeight: FontWeight.w900,
          color: accentPink,
        ),
      ),
    );
  }
}