import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../../core/utils/password_validator.dart';
import '../auth_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  String? _passwordError;
  bool _isLoading = false;
  
  // Real-time strength trackers
  int _passwordStrength = 0;
  String _strengthLabel = "None";
  Color _strengthColor = AppColors.neutralBg;

  void _signup() async {
    final validationResult = PasswordValidator.validate(_passwordCtrl.text);
    if (validationResult != null) {
      setState(() => _passwordError = validationResult);
      return;
    }

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() => _passwordError = "Passwords do not match");
      return;
    }

    setState(() {
      _passwordError = null;
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).signUp(_emailCtrl.text, _passwordCtrl.text);
      if (mounted) context.go('/profile_setup');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User already exists! Please go back and Login.')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? e.toString())));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signupGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (mounted) context.go('/profile_setup');
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? e.toString())));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('New Experience — Let\'s Sign Up'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              NeoPixelBox(
                padding: 8,
                child: TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
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
                  onChanged: (val) {
                    _updatePasswordStrength(val);
                    if (_passwordError != null) {
                      setState(() => _passwordError = PasswordValidator.validate(val));
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Secure Password',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Password strength indicator
              if (_passwordCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            for (int i = 0; i < 4; i++)
                              Expanded(
                                child: Container(
                                  height: 8,
                                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                                  decoration: BoxDecoration(
                                    color: i < _passwordStrength ? _strengthColor : AppColors.shadowDark,
                                    border: Border.all(color: AppColors.blockEdge, width: 1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _strengthLabel,
                        style: TextStyle(
                          color: _strengthColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              NeoPixelBox(
                padding: 8,
                child: TextField(
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  onChanged: (val) {
                    if (_passwordError == "Passwords do not match" && val == _passwordCtrl.text) {
                      setState(() => _passwordError = null);
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Confirm Password',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              if (_passwordError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _passwordError!,
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
              ],
              
              const SizedBox(height: 60),

              NeoPixelBox(
                isButton: true,
                onTap: _signup,
                padding: 16,
                child: Center(
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : Text('REGISTER', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 24, color: AppColors.primary,
                      )),
                ),
              ),
              const SizedBox(height: 24),
              NeoPixelBox(
                isButton: true,
                onTap: _isLoading ? null : _signupGoogle,
                padding: 16,
                child: Center(
                  child: Text('Sign up with Google', style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 24, color: AppColors.textPrimary,
                  )),
                ),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Already have an account? Login', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _updatePasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _strengthLabel = "None";
      });
      return;
    }
    
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#\$&*~]'))) strength++;

    Color sColor = AppColors.error;
    String sLabel = "Weak";

    if (strength == 2) {
      sColor = Colors.orange;
      sLabel = "Fair";
    } else if (strength == 3) {
      sColor = Colors.yellow.shade700;
      sLabel = "Good";
    } else if (strength == 4) {
      sColor = AppColors.primary;
      sLabel = "Strong";
    }

    setState(() {
      _passwordStrength = strength;
      _strengthColor = sColor;
      _strengthLabel = sLabel;
    });
  }
}
