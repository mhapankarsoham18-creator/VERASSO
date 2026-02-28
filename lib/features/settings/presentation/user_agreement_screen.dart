import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

/// Screen displaying the platform's terms and user agreement.
class UserAgreementScreen extends ConsumerStatefulWidget {
  /// Creates a [UserAgreementScreen].
  const UserAgreementScreen({super.key});

  @override
  ConsumerState<UserAgreementScreen> createState() =>
      _UserAgreementScreenState();
}

class _UserAgreementScreenState extends ConsumerState<UserAgreementScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Platform Terms'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: GlassContainer(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<String>(
                    future: rootBundle
                        .loadString('assets/docs/TERMS_OF_SERVICE.md'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text('Error loading platform terms.',
                                style: TextStyle(color: Colors.white)));
                      }
                      return Markdown(
                        data: snapshot.data ?? '',
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(Theme.of(context))
                                .copyWith(
                          p: const TextStyle(
                              color: Colors.white70, fontSize: 14),
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
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _acceptTerms,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('I AGREE TO THESE TERMS'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptTerms() async {
    setState(() => _isLoading = true);
    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) return;

      // Update profile with accepted terms version 1
      await Supabase.instance.client
          .from('profiles')
          .update({'accepted_terms_version': 1}).eq('id', userId);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate acceptance
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Terms Accepted. Welcome to the Economy! 🤝')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
