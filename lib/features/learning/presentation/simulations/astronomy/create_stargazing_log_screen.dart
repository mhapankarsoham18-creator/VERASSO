import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../../../../features/auth/presentation/auth_controller.dart';
import '../../../data/astronomy_repository.dart';

/// A screen for creating a new stargazing observation log.
///
/// This implementation is kept in the simulations namespace for routing convenience.
/// Consider refactoring to a shared widget if the UX diverges in future.
class CreateStargazingLogScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateStargazingLogScreen] instance.
  const CreateStargazingLogScreen({super.key});

  @override
  ConsumerState<CreateStargazingLogScreen> createState() =>
      _CreateStargazingLogScreenState();
}

class _CreateStargazingLogScreenState
    extends ConsumerState<CreateStargazingLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _objectController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  String _equipment = 'Naked Eye';
  int _rating = 3;
  bool _isLoading = false;

  final List<String> _equipmentOptions = [
    'Naked Eye',
    'Binoculars',
    'Telescope',
    'Camera'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Log Observation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Celestial Target',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _objectController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Moon, Jupiter, Saturn',
                            hintStyle: TextStyle(color: Colors.white24),
                            border: InputBorder.none,
                            prefixIcon: Icon(LucideIcons.scanLine,
                                color: Colors.white54),
                          ),
                          validator: (v) =>
                              v?.isEmpty == true ? 'Required' : null,
                        ),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 16),
                        const Text('Equipment Used',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Wrap(
                          spacing: 8,
                          children: _equipmentOptions
                              .map((e) => ChoiceChip(
                                    label: Text(e),
                                    selected: _equipment == e,
                                    onSelected: (v) =>
                                        setState(() => _equipment = e),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.05),
                                    selectedColor: Colors.purpleAccent
                                        .withValues(alpha: 0.3),
                                    labelStyle: TextStyle(
                                        color: _equipment == e
                                            ? Colors.purpleAccent
                                            : Colors.white70),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text('Seeing Conditions (1-5)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Slider(
                          value: _rating.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: '$_rating/5',
                          activeColor: Colors.purpleAccent,
                          onChanged: (v) => setState(() => _rating = v.toInt()),
                        ),
                        const SizedBox(height: 16),
                        const Text('Notes',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText:
                                'Describe details, colors, or feelings...',
                            hintStyle: TextStyle(color: Colors.white24),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox.shrink()
                          : const Icon(LucideIcons.rocket),
                      label:
                          Text(_isLoading ? 'Logging...' : 'Log Observation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white,
                      ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId == null) throw Exception('User not logged in');

      await ref.read(astronomyRepositoryProvider).createLog(
            userId: userId,
            celestialObject: _objectController.text,
            equipmentType: _equipment,
            locationName: _locationController.text,
            skyRating: _rating,
            notes: _notesController.text,
          );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log created successfully! 🌌')));
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
