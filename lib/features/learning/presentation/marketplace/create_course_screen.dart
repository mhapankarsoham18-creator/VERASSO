import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';

import '../../data/course_models.dart';
import '../../data/course_repository.dart';

/// A screen that allows instructors to create and publish new courses.
class CreateCourseScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateCourseScreen] instance.
  const CreateCourseScreen({super.key});

  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  final List<Chapter> _chapters = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          title: const Text('Create Course'),
          backgroundColor: Colors.transparent),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'Course Title',
                            labelStyle: TextStyle(color: Colors.white70)),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Price (USD)',
                            labelStyle: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Syllabus / Chapters',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(LucideIcons.plusCircle,
                          color: Colors.blueAccent),
                      onPressed: _addChapter,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._chapters.asMap().entries.map((entry) {
                  final idx = entry.key;
                  return GlassContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white10,
                            child: Text('${idx + 1}',
                                style: const TextStyle(fontSize: 10))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: _chapters[idx].title,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Chapter Title'),
                            onChanged: (v) {
                              _chapters[idx] = Chapter(
                                  id: '',
                                  courseId: '',
                                  title: v,
                                  orderIndex: idx,
                                  createdAt: DateTime.now());
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2,
                              size: 16, color: Colors.redAccent),
                          onPressed: () =>
                              setState(() => _chapters.removeAt(idx)),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Publish Course'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addChapter() {
    setState(() {
      _chapters.add(Chapter(
        id: '',
        courseId: '',
        title: 'New Chapter',
        orderIndex: _chapters.length,
        createdAt: DateTime.now(),
      ));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one chapter')));
      return;
    }

    setState(() => _isLoading = true);
    final creatorId = ref.read(currentUserProvider)?.id;
    if (creatorId == null) return;

    final repo = ref.read(courseRepositoryProvider);

    try {
      final course = Course(
        id: '',
        creatorId: creatorId,
        title: _titleController.text,
        description: _descController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        createdAt: DateTime.now(),
      );

      final courseId = await repo.createCourse(course);

      for (var chapter in _chapters) {
        await repo.addChapter(
          courseId: courseId,
          title: chapter.title,
          content: 'Learning content for ${chapter.title}',
          order: chapter.orderIndex,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Course Published!')));
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
