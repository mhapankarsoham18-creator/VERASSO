import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../profile/presentation/profile_controller.dart';
import '../data/mentor_model.dart';
import '../data/mentor_repository.dart';

/// Screen for users to apply to become a mentor.
class MentorOnboardingScreen extends ConsumerStatefulWidget {
  /// Creates a [MentorOnboardingScreen].
  const MentorOnboardingScreen({super.key});

  @override
  ConsumerState<MentorOnboardingScreen> createState() =>
      _MentorOnboardingScreenState();
}

class _MentorOnboardingScreenState
    extends ConsumerState<MentorOnboardingScreen> {
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _expController = TextEditingController();
  final _specializationController = TextEditingController();

  final List<Map<String, String>> _degrees = [];
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Mentor Application'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 120),
          child: Column(
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Professional Foundation',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildTextField(
                        _headlineController,
                        'Professional Headline',
                        'e.g. Senior Product Designer'),
                    const SizedBox(height: 12),
                    _buildTextField(_expController,
                        'Years of Industry Experience', 'e.g. 5',
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    _buildTextField(
                        _specializationController,
                        'Specializations',
                        'e.g. UI/UX, Flutter, Dart (comma separated)'),
                    const SizedBox(height: 12),
                    _buildTextField(_bioController, 'Professional Bio',
                        'Tell us about your journey...',
                        maxLines: 4),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Educational Degrees',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                            onPressed: _addDegree,
                            icon: const Icon(LucideIcons.plusCircle,
                                color: Colors.blueAccent)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._degrees
                        .asMap()
                        .entries
                        .map((entry) => _buildDegreeFields(entry.key)),
                    if (_degrees.isEmpty)
                      const Text('Add your degrees to boost credibility.',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Apply for Verification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addDegree() {
    setState(() {
      _degrees.add({'title': '', 'institution': '', 'year': ''});
    });
  }

  Widget _buildDegreeFields(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => _degrees[index]['title'] = val,
            decoration:
                const InputDecoration(labelText: 'Degree Title (e.g. B.Tech)'),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          TextField(
            onChanged: (val) => _degrees[index]['institution'] = val,
            decoration:
                const InputDecoration(labelText: 'Institution (e.g. Stanford)'),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white10)),
      ),
    );
  }

  Future<void> _submitApplication() async {
    final userId = ref.read(userProfileProvider).value?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    final profile = MentorProfile(
      id: '', // Will be generated by DB
      userId: userId,
      headline: _headlineController.text,
      bio: _bioController.text,
      experienceYears: int.tryParse(_expController.text) ?? 0,
      specializations: _specializationController.text
          .split(',')
          .map((s) => s.trim())
          .toList(),
      degrees: _degrees,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(mentorRepositoryProvider).registerAsMentor(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application Submitted Successfully!')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
