import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:verasso/core/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../astronomy/rendering/crt_overlay.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _loadingText = "BOOTING VERASSO OS...";
  
  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  void _startBootSequence() async {
    final sequence = [
      "INITIALIZING SECURE PROTOCOLS...",
      "LOADING MESH NODES...",
      "CALIBRATING NEURAL LINK...",
      "ACCESS GRANTED."
    ];

    for (String step in sequence) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _loadingText = step);
    }

    await Future.delayed(const Duration(milliseconds: 400));
    _navigateToNext();
  }

  void _navigateToNext() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Check if profile exists and has a username
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('firebase_uid', user.uid)
            .maybeSingle();
            
        if (!mounted) return;
        
        if (profile != null && profile['username'] != null) {
          context.go('/shell/feed');
        } else {
          // If profile was wiped or not completely set up
          context.go('/profile_setup');
        }
      } catch (e) {
        if (mounted) context.go('/profile_setup');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Force true black for CRT deep contrast
      body: Semantics(
        label: 'Retro CRT monitor scanline effect',
        child: CustomPaint(
          foregroundPainter: CrtOverlay(),
          child: Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder or text
              Text(
                'VERASSO',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                  color: context.colors.primary,
                  shadows: [
                    Shadow(color: context.colors.primary, blurRadius: 20)
                  ]
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.primary.withValues(alpha: 0.5), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 18, color: context.colors.primary), // Block cursor
                    const SizedBox(width: 8),
                    Text(
                      _loadingText,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
