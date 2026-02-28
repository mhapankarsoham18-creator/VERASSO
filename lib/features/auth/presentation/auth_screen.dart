import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../core/exceptions/user_friendly_error_handler.dart';
import '../../../core/monitoring/sentry_service.dart';
import '../../../core/security/biometric_auth_service.dart';
import '../../../core/security/screen_security_service.dart';
import '../../../core/ui/error_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_repository.dart';
import 'auth_controller.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/kinetic_code_input.dart';

/// The main authentication screen providing Login, Signup, OTP, and Reset Password flows.
///
/// This screen uses [LiquidBackground] and [GlassContainer] for its visual identity
/// and integrates with [AuthController] for session management.
class AuthScreen extends ConsumerStatefulWidget {
  /// Whether to initially show the password reset view.
  final bool showResetView;

  /// Creates an [AuthScreen].
  const AuthScreen({super.key, this.showResetView = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _otpController = TextEditingController();
  late BiometricAuthService _biometricService;

  bool _isLogin = true;
  bool _useOtp = false; // Toggle between Password and OTP login
  bool _showOtpInput = false; // Show OTP field after sending
  bool _useBackupCode = false; // Toggle between OTP and Backup Code
  bool _isResetPassword = false; // Toggle for Forgot Password flow

  bool _isUsernameTaken = false;
  bool _isValidatingUsername = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  Timer? _debounce;
  bool _backupCodeError = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final cooldownUntil = ref.watch(loginCooldownUntilProvider);

    // When cooldown is set, clear it after it expires so the UI updates (Phase 2.1).
    ref.listen(loginCooldownUntilProvider, (previous, next) {
      if (next != null && previous != next) {
        final remaining = next.difference(DateTime.now());
        if (remaining.isNegative) {
          ref.read(loginCooldownUntilProvider.notifier).state = null;
        } else {
          Future.delayed(remaining, () {
            ref.read(loginCooldownUntilProvider.notifier).state = null;
          });
        }
      }
    });

    final inCooldown =
        cooldownUntil != null && DateTime.now().isBefore(cooldownUntil);
    final cooldownSeconds =
        inCooldown ? cooldownUntil.difference(DateTime.now()).inSeconds : 0;

    // Listen to errors
    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ErrorDialog.show(
          context,
          title: AppLocalizations.of(context)!.authenticationError,
          message: UserFriendlyErrorHandler.getDisplayMessage(next.error),
          onRetry: () {
            // Retry logic handled by user pressing login again
          },
        );
      }
    });

    // Listen to MFA Requirement
    ref.listen(mfaRequirementProvider, (previous, next) {
      if (next != null && mounted) {
        setState(() {
          _showOtpInput = true;
          _useBackupCode = false;
        });
      }
    });

    return Scaffold(
      body: LiquidBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassContainer(
              opacity: 0.15,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _showOtpInput
                        ? (_useBackupCode
                            ? l10n.useRecoveryKey
                            : l10n.verifyOtp)
                        : (_isResetPassword
                            ? l10n.resetAccess
                            : (_isLogin
                                ? l10n.welcomeBackPioneer
                                : l10n.initiateDiscovery)),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showOtpInput
                        ? (_useBackupCode
                            ? l10n.recoveryKeyBody
                            : l10n.otpSentBody(_emailController.text))
                        : (_isResetPassword
                            ? l10n.reestablishNeuralLink
                            : (_isLogin
                                ? l10n.reestablishingUplink
                                : l10n.joinNeuralNetwork)),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  if (!_showOtpInput) ...[
                    if (!_isLogin) ...[
                      AuthTextField(
                        controller: _usernameController,
                        label: l10n.username,
                        icon: LucideIcons.user,
                        textFieldKey: const Key('username_field'),
                      ),
                      if (_isUsernameTaken)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 12),
                          child: Text(l10n.usernameTaken,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 10)),
                        )
                      else if (_isValidatingUsername)
                        const Padding(
                          padding: EdgeInsets.only(top: 4, left: 12),
                          child: SizedBox(
                              height: 10,
                              width: 10,
                              child: CircularProgressIndicator(strokeWidth: 1)),
                        ),
                      const SizedBox(height: 16),
                    ],
                    AuthTextField(
                        controller: _emailController,
                        label: l10n.email,
                        icon: LucideIcons.mail,
                        textFieldKey: const Key('email_field')),
                    const SizedBox(height: 16),
                    if (!_useOtp)
                      AuthTextField(
                        controller: _passwordController,
                        label: l10n.password,
                        icon: LucideIcons.lock,
                        isPassword: true,
                        textFieldKey: const Key('password_field'),
                      ),
                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _useOtp = !_useOtp;
                            });
                          },
                          child: Text(_useOtp
                              ? l10n.useMasterPassword
                              : l10n.verifyWithTemporalCode),
                        ),
                      ),
                  ] else ...[
                    if (!_useBackupCode)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _useBackupCode = true;
                              _otpController.clear();
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.helpCircle,
                                  size: 14, color: Colors.orangeAccent),
                              const SizedBox(width: 8),
                              Text(
                                l10n.lostAuthApp,
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    KineticCodeInput(
                      controller: _otpController,
                      codeLength: _useBackupCode ? 8 : 6,
                      hasError: _backupCodeError,
                      onCompleted: _submit,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _useBackupCode = !_useBackupCode;
                            _otpController.clear();
                            _backupCodeError = false;
                          });
                        },
                        child: Text(_useBackupCode
                            ? l10n.switchToAppOtp
                            : l10n.useRecoveryKey),
                      ),
                    ),
                  ],

                  if (_isLogin &&
                      !_useOtp &&
                      !_showOtpInput &&
                      !_isResetPassword)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isResetPassword = true;
                            _isLogin = false; // Temporarily switch off login UI
                          });
                        },
                        child: Text(l10n.forgotPassword,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),

                  if (inCooldown)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        l10n.tooManyAttempts(cooldownSeconds.toString()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (authState.isLoading ||
                              inCooldown ||
                              (!_isLogin &&
                                  (_isUsernameTaken || _isValidatingUsername)))
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0),
                      child: authState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _showOtpInput
                                  ? l10n.verify
                                  : (_isResetPassword
                                      ? l10n.resetPassword
                                      : (_isLogin
                                          ? (_useOtp
                                              ? l10n.sendMagicCode
                                              : l10n.signIn)
                                          : (_isUsernameTaken
                                              ? l10n.checkUsername
                                              : l10n.signUp))),
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              key: const Key('login_button')),
                    ),
                  ),

                  // Biometric Login Button (only on login screen)
                  if (_isLogin &&
                      !_showOtpInput &&
                      !_isResetPassword &&
                      _biometricAvailable &&
                      _biometricEnabled) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: authState.isLoading
                            ? null
                            : _authenticateWithBiometric,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(LucideIcons.fingerprint),
                        label: Text(
                          l10n.loginWithBiometric,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],

                  if (_isLogin && !_showOtpInput && !_isResetPassword) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(l10n.orLabel,
                              style: const TextStyle(
                                  color: Colors.white24, fontSize: 12)),
                        ),
                        const Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : () => ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: const BorderSide(color: Colors.white24),
                            ),
                            icon: const Icon(LucideIcons.chrome, size: 20),
                            label: Text(l10n.google),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: authState.isLoading
                                ? null
                                : () => ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithApple(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: const BorderSide(color: Colors.white24),
                            ),
                            icon: const Icon(LucideIcons.apple, size: 20),
                            label: Text(l10n.apple),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  if (!_showOtpInput)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                          _useOtp =
                              false; // Reset OTP mode when switching auth type
                        });
                      },
                      child: Text(_isLogin
                          ? l10n.createAccount
                          : l10n.alreadyHaveAccount),
                    ),

                  if (_showOtpInput)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showOtpInput = false;
                        });
                      },
                      child: Text(l10n.backToLogin),
                    )
                  else if (_isResetPassword)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isResetPassword = false;
                          _isLogin = true;
                        });
                      },
                      child: Text(l10n.backToLogin),
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _otpController.dispose();
    ScreenSecurityService.unprotectScreen();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _biometricService = ref.read(biometricAuthServiceProvider);
    _usernameController.addListener(_onUsernameChanged);
    _checkBiometricAndPrompt();
    ScreenSecurityService.protectScreen();

    if (widget.showResetView) {
      _isResetPassword = true;
      _isLogin = false;
    }
  }

  // Authenticate with biometric
  Future<void> _authenticateWithBiometric() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      SentryService.addBreadcrumb(
        message: 'User attempting biometric authentication',
        category: 'auth',
      );

      final authenticated = await _biometricService.authenticate(
        reason: l10n.biometricLoginReason,
      );

      if (authenticated.success && mounted) {
        // Biometric success - attempt auto-login
        // Note: In production, you'd retrieve stored email or user ID
        // For now, we'll show a success message and let user proceed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.biometricVerified),
            backgroundColor: Colors.green,
          ),
        );

        SentryService.addBreadcrumb(
          message: 'Biometric authentication successful',
          category: 'auth',
          level: SentryLevel.info,
        );

        // Success! Perform auto-login
        await ref.read(authControllerProvider.notifier).signInWithBiometrics();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.welcomeBack),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SentryService.captureException(
          e,
          hint: 'Biometric authentication failed',
        );
      }
    }
  }

  // Check if biometric is enabled and show prompt
  Future<void> _checkBiometricAndPrompt() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      final enabled = await _biometricService.isBiometricEnabled();

      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _biometricEnabled = enabled;
        });

        // Auto-prompt for biometric if enabled and on login screen
        if (_isLogin && available && enabled) {
          // Small delay to let UI settle
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _authenticateWithBiometric();
          }
        }
      }
    } catch (e) {
      SentryService.captureException(e, hint: 'Biometric check failed');
    }
  }

  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final username = _usernameController.text.trim();
      if (username.length > 2) {
        setState(() => _isValidatingUsername = true);
        final available = await ref
            .read(profileRepositoryProvider)
            .isUsernameAvailable(username);
        if (mounted) {
          setState(() {
            _isUsernameTaken = !available;
            _isValidatingUsername = false;
          });
        }
      }
    });
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final otp = _otpController.text.trim();

    final l10n = AppLocalizations.of(context)!;

    if (email.isEmpty) return;

    if (_showOtpInput) {
      if (otp.isEmpty) return;

      if (_useBackupCode) {
        // Verify Backup Code
        _verifyBackupCode(otp);
        return;
      }

      // Step 2: Verify OTP or MFA
      final mfaRequirement = ref.read(mfaRequirementProvider);
      if (mfaRequirement != null) {
        await ref.read(authControllerProvider.notifier).verifyMFA(
              factorId: mfaRequirement.factorId,
              challengeId: mfaRequirement.challengeId,
              code: otp,
            );
        // Clear requirement on success
        ref.read(mfaRequirementProvider.notifier).state = null;
        return;
      }

      ref
          .read(authControllerProvider.notifier)
          .verifyOtp(email: email, token: otp);
      return;
    }

    if (_useOtp && _isLogin) {
      // Step 1: Request OTP
      await ref.read(authControllerProvider.notifier).signInWithOtpEmail(email);
      if (!context.mounted) return;

      final messengerContext = context;
      if (messengerContext.mounted) {
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(content: Text(l10n.otpSentFeedback)),
        );
      }
      setState(() {
        _showOtpInput = true;
      });
      return;
    }

    if (_isResetPassword) {
      await ref.read(authControllerProvider.notifier).resetPassword(email);
      if (!context.mounted) return;

      final messengerContext = context;
      if (messengerContext.mounted) {
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(content: Text(l10n.passwordResetSent)),
        );
      }
      setState(() {
        _isResetPassword = false;
        _isLogin = true;
      });
      return;
    }

    // Standard Password Flow
    if (password.isEmpty) return;

    if (!_isLogin) {
      if (username.isEmpty) return;
      if (_isUsernameTaken || _isValidatingUsername) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.usernameTaken),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      ref
          .read(authControllerProvider.notifier)
          .signUp(email: email, password: password, username: username);
    } else {
      ref
          .read(authControllerProvider.notifier)
          .signIn(email: email, password: password);
    }
  }

  Future<void> _verifyBackupCode(String code) async {
    try {
      final l10n = AppLocalizations.of(context)!;
      await ref.read(authControllerProvider.notifier).verifyBackupCode(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recoverySuccessful),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate away or refresh state - the AuthState stream will handle the session change
      }
    } catch (e) {
      setState(() => _backupCodeError = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _backupCodeError = false);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(UserFriendlyErrorHandler.getDisplayMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
