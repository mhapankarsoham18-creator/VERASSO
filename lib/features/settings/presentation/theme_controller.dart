import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/battery_saver_service.dart';
import '../../../core/theme/app_colors.dart';

/// Provider for the [ThemeController] which manages the application's visual theme.
final themeControllerProvider =
    StateNotifierProvider<ThemeController, AppThemeState>((ref) {
  final batterySaver = ref.watch(batterySaverProvider);
  final controller = ThemeController();

  // Power Saving Sync
  if (batterySaver.isEnabled) {
    controller.togglePowerSaveMode(true);
  }

  return controller;
});

/// State class capturing all theme-related configurations.
class AppThemeState {
  /// The current theme mode (system, light, or dark).
  final ThemeMode mode;

  /// The primary color used for major UI elements.
  final Color primaryColor;

  /// The accent color used for highlights and interactions.
  final Color accentColor;

  /// The overall visual style of the application.
  final ThemeStyle style;

  /// The current locale for internationalization.
  final Locale locale;

  /// Whether animations and effects are reduced for power saving.
  final bool isPowerSaveMode;

  /// Creates an [AppThemeState].
  AppThemeState({
    required this.mode,
    required this.primaryColor,
    required this.accentColor,
    this.style = ThemeStyle.liquid,
    this.locale = const Locale('en'),
    this.isPowerSaveMode = false,
  });

  /// Creates a copy of [AppThemeState] with updated properties.
  AppThemeState copyWith({
    ThemeMode? mode,
    Color? primaryColor,
    Color? accentColor,
    ThemeStyle? style,
    Locale? locale,
    bool? isPowerSaveMode,
  }) {
    return AppThemeState(
      mode: mode ?? this.mode,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      style: style ?? this.style,
      locale: locale ?? this.locale,
      isPowerSaveMode: isPowerSaveMode ?? this.isPowerSaveMode,
    );
  }
}

/// Controller that manages and persists application theme settings.
class ThemeController extends StateNotifier<AppThemeState> {
  static const _kThemeModeKey = 'theme_mode';

  static const _kPrimaryColorKey = 'theme_primary_color';
  static const _kAccentColorKey = 'theme_accent_color';
  static const _kStyleKey = 'theme_style';
  static const _kLocaleKey = 'locale';
  static const _kPowerSaveKey = 'theme_power_save';

  /// Creates a [ThemeController] and loads settings from persistent storage.
  ThemeController()
      : super(AppThemeState(
            mode: ThemeMode.system,
            primaryColor: AppColors.primary,
            accentColor: AppColors.accent)) {
    _loadSettings();
  }

  /// Sets the application accent color.
  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAccentColorKey, color.toARGB32());
  }

  /// Sets the application locale.
  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }

  /// Sets the application primary color.
  Future<void> setPrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrimaryColorKey, color.toARGB32());
  }

  /// Sets the application theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeModeKey, mode.index);
  }

  /// Updates the application style and applies default colors for that style.
  Future<void> setThemeStyle(ThemeStyle style) async {
    state = state.copyWith(style: style);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStyleKey, style.index);

    // Auto-adjust colors based on style defaults
    switch (style) {
      case ThemeStyle.liquid:
        setPrimaryColor(const Color(0xFF9D50BB));
        setAccentColor(const Color(0xFFE91E63));
        break;
      case ThemeStyle.midnight:
        setPrimaryColor(const Color(0xFF1A237E));
        setAccentColor(const Color(0xFF0D47A1));
        break;
      case ThemeStyle.tron:
        setPrimaryColor(const Color(0xFF00F2FF));
        setAccentColor(const Color(0xFF0055FF));
        break;
      case ThemeStyle.bladeRunner:
        setPrimaryColor(const Color(0xFFFFB800));
        setAccentColor(const Color(0xFF333333));
        break;
      case ThemeStyle.enchanted:
        setPrimaryColor(const Color(0xFF740001));
        setAccentColor(const Color(0xFFD3A625));
        break;
      case ThemeStyle.nature:
        setPrimaryColor(const Color(0xFF2E7D32));
        setAccentColor(const Color(0xFF8BC34A));
        break;
      case ThemeStyle.sunset:
        setPrimaryColor(const Color(0xFFFF6D00));
        setAccentColor(const Color(0xFFFFAB40));
        break;
      case ThemeStyle.hellblazer:
        setPrimaryColor(const Color(0xFF1A1A1A)); // Deep Obsidian Noir
        setAccentColor(const Color(0xFFCFB53B)); // Occult Gold
        break;
    }
  }

  /// Toggles power save mode to reduce UI intensity.
  Future<void> togglePowerSaveMode(bool active) async {
    state = state.copyWith(isPowerSaveMode: active);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPowerSaveKey, active);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_kThemeModeKey) ?? 0;
    final primaryValue = prefs.getInt(_kPrimaryColorKey);
    final accentValue = prefs.getInt(_kAccentColorKey);
    final styleIndex = prefs.getInt(_kStyleKey) ?? 0;
    final localeCode = prefs.getString(_kLocaleKey) ?? 'en';
    final powerSave = prefs.getBool(_kPowerSaveKey) ?? false;

    ThemeMode mode = ThemeMode.values[modeIndex];
    Color primary =
        primaryValue != null ? Color(primaryValue) : AppColors.primary;
    Color accent = accentValue != null ? Color(accentValue) : AppColors.accent;
    ThemeStyle style = ThemeStyle.values[styleIndex];
    Locale locale = Locale(localeCode);

    state = AppThemeState(
        mode: mode,
        primaryColor: primary,
        accentColor: accent,
        style: style,
        locale: locale,
        isPowerSaveMode: powerSave);
  }
}

/// Available visual styles for the application.
enum ThemeStyle {
  /// Default Purple/Pink/White style.
  liquid,

  /// Deep Blue/Navy nighttime style.
  midnight,

  /// Cyan/Electric Blue futuristic style.
  tron,

  /// Amber/Orange/Grey hazy futuristic style.
  bladeRunner,

  /// Burgundy/Gold magical style.
  enchanted,

  /// Green/Brown/Sunlight natural style.
  nature,

  /// Orange/Pink/Yellow sunset style.
  sunset,

  /// Black/Obsidian/Occult Gold dark mystical style.
  hellblazer,
}
