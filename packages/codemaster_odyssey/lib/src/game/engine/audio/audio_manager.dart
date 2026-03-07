import 'package:flame_audio/flame_audio.dart';

/// Stub audio manager for background music and SFX.
///
/// This manager wraps `flame_audio` calls behind a clean API.
/// Audio files should be placed in `assets/audio/`.
///
/// Usage:
/// ```dart
/// AudioManager.playBGM('region_1_theme.mp3');
/// AudioManager.playSFX('hit.wav');
/// ```
class AudioManager {
  static bool _muted = false;

  /// Whether audio is globally muted.
  static bool get isMuted => _muted;

  /// Plays a background music track (loops by default).
  ///
  /// Call `stopBGM()` before switching tracks.
  static Future<void> playBGM(String filename) async {
    if (_muted) return;
    try {
      await FlameAudio.bgm.play(filename, volume: 0.5);
    } catch (e) {
      // Audio file might be missing
    }
  }

  /// Plays the boss encounter jingle.
  static Future<void> playBossIntro() async {
    await playSFX('boss_intro.wav');
  }

  /// Plays a challenge-complete jingle.
  static Future<void> playChallengeComplete() async {
    await playSFX('challenge_complete.wav');
  }

  /// Plays a death/respawn sound.
  static Future<void> playDeathSFX() async {
    await playSFX('death.wav');
  }

  /// Plays a portal/region transition sound.
  static Future<void> playPortalSFX() async {
    await playSFX('portal_enter.wav');
  }

  /// Plays the correct region BGM based on region number.
  static Future<void> playRegionTheme(int region) async {
    if (_muted) return;
    // Each region maps to a named audio file
    final filename = 'region_${region}_theme.mp3';
    await stopBGM();
    await playBGM(filename);
  }

  /// Plays a one-shot sound effect.
  static Future<void> playSFX(String filename) async {
    if (_muted) return;
    try {
      await FlameAudio.play(filename, volume: 0.7);
    } catch (e) {
      // Audio file might be missing
    }
  }

  /// Plays a UI click/confirm sound.
  static Future<void> playUIClick() async {
    await playSFX('ui_click.wav');
  }

  /// Stops all audio (BGM and SFX).
  static void stopAll() {
    FlameAudio.bgm.stop();
    FlameAudio.audioCache.clearAll();
  }

  /// Stops the currently playing background music.
  static Future<void> stopBGM() async {
    await FlameAudio.bgm.stop();
  }

  /// Toggles global mute on/off.
  static void toggleMute() {
    _muted = !_muted;
    if (_muted) {
      stopAll();
    }
  }
}
