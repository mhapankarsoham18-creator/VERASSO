import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the [BatterySaverNotifier].
final batterySaverProvider =
    StateNotifierProvider<BatterySaverNotifier, BatterySaverState>((ref) {
  return BatterySaverNotifier();
});

/// Notifier class for managing the battery saver state.
class BatterySaverNotifier extends StateNotifier<BatterySaverState> {
  /// Creates a [BatterySaverNotifier] and loads the saved state.
  BatterySaverNotifier() : super(BatterySaverState()) {
    _loadState();
  }

  /// Sets the battery saver enabled status.
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_saver_enabled', value);
    state = BatterySaverState(isEnabled: value);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = BatterySaverState(
        isEnabled: prefs.getBool('battery_saver_enabled') ?? false);
  }
}

/// State model for battery saver.
class BatterySaverState {
  /// Whether the battery saver is currently enabled.
  final bool isEnabled;

  /// Creates a [BatterySaverState] instance.
  BatterySaverState({this.isEnabled = false});
}
