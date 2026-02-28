import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verasso/features/profile/data/profile_model.dart';
import 'package:verasso/features/profile/data/profile_repository.dart';
import 'package:verasso/features/profile/presentation/profile_controller.dart';

/// Provider for the [PrivacySettingsNotifier].
final privacySettingsProvider =
    StateNotifierProvider<PrivacySettingsNotifier, PrivacySettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PrivacySettingsNotifier(prefs, ref);
});

/// Provider for [SharedPreferences].
///
/// Note: Must be overridden in the [ProviderScope].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // This is overridden in main.dart
  return throw UnimplementedError(
      'sharedPreferencesProvider must be overridden');
});

/// Data model for user privacy settings.
class PrivacySettings {
  /// Whether the user's email is masked in search/public.
  final bool maskEmail;

  /// Whether the user's full name is masked.
  final bool maskFullName;

  /// Whether push notifications are enabled.
  final bool notifyEnabled;

  /// Whether the user's online status is visible.
  final bool showOnlineStatus;

  /// Whether the user's last login time is visible.
  final bool showLastSeen;

  /// Whether anyone can send friend requests.
  final bool allowFriendRequestsFromAnyone;

  /// Whether anybody can tag the user in posts.
  final bool allowTagging;

  /// Whether to automatically enable chat shielding/masking.
  final bool autoShieldChats;

  /// Whether to automatically blur the app's content when in the background.
  final bool autoBlurInBackground;

  /// Whether to enable biometric lock (Phase 2.1).
  final bool requireBiometric;

  /// Inactivity timeout duration before locking the app (Phase 2.1).
  final Duration sessionTimeout;

  /// Whether to enable mesh-only mode (No cloud sync) (Phase 3.3).
  final bool meshOnlyModeCurrent;

  /// Whether to notify about high trust score updates (Gamification Phase 3.5).
  final bool trustScoreNotifications;

  /// Whether a private profile is active.
  final bool privateProfile;

  /// Creates a [PrivacySettings] instance.
  PrivacySettings({
    this.maskEmail = false,
    this.maskFullName = false,
    this.notifyEnabled = true,
    this.showOnlineStatus = true,
    this.showLastSeen = true,
    this.allowFriendRequestsFromAnyone = true,
    this.allowTagging = true,
    this.autoShieldChats = false,
    this.autoBlurInBackground = true,
    this.requireBiometric = false,
    this.sessionTimeout = const Duration(minutes: 5),
    this.meshOnlyModeCurrent = false,
    this.trustScoreNotifications = true,
    this.privateProfile = false,
  });

