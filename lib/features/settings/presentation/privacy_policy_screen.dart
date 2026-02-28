import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// Screen displaying the application's privacy policy.
class PrivacyPolicyScreen extends StatelessWidget {
  /// Creates a [PrivacyPolicyScreen].
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: LiquidBackground(
        child: FutureBuilder<String>(
          future: rootBundle.loadString('assets/docs/PRIVACY_POLICY.md'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading privacy policy.',
                      style: const TextStyle(color: Colors.white)));
            }
            return Markdown(
              data: snapshot.data ?? '',
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(color: Colors.white70, fontSize: 16),
                h1: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                h2: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                h3: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
    );
  }
}
