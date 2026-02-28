import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/learning/presentation/classroom/doubt_controller.dart';

/// A screen that allows students to post doubts or questions to the community.
class AskDoubtScreen extends ConsumerStatefulWidget {
  /// Creates an [AskDoubtScreen] instance.
  const AskDoubtScreen({super.key});

  @override
  ConsumerState<AskDoubtScreen> createState() => _AskDoubtScreenState();
}

class _AskDoubtScreenState extends ConsumerState<AskDoubtScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedImage;
  String _selectedSubject = 'Physics';
  final List<String> _subjects = [
    'Physics',
    'Chemistry',
    'Biology',
    'Math',
    'General'
  ]; // Could query from DB too

  @override
  Widget build(BuildContext context) {
    final doubtState = ref.watch(doubtControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ask a Doubt')),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubject,
                      dropdownColor: Colors.grey[900], // or a glass style
                      decoration: const InputDecoration(
                          labelText: 'Subject',
                          labelStyle: TextStyle(color: Colors.white)),
                      style: const TextStyle(color: Colors.white),
                      items: _subjects
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSubject = val ?? 'General'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Question Title',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Image Picker
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            _selectedImage = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedImage!,
                                    fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.image,
                                      color: Colors.white54, size: 32),
                                  SizedBox(height: 8),
                                  Text('Add Image (Optional)',
                                      style: TextStyle(color: Colors.white54)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: doubtState.isLoading
                            ? null
                            : () {
                                if (_titleController.text.isNotEmpty) {
                                  ref
                                      .read(doubtControllerProvider.notifier)
                                      .askDoubt(
                                        title: _titleController.text,
                                        description: _descController.text,
                                        subject: _selectedSubject,
                                        image: _selectedImage,
                                      );
                                  Navigator.pop(context);
                                }
                              },
                        child: doubtState.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Post Question',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
