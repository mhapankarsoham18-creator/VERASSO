import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutralBg,
      appBar: AppBar(
        title: Text('Legal & Compliance', style: TextStyle(fontWeight: FontWeight.bold, color: context.colors.primary)),
        backgroundColor: context.colors.neutralBg,
        iconTheme: IconThemeData(color: context.colors.primary),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Privacy Policy', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Last updated: May 2026\n\n'
                '1. Information Collection: We collect your display name, email, avatar, and any media you choose to upload to Verasso. We also collect usage analytics to improve our services.\n\n'
                '2. Usage of Data: Your data is solely used to provide you the Verasso social experience, facilitate connections, and improve application stability.\n\n'
                '3. COPPA Compliance (Children\'s Privacy): Verasso is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are under 13, please do not use or provide any information on this App. If we learn we have collected or received personal information from a child under 13 without verification of parental consent, we will delete that information.\n\n'
                '4. End-to-End Encryption: Private messages sent via Verasso are end-to-end encrypted locally before transmission. We do not hold the keys to decrypt your personal messages.\n\n'
                '5. Data Deletion: You may request account and data deletion at any time in the settings page or by contacting support.\n\n',
                style: TextStyle(color: context.colors.textSecondary, height: 1.5, fontSize: 16)),
            SizedBox(height: 24),
            Text('Terms of Service', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: context.colors.primary, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('1. Acceptance: By using Verasso, you agree to abide by these terms.\n\n'
                '2. User Conduct: You agree not to post illegal, abusive, or hateful content. Verasso reserves the right to terminate accounts violating these terms.\n\n'
                '3. Limitation of Liability: Verasso is provided "as is" without warranty. We are not liable for any damages arising from your use of the app.\n\n'
                '4. Intellectual Property: You retain ownership of the content you post, but you grant Verasso a license to host and display it within the app.\n\n',
                style: TextStyle(color: context.colors.textSecondary, height: 1.5, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
