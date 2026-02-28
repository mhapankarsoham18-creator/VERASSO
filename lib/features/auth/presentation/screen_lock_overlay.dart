import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/security/biometric_auth_service.dart';
import 'package:verasso/core/security/session_timeout_service.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

/// An overlay that blurs the screen and requires biometric authentication to unlock.
///
/// Used by the [SessionTimeoutService] to protect the application during inactivity.
class ScreenLockOverlay extends ConsumerStatefulWidget {
  /// The widget tree to be displayed behind the lock overlay.
  final Widget child;

  /// Creates a [ScreenLockOverlay].
  const ScreenLockOverlay({super.key, required this.child});

  @override
  ConsumerState<ScreenLockOverlay> createState() => _ScreenLockOverlayState();
}

class _FadeInUpAnimation extends StatefulWidget {
  final Widget child;
  const _FadeInUpAnimation({required this.child});

  @override
  State<_FadeInUpAnimation> createState() => _FadeInUpAnimationState();
}

class _FadeInUpAnimationState extends State<_FadeInUpAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _offset = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }
}

class _ScreenLockOverlayState extends ConsumerState<ScreenLockOverlay> {
  final _biometricService = BiometricAuthService();
  bool _isAuthenticating = false;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionTimeoutProvider);

    return Stack(
      children: [
        widget.child,
        if (sessionState.isLocked)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: _FadeInUpAnimation(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GlassContainer(
                              width: 320,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 40, horizontal: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.lock,
                                      size: 64, color: Colors.orange),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Verasso is Locked',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Your session timed out due to inactivity.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 40),
                                  ElevatedButton.icon(
                                    onPressed:
                                        _isAuthenticating ? null : _tryUnlock,
                                    icon: const Icon(LucideIcons.fingerprint),
                                    label: const Text('Unlock with Biometrics'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _signOut,
                                    child: const Text('Sign Out',
                                        style:
                                            TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _signOut() {
    ref.read(authControllerProvider.notifier).signOut();
    ref.read(sessionTimeoutProvider).unlock();
  }

  Future<void> _tryUnlock() async {
    if (_isAuthenticating) return;

    setState(() => _isAuthenticating = true);
    try {
      final available = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.isBiometricEnabled();

      if (available && enabled) {
        final result = await _biometricService.authenticate(
          reason: 'Please authenticate to unlock Verasso',
        );
        if (result.success) {
          ref.read(sessionTimeoutProvider).unlock();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Biometric authentication not available or enabled.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }
}