  /// Creates a [PrivacySettings] from a map.
  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      maskEmail: map['maskEmail'] ?? false,
      maskFullName: map['maskFullName'] ?? false,
      notifyEnabled: map['notifyEnabled'] ?? true,
      showOnlineStatus: map['showOnlineStatus'] ?? true,
      showLastSeen: map['showLastSeen'] ?? true,
      allowFriendRequestsFromAnyone:
          map['allowFriendRequestsFromAnyone'] ?? true,
      allowTagging: map['allowTagging'] ?? true,
      autoShieldChats: map['autoShieldChats'] ?? false,
      autoBlurInBackground: map['autoBlurInBackground'] ?? true,
      requireBiometric: map['requireBiometric'] ?? false,
      sessionTimeout: map['sessionTimeoutMs'] != null
          ? Duration(milliseconds: map['sessionTimeoutMs'] as int)
          : const Duration(minutes: 5),
      meshOnlyModeCurrent: map['meshOnlyModeCurrent'] ?? false,
      trustScoreNotifications: map['trustScoreNotifications'] ?? true,
      privateProfile: map['privateProfile'] ?? false,
    );
  }

  /// Creates a copy of [PrivacySettings] with updated properties.
  PrivacySettings copyWith({
    bool? maskEmail,
    bool? maskFullName,
    bool? notifyEnabled,
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? allowFriendRequestsFromAnyone,
    bool? allowTagging,
    bool? autoShieldChats,
    bool? autoBlurInBackground,
    bool? requireBiometric,
    Duration? sessionTimeout,
    bool? meshOnlyModeCurrent,
    bool? trustScoreNotifications,
    bool? privateProfile,
  }) {
    return PrivacySettings(
      maskEmail: maskEmail ?? this.maskEmail,
      maskFullName: maskFullName ?? this.maskFullName,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      allowFriendRequestsFromAnyone:
          allowFriendRequestsFromAnyone ?? this.allowFriendRequestsFromAnyone,
      allowTagging: allowTagging ?? this.allowTagging,
      autoShieldChats: autoShieldChats ?? this.autoShieldChats,
      autoBlurInBackground: autoBlurInBackground ?? this.autoBlurInBackground,
      requireBiometric: requireBiometric ?? this.requireBiometric,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      meshOnlyModeCurrent: meshOnlyModeCurrent ?? this.meshOnlyModeCurrent,
      trustScoreNotifications:
          trustScoreNotifications ?? this.trustScoreNotifications,
      privateProfile: privateProfile ?? this.privateProfile,
    );
  }

  /// Converts [PrivacySettings] to a map.
  Map<String, dynamic> toMap() {
    return {
      'maskEmail': maskEmail,
      'maskFullName': maskFullName,
      'notifyEnabled': notifyEnabled,
      'showOnlineStatus': showOnlineStatus,
      'showLastSeen': showLastSeen,
      'allowFriendRequestsFromAnyone': allowFriendRequestsFromAnyone,
      'allowTagging': allowTagging,
      'autoShieldChats': autoShieldChats,
      'autoBlurInBackground': autoBlurInBackground,
      'requireBiometric': requireBiometric,
      'sessionTimeoutMs': sessionTimeout.inMilliseconds,
      'meshOnlyModeCurrent': meshOnlyModeCurrent,
      'trustScoreNotifications': trustScoreNotifications,
      'privateProfile': privateProfile,
    };
  }
}

/// Notifier that manages and persists user privacy settings.
class PrivacySettingsNotifier extends StateNotifier<PrivacySettings> {
  final SharedPreferences _prefs;
  final Ref _ref;

  /// Creates a [PrivacySettingsNotifier] and loads settings.
  PrivacySettingsNotifier(this._prefs, this._ref) : super(PrivacySettings()) {
    _loadSettings();
    _syncFromSupabase();
  }

  /// Updates whether anyone can send friend requests.
  void setAllowFriendRequestsFromAnyone(bool value) {
    state = state.copyWith(allowFriendRequestsFromAnyone: value);
    _prefs.setBool('allow_friend_requests', value);
    _updateSupabase();
  }

  /// Updates the tagging permission setting.
  void setAllowTagging(bool value) {
    state = state.copyWith(allowTagging: value);
    _prefs.setBool('allow_tagging', value);
    _updateSupabase();
  }

  /// Updates whether the app blurs when in the background.
  void setAutoBlurInBackground(bool value) {
    state = state.copyWith(autoBlurInBackground: value);
    _prefs.setBool('auto_blur', value);
    _updateSupabase();
  }

  /// Updates the automatic chat shielding setting.
  void setAutoShieldChats(bool value) {
    state = state.copyWith(autoShieldChats: value);
    _prefs.setBool('auto_shield_chats', value);
    _updateSupabase();
  }

  /// Updates the email masking setting.
  void setMaskEmail(bool value) {
    state = state.copyWith(maskEmail: value);
    _prefs.setBool('mask_email', value);
    _updateSupabase();
  }

  /// Updates the full name masking setting.
  void setMaskFullName(bool value) {
    state = state.copyWith(maskFullName: value);
    _prefs.setBool('mask_full_name', value);
    _updateSupabase();
  }

  /// Updates the mesh-only mode setting.
  void setMeshOnlyMode(bool value) {
    state = state.copyWith(meshOnlyModeCurrent: value);
    _prefs.setBool('mesh_only_mode', value);
    _updateSupabase();
  }

  /// Enables or disables push notifications.
  void setNotifyEnabled(bool value) {
    state = state.copyWith(notifyEnabled: value);
    _prefs.setBool('push_notifications', value);
    _updateSupabase();
  }

