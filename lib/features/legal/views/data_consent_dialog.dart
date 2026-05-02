import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'legal_screen.dart';

class DataConsentDialog extends StatelessWidget {
  final VoidCallback onAccept;

  const DataConsentDialog({super.key, required this.onAccept});

  static Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('data_consent_v1') ?? false;
  }

  static Future<void> markConsented() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_consent_v1', true);
  }

  static Future<void> showIfNeeded(BuildContext context, VoidCallback onAccept) async {
    if (await hasConsented()) {
      onAccept();
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => DataConsentDialog(
          onAccept: () async {
            await markConsented();
            if (ctx.mounted) Navigator.of(ctx).pop();
            onAccept();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.colors.neutralBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.primary, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: context.colors.primary),
                SizedBox(width: 8),
                Expanded(child: Text('Data Privacy Consent', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: context.colors.primary))),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Verasso requires your consent to collect basic profile data (email, name) and usage analytics to provide you a stable, secure experience. '
              'By continuing, you agree to our Privacy Policy and Terms of Service.',
              style: TextStyle(color: context.colors.textSecondary, height: 1.4, fontSize: 14),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LegalScreen()));
              },
              child: Text(
                'Read Privacy Policy',
                style: TextStyle(color: context.colors.accent, decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: NeoPixelBox(
                isButton: true,
                padding: 16,
                onTap: onAccept,
                child: Center(
                  child: Text(
                    'I AGREE & CONTINUE',
                    style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
