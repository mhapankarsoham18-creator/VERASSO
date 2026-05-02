import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../errors/app_exceptions.dart';

/// Centralized service for looking up the current user's Supabase profile ID.
/// Eliminates the repeated "get my profile from firebase_uid" pattern
/// that was duplicated in 10+ screens.
final profileLookupProvider = Provider<ProfileLookupService>((ref) {
  return ProfileLookupService();
});

class ProfileLookupService {
  String? _cachedProfileId;
  String? _cachedFirebaseUid;

  /// Returns the current user's Supabase profile UUID.
  /// Caches the result so subsequent calls within the same session are instant.
  /// Throws [AuthException] if not logged in.
  /// Throws [NotFoundException] if profile doesn't exist.
  Future<String> getMyProfileId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw AppAuthException();

    // Return cached value if the Firebase UID hasn't changed
    if (_cachedProfileId != null && _cachedFirebaseUid == user.uid) {
      return _cachedProfileId!;
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('firebase_uid', user.uid)
        .maybeSingle();

    if (profile == null) throw NotFoundException('Profile not found');

    _cachedProfileId = profile['id'] as String;
    _cachedFirebaseUid = user.uid;
    return _cachedProfileId!;
  }

  /// Clears the cache (e.g. on logout).
  void clearCache() {
    _cachedProfileId = null;
    _cachedFirebaseUid = null;
  }
}
