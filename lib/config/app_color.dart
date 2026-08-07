import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF588B5B);
  static const Color background = Color(0xFFF4F6F4);
  static const Color inputBackground = Color(0xFFEFF2EE);
  static const Color textDark = Color(0xFF2C322E);
  static const Color textMuted = Color(0xFF7A817C);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryGreen,
        surface: inputBackground,
        onPrimary: Colors.white,
        onSurface: textDark,
      ),
    );
  }
}
