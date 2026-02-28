import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../profile/presentation/profile_controller.dart';

/// Screen that simulates an age-verification flow for the Talent feature.
///
/// In the current implementation, documents are selected locally and the
/// profile is marked as verified immediately via a simulation method.
class AgeVerificationScreen extends ConsumerStatefulWidget {
  /// Creates an [AgeVerificationScreen].
  const AgeVerificationScreen({super.key});

  @override
  ConsumerState<AgeVerificationScreen> createState() =>
      _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends ConsumerState<AgeVerificationScreen> {
  File? _selectedDoc;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Age Verification'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(LucideIcons.contact,
                        size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      'Provide Identity Document',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload a photo of your ID card, Passport, or a signed permission note from your parent/guardian.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white24, style: BorderStyle.solid),
                        ),
                        child: _selectedDoc == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.upload,
                                      color: Colors.white54),
                                  SizedBox(height: 8),
                                  Text('Select Image',
                                      style: TextStyle(color: Colors.white54)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_selectedDoc!,
                                    fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_selectedDoc == null || _isSubmitting)
                            ? null
                            : _submitVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Submit for Verification'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Privacy Note: Your documents are only used for age verification and are stored securely with end-to-end encryption.',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the gallery to pick an image representing an identity document.
  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedDoc = File(image.path);
      });
    }
  }

  /// Submits the simulated verification and marks the profile as verified.
  ///
  /// In a production deployment this would upload the document to secure
  /// storage and wait for manual or automated approval.
  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);

    // In a real app, this would upload to Supabase Storage and wait for admin approval
    // For this demo, we use the simulation method to mark the user as verified instantly
    await ref.read(profileControllerProvider.notifier).simulateVerification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Verification documents submitted! Your age is now verified (Simulated).')),
      );
      Navigator.pop(context);
    }
  }
}
