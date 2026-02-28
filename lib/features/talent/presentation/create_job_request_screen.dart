import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../profile/presentation/profile_controller.dart';
import '../data/job_model.dart';
import '../data/job_repository.dart';
import 'talent_dashboard.dart';

/// Screen for posting a new job request.
class CreateJobRequestScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateJobRequestScreen].
  const CreateJobRequestScreen({super.key});

  @override
  ConsumerState<CreateJobRequestScreen> createState() =>
      _CreateJobRequestScreenState();
}

class _CreateJobRequestScreenState
    extends ConsumerState<CreateJobRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _skillsController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Post Job Request'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
          child: Form(
            key: _formKey,
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Job Title',
                        hintText: 'e.g. Need Logo Design',
                        labelStyle: TextStyle(color: Colors.white70)),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.white70)),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _budgetController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Budget',
                        prefixText: '\$',
                        labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skillsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Required Skills (comma separated)',
                        hintText: 'e.g. Flutter, UI Design',
                        labelStyle: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Post Job'),
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
    final myId = ref.read(userProfileProvider).value?.id;
    if (myId == null) return;

    final job = JobRequest(
      id: '',
      clientId: myId,
      title: _titleController.text,
      description: _descriptionController.text,
      budget: double.tryParse(_budgetController.text) ?? 0.0,
      requiredSkills: _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(jobRepositoryProvider).createJobRequest(job);
      if (mounted) {
        ref.invalidate(jobsProvider);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Job request posted!')));
        Navigator.pop(context);
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
