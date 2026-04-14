import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/shell/feed'); // Ensure dynamic feed mounting
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Authentication failed';
      if (e.code == 'user-not-found') {
        msg = 'No user found for that email. Sign up instead.';
      } else if (e.code == 'wrong-password') {
        msg = 'Wrong password provided. Tap Forgot Password to reset.';
      } else if (e.code == 'invalid-credential') {
        msg = 'Invalid credentials. Please check your email or password.';
      } else if (e.code == 'too-many-requests') {
        msg = 'Too many attempts. Try again later.';
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loginGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) context.go('/shell/feed');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) {
        final resetEmailCtrl = TextEditingController(text: _emailCtrl.text);
        return AlertDialog(
          backgroundColor: AppColors.neutralBg,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.blockEdge, width: 2),
            borderRadius: BorderRadius.circular(0),
          ),
          title: Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your email to reset your password.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              NeoPixelBox(
                padding: 8,
                child: TextField(
                  controller: resetEmailCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                if (resetEmailCtrl.text.isEmpty) return;
                Navigator.of(ctx).pop();
                try {
                  await ref.read(authServiceProvider).sendPasswordResetEmail(resetEmailCtrl.text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password reset link sent!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('SEND RESET LINK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'VERASSO',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'P2P Knowledge Grid',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 60),

                // Inputs
                NeoPixelBox(
                  padding: 8,
                  child: TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                NeoPixelBox(
                  padding: 8,
                  child: TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Login Buttons
                NeoPixelBox(
                  isButton: true,
                  onTap: _login,
                  padding: 16,
                  child: Center(
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: AppColors.primary)
                      : Text('LOGIN', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 24, color: AppColors.primary,
                        )),
                  ),
                ),
                
                const SizedBox(height: 24),

                NeoPixelBox(
                  isButton: true,
                  onTap: _isLoading ? null : _loginGoogle,
                  padding: 16,
                  child: Center(
                    child: Text('Login with Google', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 24, color: AppColors.textPrimary,
                    )),
                  ),
                ),

                const SizedBox(height: 48),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text('New Experience — Let\'s Sign Up', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
