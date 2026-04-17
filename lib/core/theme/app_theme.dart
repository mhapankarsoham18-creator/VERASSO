import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData _buildTheme(Brightness brightness, AppColorsExtension colors) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.neutralBg,
      primaryColor: colors.primary,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.neutralBg,
        secondary: colors.accent,
        onSecondary: colors.neutralBg,
        surface: colors.neutralBg,
        onSurface: colors.textPrimary,
        error: colors.error,
        onError: colors.neutralBg,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.neutralBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.pressStart2p(
          color: colors.textPrimary,
          fontSize: 12, 
          shadows: [
            Shadow(color: colors.shadowDark, offset: const Offset(2, 2)),
          ]
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.vt323(
          color: colors.textPrimary,
          fontSize: 64,
          fontWeight: FontWeight.bold,
          shadows: [
             Shadow(color: colors.shadowDark, offset: const Offset(2, 2)),
          ]
        ),
        displayMedium: GoogleFonts.vt323(
          color: colors.textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          shadows: [
             Shadow(color: colors.shadowDark, offset: const Offset(1, 1)),
          ]
        ),
        bodyLarge: TextStyle(color: colors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: colors.textSecondary, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.neutralBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: BorderSide(color: colors.blockEdge, width: 2),
          ),
          textStyle: GoogleFonts.vt323(fontSize: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      extensions: [colors],
    );
  }

  static ThemeData get classicTheme => _buildTheme(Brightness.light, AppColors.classic);
  static ThemeData get bladerunnerTheme => _buildTheme(Brightness.dark, AppColors.bladerunner);
}
