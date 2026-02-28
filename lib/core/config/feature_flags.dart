import 'package:verasso/core/services/supabase_service.dart';

/// Global feature flags and capability stages for Verasso.
///
/// This centralizes which experiences are considered production‑ready,
/// beta, or experimental, and allows builds to override behaviour via
/// `--dart-define` at compile time.
class FeatureFlags {
  /// Whether Mesh Labs (offline Bluetooth mesh experiments) are enabled
  /// in the UI.
  ///
  /// This flag controls visibility of the Mesh Labs entry points. It does
  /// **not** guarantee cross‑platform transport support; that is handled
  /// by platform‑specific capability checks inside mesh services.
  static const bool enableMeshLabs =
      bool.fromEnvironment('FEATURE_MESH_LABS', defaultValue: true);

  /// Whether advanced cognitive / analytics dashboards should be visible
  /// beyond the core learning progress views.
  static const bool enableAdvancedCognitiveDashboards =
      bool.fromEnvironment('FEATURE_ADVANCED_COGNITIVE', defaultValue: true);

  /// Whether experimental secure‑messaging features (such as in‑progress
  /// E2E encryption UX) are exposed beyond the core chat experience.
  static const bool enableExperimentalMessagingSecurity = bool.fromEnvironment(
      'FEATURE_EXPERIMENTAL_MESSAGING_SECURITY',
      defaultValue: false);

  /// Whether the CodeMaster Odyssey CS journey should be integrated into
  /// the main app shell.
  ///
  /// At the time of writing, this is a separate package that is not wired
  /// into navigation; when this flag is true, navigation entry points can
  /// safely be added.
  static const bool enableCodeMasterOdyssey =
      bool.fromEnvironment('FEATURE_CODEMASTER_ODYSSEY', defaultValue: false);

  static final Map<String, bool> _overrides = {};

  /// Helper for checking if a given feature is considered production‑grade.
  static bool get isMeshProductionReady =>
      _getFlag('enable_mesh_sync', enableMeshLabs);

  /// Updates local overrides from Supabase.
  static Future<void> updateFromRemote() async {
    try {
      final response = await SupabaseService.client
          .from('feature_flags')
          .select('key, is_enabled');

      for (var row in response) {
        _overrides[row['key']] = row['is_enabled'] as bool;
      }
    } catch (e) {
      // Fallback to defaults
    }
  }

  static bool _getFlag(String key, bool defaultValue) {
    return _overrides[key] ?? defaultValue;
  }
}
