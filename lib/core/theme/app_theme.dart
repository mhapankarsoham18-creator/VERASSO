import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.neutralBg,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.neutralBg,
        error: Colors.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.neutralBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.pressStart2p(
          color: AppColors.textPrimary,
          fontSize: 12, // Reduced from 16 so long titles fit
          shadows: const [
            Shadow(color: AppColors.shadowDark, offset: Offset(2, 2)),
          ]
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      // Clean geometric reading font for body text and inputs
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.vt323(
          color: AppColors.textPrimary,
          fontSize: 64,
          fontWeight: FontWeight.bold,
          shadows: const [
             Shadow(color: AppColors.shadowDark, offset: Offset(2, 2)),
          ]
        ),
        displayMedium: GoogleFonts.vt323(
          color: AppColors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          shadows: const [
             Shadow(color: AppColors.shadowDark, offset: Offset(1, 1)),
          ]
        ),
        bodyLarge: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      // Buttons styled natively mostly for secondary actions, main buttons will use NeoPixelBox
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.neutralBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: AppColors.blockEdge, width: 2),
          ),
          textStyle: GoogleFonts.vt323(fontSize: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
