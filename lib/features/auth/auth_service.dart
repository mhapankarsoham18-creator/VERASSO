import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in_lib;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter/foundation.dart';
import '../../core/services/notification_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserCredential> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (credential.user != null) {
      await _syncProfile(credential.user!);
    }
    return credential;
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final google_sign_in_lib.GoogleSignInAccount? googleUser = await google_sign_in_lib.GoogleSignIn().signIn();
      if (googleUser == null) return null; // Cancelled

      final google_sign_in_lib.GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred =
          await _auth.signInWithCredential(credential);
      
      // On new user (or existing but needing sync)
      if (userCred.user != null) {
        await _syncProfile(userCred.user!);
      }
      return userCred;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await google_sign_in_lib.GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Ensures Supabase has a profile mapped to the Firebase UID
  Future<void> _syncProfile(User firebaseUser) async {
    try {
      // Upsert into profiles based on firebase_uid
      // Wait, we generate uuid in supabase, but we match by firebase_uid. 
      // Supabase's auth.users is completely circumvented here since we use Firebase Auth.
      // So profile ID must just use gen_random_uuid in table definition, and firebase_uid is the lookup key.
      await _supabase.from('profiles').upsert({
        'firebase_uid': firebaseUser.uid,
        if (firebaseUser.displayName != null) 'display_name': firebaseUser.displayName,
        if (firebaseUser.photoURL != null) 'avatar_url': firebaseUser.photoURL,
        if (firebaseUser.email != null) 'username': firebaseUser.email!.split('@')[0],
        if (firebaseUser.email != null) 'email': firebaseUser.email,
      }, onConflict: 'firebase_uid');
      // Initialize Push Notifications so token is mapped to the new profile
      await NotificationService().initPushNotifications();
    } catch (e) {
      // Log to sentry ideally
      debugPrint('Supabase Profile Sync Error: $e');
    }
  }
}
