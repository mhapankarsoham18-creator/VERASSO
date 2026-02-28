import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// Screen displaying the application's terms of service.
class TermsOfServiceScreen extends StatelessWidget {
  /// Creates a [TermsOfServiceScreen].
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Last updated: February 01, 2026',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const Divider(height: 32, color: Colors.white24),
                _buildSection(
                  '1. Acceptance of Terms',
                  'By using Verasso, you agree to these terms. If you do not agree, do not use the application.',
                ),
                _buildSection(
                  '2. User Conduct',
                  'You agree not to use the service for any illegal or unauthorized purpose. You must not violate any laws in your jurisdiction.',
                ),
                _buildSection(
                  '3. Intellectual Property',
                  'All content shared on Verasso remains the property of the respective owners. Verasso claims no ownership over user content.',
                ),
                _buildSection(
                  '4. Termination',
                  'We reserve the right to terminate or suspend access to our service immediately, without prior notice, for any reason whatsoever.',
                ),
                _buildSection(
                  '5. Limitation of Liability',
                  'Verasso shall not be liable for any indirect, incidental, special, consequential or punitive damages.',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(height: 1.5, color: Colors.white70)),
        ],
      ),
    );
  }
}
