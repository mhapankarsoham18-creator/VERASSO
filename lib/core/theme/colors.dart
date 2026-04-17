import 'package:flutter/material.dart';

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color neutralBg;
  final Color primary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color shadowDark;
  final Color shadowLight;
  final Color blockEdge;
  final Color error;

  const AppColorsExtension({
    required this.neutralBg,
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.shadowDark,
    required this.shadowLight,
    required this.blockEdge,
    required this.error,
  });

  @override
  AppColorsExtension copyWith({
    Color? neutralBg,
    Color? primary,
    Color? accent,
    Color? textPrimary,
    Color? textSecondary,
    Color? shadowDark,
    Color? shadowLight,
    Color? blockEdge,
    Color? error,
  }) {
    return AppColorsExtension(
      neutralBg: neutralBg ?? this.neutralBg,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      shadowDark: shadowDark ?? this.shadowDark,
      shadowLight: shadowLight ?? this.shadowLight,
      blockEdge: blockEdge ?? this.blockEdge,
      error: error ?? this.error,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      neutralBg: Color.lerp(neutralBg, other.neutralBg, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      shadowDark: Color.lerp(shadowDark, other.shadowDark, t)!,
      shadowLight: Color.lerp(shadowLight, other.shadowLight, t)!,
      blockEdge: Color.lerp(blockEdge, other.blockEdge, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}

class AppColors {
  // Define instances
  static const classic = AppColorsExtension(
    neutralBg: Color(0xFFEAF0EA),
    primary: Color(0xFF4A5D23),
    accent: Color(0xFFE27D60),
    textPrimary: Color(0xFF2C2F33),
    textSecondary: Color(0xFF6B6E70),
    shadowDark: Color(0xFFCFCAC1),
    shadowLight: Color(0xFFFFFFFF),
    blockEdge: Color(0xFF1E2124),
    error: Color(0xFFD32F2F),
  );

  static const bladerunner = AppColorsExtension(
    neutralBg: Color(0xFF030508), // Deep cyber blue/black
    primary: Color(0xFF00E5FF), // Neon cyan
    accent: Color(0xFFFF0055),  // Neon magenta/pink
    textPrimary: Color(0xFFE0E5EC), // Bright text
    textSecondary: Color(0xFF8C9FB5), // Subdued blue-grey
    shadowDark: Color(0xFF000000), // Darker shadows for higher contrast neon
    shadowLight: Color(0xFF09121E), // Slightly raised cyber blue
    blockEdge: Color(0xFF008B99), // Edges glow cyan instead of black
    error: Color(0xFFFF003C),
  );
}

extension AppColorsContext on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>() ?? AppColors.classic;
}
