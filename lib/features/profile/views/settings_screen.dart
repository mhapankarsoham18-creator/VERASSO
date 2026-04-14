import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../auth/views/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          NeoPixelBox(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 2, fontSize: 12)),
                const SizedBox(height: 16),
                _pixelSettingTile(Icons.person, 'Edit Profile', () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon.')));
                }),
                _pixelSettingTile(Icons.lock, 'Privacy & Security', () {}),
                _pixelSettingTile(Icons.shield, 'Data & Permissions', () {}),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NeoPixelBox(
            padding: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('SYSTEM', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textSecondary, letterSpacing: 2, fontSize: 12)),
                const SizedBox(height: 16),
                _pixelSettingTile(Icons.color_lens, 'Theme Configuration', () {}),
                _pixelSettingTile(Icons.code, 'Developer Mesh Options', () {}),
                _pixelSettingTile(Icons.info_outline, 'About Grid', () {}),
              ],
            ),
          ),
          const SizedBox(height: 32),
          NeoPixelBox(
            padding: 16,
            isButton: true,
            onTap: () => _signOut(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.power_settings_new, color: AppColors.error),
                SizedBox(width: 8),
                Text('TERMINATE SESSION', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pixelSettingTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1))),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