  /// Updates whether the profile is private.
  void setPrivateProfile(bool value) {
    state = state.copyWith(privateProfile: value);
    _prefs.setBool('private_profile', value);
    _updateSupabase();
  }

  /// Updates the biometric requirement setting.
  void setRequireBiometric(bool value) {
    state = state.copyWith(requireBiometric: value);
    _prefs.setBool('require_biometric', value);
    _updateSupabase();
  }

  /// Updates the session timeout duration.
  void setSessionTimeout(Duration duration) {
    state = state.copyWith(sessionTimeout: duration);
    _prefs.setInt('session_timeout_minutes', duration.inMinutes);
    _updateSupabase();
  }

  /// Updates the last seen visibility setting.
  void setShowLastSeen(bool value) {
    state = state.copyWith(showLastSeen: value);
    _prefs.setBool('show_last_seen', value);
    _updateSupabase();
  }

  /// Updates the online status visibility setting.
  void setShowOnlineStatus(bool value) {
    state = state.copyWith(showOnlineStatus: value);
    _prefs.setBool('show_online_status', value);
    _updateSupabase();
  }

  /// Updates the trust score notification setting.
  void setTrustScoreNotifications(bool value) {
    state = state.copyWith(trustScoreNotifications: value);
    _prefs.setBool('trust_notifications', value);
    _updateSupabase();
  }

  Future<void> _loadSettings() async {
    state = PrivacySettings(
      maskEmail: _prefs.getBool('mask_email') ?? false,
      maskFullName: _prefs.getBool('mask_full_name') ?? false,
      notifyEnabled: _prefs.getBool('push_notifications') ?? true,
      showOnlineStatus: _prefs.getBool('show_online_status') ?? true,
      showLastSeen: _prefs.getBool('show_last_seen') ?? true,
      allowFriendRequestsFromAnyone:
          _prefs.getBool('allow_friend_requests') ?? true,
      allowTagging: _prefs.getBool('allow_tagging') ?? true,
      autoShieldChats: _prefs.getBool('auto_shield_chats') ?? false,
      autoBlurInBackground: _prefs.getBool('auto_blur') ?? true,
      requireBiometric: _prefs.getBool('require_biometric') ?? false,
      sessionTimeout:
          Duration(minutes: _prefs.getInt('session_timeout_minutes') ?? 5),
      meshOnlyModeCurrent: _prefs.getBool('mesh_only_mode') ?? false,
      trustScoreNotifications: _prefs.getBool('trust_notifications') ?? true,
      privateProfile: _prefs.getBool('private_profile') ?? false,
    );
  }

  Future<void> _syncFromSupabase() async {
    try {
      final profile = await _ref.read(userProfileProvider.future);
      if (profile != null) {
        final remoteSettings = PrivacySettings.fromMap(profile.privacySettings);
        state = remoteSettings;
      }
    } catch (e) {
      // Quietly fail or log - we fallback to shared prefs already
    }
  }

  Future<void> _updateSupabase() async {
    try {
      final profileAsync = _ref.read(userProfileProvider);
      final profile = profileAsync.asData?.value;

      if (profile != null) {
        final updatedProfile = Profile(
          id: profile.id,
          username: profile.username,
          fullName: profile.fullName,
          avatarUrl: profile.avatarUrl,
          bio: profile.bio,
          role: profile.role,
          trustScore: profile.trustScore,
          website: profile.website,
          interests: profile.interests,
          isPrivate: state.privateProfile,
          followersCount: profile.followersCount,
          followingCount: profile.followingCount,
          postsCount: profile.postsCount,
          defaultPersonalVisibility: profile.defaultPersonalVisibility,
          isAgeVerified: profile.isAgeVerified,
          verificationUrl: profile.verificationUrl,
          isMentor: profile.isMentor,
          mentorTitle: profile.mentorTitle,
          mentorVerificationStatus: profile.mentorVerificationStatus,
          fcmToken: profile.fcmToken,
          journalistLevel: profile.journalistLevel,
          privacySettings: state.toMap(),
        );

        await _ref
            .read(profileRepositoryProvider)
            .updateProfile(updatedProfile);
      }
    } catch (e) {
      // Error updating - will try again next interaction
    }
  }
}
