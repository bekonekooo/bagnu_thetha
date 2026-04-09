import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF8E7AB5);
  static const Color softCream = Color(0xFFF8F5EF);
  static const Color gold = Color(0xFFD4AF37);
  static const Color textDark = Color(0xFF2D2438);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: softCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        primary: primaryPurple,
        secondary: gold,
        surface: softCream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: softCream,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textDark,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: textDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}