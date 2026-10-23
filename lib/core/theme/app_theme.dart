import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color textColor = Color(0xFF2D3436);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // Đặt font toàn cục tại đây, không cần config TextTheme phức tạp nữa
      fontFamily: GoogleFonts.nunito().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        surface: backgroundColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}