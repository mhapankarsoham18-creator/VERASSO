import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../../profile/presentation/profile_controller.dart';
import '../data/talent_model.dart';
import '../data/talent_repository.dart';
import 'talent_dashboard.dart';

/// Form screen for publishing a new [TalentPost] to the marketplace.
///
/// Allows the user to describe their offering, choose a category, billing
/// period, and enquiry details, and then persists the post via
/// [TalentRepository].
class CreateTalentScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateTalentScreen].
  const CreateTalentScreen({super.key});

  @override
  ConsumerState<CreateTalentScreen> createState() => _CreateTalentScreenState();
}

class _CreateTalentScreenState extends ConsumerState<CreateTalentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _enquiryController = TextEditingController();
  String _category = 'Art';
  bool _isLoading = false;

  final List<String> _categories = [
    'Art',
    'Music',
    'Coding',
    'Design',
    'Writing',
    'Other'
  ];
  String _billingPeriod = 'one-off';
  bool _isMentorPackage = false;
  final List<String> _billingPeriods = [
    'one-off',
    'hourly',
    'monthly',
    'quarterly',
    'yearly',
    'free'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Showcase Talent'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'Title (e.g. Portrait Illustration)',
                            labelStyle: TextStyle(color: Colors.white70)),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Price',
                                  prefixText: '\$',
                                  labelStyle: TextStyle(color: Colors.white70)),
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              dropdownColor: Colors.grey[900],
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  labelText: 'Category',
                                  labelStyle: TextStyle(color: Colors.white70)),
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                      value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _billingPeriod,
                              dropdownColor: Colors.grey[900],
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  labelText: 'Billing Period',
                                  labelStyle: TextStyle(color: Colors.white70)),
                              items: _billingPeriods
                                  .map((p) => DropdownMenuItem(
                                      value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _billingPeriod = v!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _isMentorPackage,
                                activeColor: Colors.blueAccent,
                                onChanged: (val) =>
                                    setState(() => _isMentorPackage = val!),
                              ),
                              const Text('Mentor Pkg',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _enquiryController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Enquiry Details',
                          hintText: 'e.g. DM me on Instagram @user or email me',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintStyle:
                              TextStyle(fontSize: 12, color: Colors.white38),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
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
                              : const Text('Post to Showcase'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Validates the form and posts a new [TalentPost] through the repository.
  ///
  /// On success, invalidates the [talentsProvider] cache and navigates back
  /// to the [TalentDashboard] with a confirmation snackbar.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final myId = ref.read(userProfileProvider).value?.id;
    if (myId == null) return;

    final talent = TalentPost(
      id: '', // Generated by Supabase
      userId: myId,
      title: _titleController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      currency: 'USD',
      enquiryDetails: _enquiryController.text,
      category: _category,
      createdAt: DateTime.now(),
      billingPeriod: _billingPeriod,
      isMentorPackage: _isMentorPackage,
    );

    try {
      await ref.read(talentRepositoryProvider).createTalent(talent);
      if (mounted) {
        ref.invalidate(talentsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Talent posted successfully!')));
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
