import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.grey,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: AppColors.white,
      onPrimary: AppColors.white,
      onSecondary: AppColors.dark,
      onSurface: AppColors.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark),
      headlineMedium: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.dark),
      titleLarge: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.dark),
      bodyLarge: const TextStyle(color: AppColors.dark),
      bodyMedium: TextStyle(color: AppColors.dark.withOpacity(0.8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.dark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shadowColor: AppColors.goldDark.withOpacity(0.4),
        elevation: 4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.goldLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.goldLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.gold, width: 2.5),
      ),
      labelStyle: TextStyle(color: AppColors.dark.withOpacity(0.7)),
      floatingLabelStyle: const TextStyle(color: AppColors.gold),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: const Color(0xFF1A0F0F),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.gold,
      surface: const Color(0xFF2D1B1B),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: AppColors.goldLight),
        fontFamily: 'Poppins',
  );
}