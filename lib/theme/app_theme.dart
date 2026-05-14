import 'package:flutter/material.dart';

class AppTheme {
  // principales
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // charte complÃ©mentaire
  static const Color primaryPink = Color(0xFFE88FCF);
  static const Color softPink = Color(0xFFF6CAE8);
  static const Color primaryBlue = Color(0xFF92BBF6);
  static const Color softBlue = Color(0xFF9CE2F6);
  static const Color softGreen = Color(0xFFD7FEBD);
  static const Color softYellow = Color(0xFFFEFCD4);

  static const Color background = white;

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,

      colorScheme: const ColorScheme.light(
        primary: primaryPink,
        secondary: primaryBlue,
        surface: white,
        onPrimary: white,
        onSecondary: black,
        onSurface: black,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
      ),

      textTheme: const TextTheme(
        // GRANDSTANDER
        displayLarge: TextStyle(
          fontFamily: 'Grandstander',
          fontSize: 48,
          fontWeight: FontWeight.w700,
        ),

        headlineLarge: TextStyle(
          fontFamily: 'Grandstander',
          fontSize: 40,
          fontWeight: FontWeight.w700,
        ),

        headlineMedium: TextStyle(
          fontFamily: 'Grandstander',
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),

        headlineSmall: TextStyle(
          fontFamily: 'Grandstander',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),

        // MONTSERRAT
        titleLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),

        titleMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),

        bodyLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),

        bodyMedium: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),

        labelLarge: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: black,
          side: const BorderSide(color: black),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
