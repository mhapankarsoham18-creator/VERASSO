import 'package:flutter_riverpod/flutter_riverpod.dart';

// Represents the available themes
enum AppThemeType { classic, bladerunner }

// Notifier to hold the active theme
class ThemeNotifier extends Notifier<AppThemeType> {
  @override
  AppThemeType build() {
    return AppThemeType.classic;
  }

  void setTheme(AppThemeType theme) {
    state = theme;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeType>(ThemeNotifier.new);
