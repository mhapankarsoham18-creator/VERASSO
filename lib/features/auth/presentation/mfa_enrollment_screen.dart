import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:verasso/core/ui/error_dialog.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/mfa_controller.dart';
import 'package:verasso/features/auth/presentation/widgets/auth_text_field.dart';

import '../domain/mfa_models.dart';

/// Screen for enrolling in Multi-Factor Authentication.
///
/// Displays a QR code for the user to scan into their authenticator app.
class MFAEnrollmentScreen extends ConsumerStatefulWidget {
  /// Creates an [MFAEnrollmentScreen].
  const MFAEnrollmentScreen({super.key});

  @override
  ConsumerState<MFAEnrollmentScreen> createState() =>
      _MFAEnrollmentScreenState();
}

class _MFAEnrollmentScreenState extends ConsumerState<MFAEnrollmentScreen> {
  final _codeController = TextEditingController();
  MfaEnrollment? _enrollResponse;

  @override
  Widget build(BuildContext context) {
    final mfaState = ref.watch(mfaControllerProvider);

    ref.listen(mfaControllerProvider, (previous, next) {
      if (next.hasError) {
        ErrorDialog.show(
          context,
          title: 'MFA Setup Error',
          message: next.error.toString(),
          onRetry: () {
            _startEnrollment();
          },
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Enable 2FA')),
      body: LiquidBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Secure Your Account',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan the QR code below with your Authenticator App (Google Authenticator, Authy, etc.)',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_enrollResponse != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: QrImageView(
                        data: _enrollResponse!.totpUri ?? '',
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      'Or enter this secret key:\n${_enrollResponse!.totpSecret ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ] else ...[
                    const CircularProgressIndicator()
                  ],
                  const SizedBox(height: 32),
                  const Text('Enter the 6-digit code from your app:'),
                  const SizedBox(height: 8),
                  AuthTextField(
                      controller: _codeController,
                      label: '000 000',
                      icon: LucideIcons.shieldCheck),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: mfaState.isLoading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: mfaState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Verify & Enable',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Start enrollment process immediately on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startEnrollment();
    });
  }

  Future<void> _startEnrollment() async {
    final response = await ref.read(mfaControllerProvider.notifier).enroll();
    setState(() {
      _enrollResponse = response;
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;

    if (_enrollResponse == null) return;

    // We challenge and verify the Factor ID immediately to enable it.
    await ref
        .read(mfaControllerProvider.notifier)
        .verifyAndEnable(_enrollResponse!.id, code);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-Factor Authentication Enabled!')),
      );
      Navigator.of(context).pop(); // Go back to settings/home
    }
  }
}
