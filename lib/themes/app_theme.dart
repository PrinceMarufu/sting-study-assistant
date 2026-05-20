import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Vibrant Educational Colors
  static const Color tealColor = Color(0xFF00BFA6);
  static const Color darkBlueColor = Color(0xFF1E293B);
  static const Color charcoalColor = Color(0xFF121824);
  static const Color mustardColor = Color(0xFFFFC107);
  static const Color coralColor = Color(0xFFFF5A79);
  
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color lightGreyColor = Color(0xFFF1F5F9);
  static const Color borderGreyColor = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: tealColor,
      scaffoldBackgroundColor: whiteColor,
      colorScheme: const ColorScheme.light(
        primary: tealColor,
        secondary: darkBlueColor,
        tertiary: mustardColor,
        surface: lightGreyColor,
        error: coralColor,
        onPrimary: whiteColor,
        onSecondary: whiteColor,
        onSurface: darkBlueColor,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: darkBlueColor,
        displayColor: darkBlueColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: whiteColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkBlueColor),
        titleTextStyle: GoogleFonts.inter(
          color: darkBlueColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealColor,
          foregroundColor: whiteColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGreyColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: tealColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: whiteColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderGreyColor, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: tealColor,
      scaffoldBackgroundColor: charcoalColor,
      colorScheme: const ColorScheme.dark(
        primary: tealColor,
        secondary: lightGreyColor,
        tertiary: mustardColor,
        surface: darkBlueColor,
        error: coralColor,
        onPrimary: charcoalColor,
        onSecondary: charcoalColor,
        onSurface: whiteColor,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: whiteColor,
        displayColor: whiteColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: charcoalColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: whiteColor),
        titleTextStyle: GoogleFonts.inter(
          color: whiteColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tealColor,
          foregroundColor: charcoalColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBlueColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: tealColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: darkBlueColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkBlueColor.withValues(alpha: 0.1), width: 1),
        ),
      ),
    );
  }
}
