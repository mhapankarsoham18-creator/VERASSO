import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../auth/presentation/auth_controller.dart';
import '../../data/challenge_repository.dart';

/// A screen for creating and launching new community learning challenges.
class CreateChallengeScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateChallengeScreen] instance.
  const CreateChallengeScreen({super.key});

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _category = 'Coding';
  String _difficulty = 'Medium';
  int _karma = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Create Challenge'),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: LiquidBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Challenge Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildTextField(
                      'Title', 'e.g. Design a Splash Screen', _titleController),
                  const SizedBox(height: 16),
                  _buildTextField('Description',
                      'Provide clear instructions...', _descController,
                      maxLines: 3),
                  const SizedBox(height: 16),
                  _buildDropdown(
                      'Category',
                      ['Coding', 'Design', 'Math', 'Physics', 'Writing'],
                      _category,
                      (v) => setState(() => _category = v!)),
                  const SizedBox(height: 16),
                  _buildDropdown(
                      'Difficulty',
                      ['Easy', 'Medium', 'Hard', 'Expert'],
                      _difficulty,
                      (v) => setState(() => _difficulty = v!)),
                  const SizedBox(height: 24),
                  const Text('Karma Reward',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _karma.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    label: '$_karma Karma',
                    activeColor: Colors.purpleAccent,
                    onChanged: (v) => setState(() => _karma = v.toInt()),
                  ),
                  Center(
                      child: Text('$_karma Karma Points',
                          style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(LucideIcons.swords),
                      label: const Text('Launch Challenge'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String current,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    await ref.read(challengeRepositoryProvider).createChallenge(
          creatorId: userId,
          title: _titleController.text,
          description: _descController.text,
          category: _category,
          difficulty: _difficulty,
          karmaReward: _karma,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Challenge Created! 🚀')));
    }
  }
}
