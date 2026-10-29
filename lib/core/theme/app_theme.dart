
import 'package:flutter/material.dart';

class AppTheme {
  // Bảng màu pastel ReadSpace
  static const Color softPurple = Color(0xFF9FA0FF);
  static const Color softMint = Color(0xFFD5E8E6);
  static const Color creamLight = Color(0xFFFFF3E3);
  static const Color coralRed = Color(0xFFFF7171);
  static const Color darkText = Color(0xFF2C2D42);

  // Theme sáng
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: softPurple,
      onPrimary: Colors.white,
      secondary: softMint,
      onSecondary: darkText,
      tertiary: coralRed,
      onTertiary: Colors.white,
      surface: creamLight,
      onSurface: darkText,
      error: coralRed,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: creamLight,

      appBarTheme: const AppBarTheme(
        backgroundColor: creamLight,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: false,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: creamLight,
        indicatorColor: softPurple,
        iconTheme:
        WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return IconThemeData(color: darkText.withOpacity(0.7));
        }),
        labelTextStyle:
        WidgetStateProperty.resolveWith<TextStyle?>((states) {
          return TextStyle(
            color: darkText,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.bold
                : FontWeight.normal,
          );
        }),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: softPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: softPurple,
          side: const BorderSide(color: softPurple),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: softPurple.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: darkText.withOpacity(0.10),
        thickness: 1,
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkText),
        titleLarge: TextStyle(
          color: darkText,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: darkText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Theme tối
  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF20212D);
    const darkSurface = Color(0xFF2C2D42);
    const lightText = Color(0xFFF7F2FA);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: softPurple,
        onPrimary: darkText,
        secondary: softMint,
        onSecondary: darkText,
        tertiary: coralRed,
        onTertiary: darkText,
        surface: darkSurface,
        onSurface: lightText,
        error: coralRed,
        onError: darkText,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: softPurple,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: lightText.withOpacity(0.12),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightText),
        bodyMedium: TextStyle(color: lightText),
        titleLarge: TextStyle(
          color: lightText,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: lightText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
