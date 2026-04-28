import 'package:flutter/material.dart';

class AppTheme {
  static Color primaryColor = const Color(0xFFE8B4BC);
  static Color primaryDarkColor = const Color(0xFFD49BA5);
  static Color backgroundColor = const Color(0xFFFDF9FA);
  static Color textColor = const Color(0xFF333333);
  static Color textLightColor = const Color(0xFF8A8A8A);
  static Color borderColor = const Color(0xFFE8E8E8);
  static Color okColor = const Color(0xFF8FC9A3);
  static Color warningColor = const Color(0xFFE8A87C);
  static Color dangerColor = const Color(0xFFD9848C);
  
  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      surface: backgroundColor,
    ),
    useMaterial3: true,
    fontFamily: 'Inter',
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textColor,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE8E8E8)),
      ),
    ),
  );
  
  static void updateFromJson(Map<String, dynamic> json) {
    if (json['primaryColor'] != null) {
      final hex = json['primaryColor'].toString().replaceFirst('#', '');
      primaryColor = Color(int.parse('FF$hex', radix: 16));
    }
    if (json['primaryDarkColor'] != null) {
      final hex = json['primaryDarkColor'].toString().replaceFirst('#', '');
      primaryDarkColor = Color(int.parse('FF$hex', radix: 16));
    }
    if (json['backgroundColor'] != null) {
      final hex = json['backgroundColor'].toString().replaceFirst('#', '');
      backgroundColor = Color(int.parse('FF$hex', radix: 16));
    }
    if (json['textColor'] != null) {
      final hex = json['textColor'].toString().replaceFirst('#', '');
      textColor = Color(int.parse('FF$hex', radix: 16));
    }
  }
}
