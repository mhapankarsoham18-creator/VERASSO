import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/neo_pixel_box.dart';

/// A premium, retro-styled snackbar for the Verasso app.
class VerassoSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    bool isError = false,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating, // Floating allows us to position it
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        // Use an animation curve for the pop up
        animation: CurvedAnimation(
          parent: const AlwaysStoppedAnimation(1.0),
          curve: Curves.easeOutBack,
        ),
        content: NeoPixelBox(
          padding: 16.0,
          enableTilt: false,
          backgroundColor: isError ? context.colors.error : context.colors.neutralBg,
          child: Row(
            children: [
              Icon(
                isError ? Icons.warning_amber_rounded : Icons.info_outline,
                color: isError ? context.colors.neutralBg : context.colors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message.toUpperCase(),
                  style: GoogleFonts.vt323(
                    textStyle: TextStyle(
                      fontSize: 18,
                      color: isError ? context.colors.neutralBg : context.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
