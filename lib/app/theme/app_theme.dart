import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color darkBlue = Color(0xFF1D4ED8);
  static const Color lightGreen = Color(0xFF10B981);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF1F5F9);
  static const Color mediumGray = Color(0xFF64748B);
  static const Color darkGray = Color(0xFF334155);
  static const Color black = Color(0xFF0F172A);

  // Additional Blue Shades for Gradients
  static const Color skyBlue = Color(0xFF0EA5E9);
  static const Color cyanBlue = Color(0xFF06B6D4);
  static const Color indigoBlue = Color(0xFF4F46E5);
  static const Color purpleBlue = Color(0xFF7C3AED);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF2563EB),
    Color(0xFF3B82F6),
    Color(0xFF0EA5E9),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFFA855F7),
  ];

  static const List<Color> successGradient = [
    Color(0xFF10B981),
    Color(0xFF34D399),
    Color(0xFF6EE7B7),
  ];

  static const List<Color> cardGradient = [
    Color(0xFFF8FAFC),
    Color(0xFFE2E8F0),
  ];

  // State Colors
  static const Map<String, List<Color>> stateColors = {
    'NY': [Color(0xFF2563EB), Color(0xFF3B82F6)], // Blue
    'PA': [Color(0xFF10B981), Color(0xFF34D399)], // Green
    'NJ': [Color(0xFFF59E0B), Color(0xFFFBBF24)], // Orange
    'CT': [Color(0xFF8B5CF6), Color(0xFFA78BFA)], // Purple
  };

  static List<Color> getStateColors(String state) {
    return stateColors[state] ?? primaryGradient;
  }

  // Agent State Colors (all blue)
  static List<Color> getAgentStateColors(String state) {
    return primaryGradient; // Always blue for agents
  }

  // Loan Officer State Colors (all green)
  static List<Color> getLoanOfficerStateColors(String state) {
    return successGradient; // Always green for loan officers
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: lightGreen,
        surface: white,
        background: lightGray,
        onPrimary: white,
        onSecondary: white,
        onSurface: darkGray,
        onBackground: darkGray,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: black,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: black,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: black,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: darkGray,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: mediumGray,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkGray,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkGray,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: mediumGray,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.inter(color: mediumGray, fontSize: 14),
        labelStyle: GoogleFonts.inter(
          color: darkGray,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 4,
        shadowColor: primaryBlue.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: mediumGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
