import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const brand50 = Color(0xFFF6F0FF);
  static const brand100 = Color(0xFFEDE4FF);
  static const brand200 = Color(0xFFD8C4FF);
  static const brand300 = Color(0xFFB794FF);
  static const brand500 = Color(0xFF8B3DFF);
  static const brand600 = Color(0xFF7A2EF0);
  static const brand700 = Color(0xFF6B21D9);
  static const brand900 = Color(0xFF2E004B);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
}

class AppTheme {
  static ThemeData light({bool elderly = false}) {
    final baseSize = elderly ? 1.15 : 1.0;
    final text = GoogleFonts.dmSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand600,
        primary: AppColors.brand600,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: text.apply(
        bodyColor: AppColors.slate700,
        displayColor: AppColors.brand900,
        fontSizeFactor: baseSize,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand600,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 15 * baseSize,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand700,
          side: const BorderSide(color: AppColors.brand200),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate50,
        isDense: false,
        // Extra vertical padding so floating labels don't sit on the border /
        // collide with neighbouring fields.
        contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelStyle: GoogleFonts.dmSans(
          color: AppColors.brand700,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        labelStyle: GoogleFonts.dmSans(
          color: AppColors.slate500,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.dmSans(
          color: AppColors.slate400,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        prefixIconColor: AppColors.slate500,
        suffixIconColor: AppColors.slate500,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand500, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.brand600,
        secondarySelectedColor: AppColors.brand600,
        disabledColor: AppColors.slate100,
        checkmarkColor: Colors.white,
        deleteIconColor: AppColors.slate500,
        side: const BorderSide(color: AppColors.slate200),
        // Unselected: dark on white. Selected: white on brand purple.
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.slate700,
        ),
        secondaryLabelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brand900,
        elevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.brand900,
        ),
      ),
    );
  }
}
