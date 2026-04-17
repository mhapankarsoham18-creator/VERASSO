import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../auth/views/login_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: ListView(
        padding: EdgeInsets.all(24),
        children: [
          NeoPixelBox(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.textSecondary, letterSpacing: 2, fontSize: 12)),
                SizedBox(height: 16),
                _pixelSettingTile(context, Icons.person, 'Edit Profile', () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen()));
                }),
                _pixelSettingTile(context, Icons.lock, 'Privacy & Security', () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PrivacySettingsScreen()));
                }),
                _pixelSettingTile(context, Icons.shield, 'Data & Permissions', () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Permissions managed via OS.')));
                }),
              ],
            ),
          ),
          SizedBox(height: 24),
          NeoPixelBox(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('SYSTEM', style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.textSecondary, letterSpacing: 2, fontSize: 12)),
                SizedBox(height: 16),
                _pixelSettingTile(context, Icons.color_lens, 'Theme Configuration', () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: context.colors.neutralBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: context.colors.blockEdge, width: 3)),
                      title: Text('SELECT THEME', style: TextStyle(fontWeight: FontWeight.w900, color: context.colors.textPrimary)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text('Classic Earth', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                            onTap: () {
                              ref.read(themeProvider.notifier).setTheme(AppThemeType.classic);
                              Navigator.pop(ctx);
                            },
                          ),
                          ListTile(
                            title: Text('Bladerunner (Cyberpunk)', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
                            onTap: () {
                              ref.read(themeProvider.notifier).setTheme(AppThemeType.bladerunner);
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                _pixelSettingTile(context, Icons.code, 'Developer Mesh Options', () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Developer settings locked.')));
                }),
                _pixelSettingTile(context, Icons.info_outline, 'About Grid', () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'VERASSO',
                    applicationVersion: '1.0.0-phase2',
                    applicationIcon: Icon(Icons.bolt, color: context.colors.primary, size: 48),
                    children: [
                      Text('Built for mesh-networking space exploration.\nCompliant with DPDP Act 2023.', style: TextStyle(color: context.colors.textSecondary)),
                    ]
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 32),
          NeoPixelBox(
            padding: 16,
            isButton: true,
            onTap: () => _signOut(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.power_settings_new, color: context.colors.error),
                SizedBox(width: 8),
                Text('TERMINATE SESSION', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pixelSettingTile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colors.primary),
            SizedBox(width: 16),
            Expanded(child: Text(label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1))),
            Icon(Icons.chevron_right, size: 16, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
