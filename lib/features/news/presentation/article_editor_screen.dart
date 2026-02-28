import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../data/news_repository.dart';
import '../domain/news_model.dart';

/// Screen for creating and publishing new news articles with rich text and LaTeX support.
class ArticleEditorScreen extends ConsumerStatefulWidget {
  /// Creates an [ArticleEditorScreen].
  const ArticleEditorScreen({super.key});

  @override
  ConsumerState<ArticleEditorScreen> createState() =>
      _ArticleEditorScreenState();
}

class _ArticleEditorScreenState extends ConsumerState<ArticleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _contentController = TextEditingController();
  final _latexController = TextEditingController();

  String _selectedSubject = 'Physics';
  String _selectedAudience = 'NEET Aspirants';
  final String _selectedType = 'concept_explainer';
  bool _isPublishing = false;

  final List<String> _subjects = [
    'Physics',
    'Chemistry',
    'Biology',
    'Pharmacy',
    'Engineering',
    'Commerce'
  ];
  final List<String> _audiences = [
    'NEET Aspirants',
    'JEE Aspirants',
    'B.Pharm Students',
    'Engineering Students',
    'Global Learners'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('New Article'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isPublishing ? null : _publish,
            icon: _isPublishing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.send),
            label: const Text('Publish'),
            style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
          ),
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Academic Metadata'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                          'Subject',
                          _selectedSubject,
                          _subjects,
                          (val) => setState(() => _selectedSubject = val!)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                          'Audience',
                          _selectedAudience,
                          _audiences,
                          (val) => setState(() => _selectedAudience = val!)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Article Content'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('Article Title'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        validator: (v) => v!.isEmpty ? 'Title required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descController,
                        decoration:
                            _inputDecoration('Brief Description (Abstract)'),
                        maxLines: 2,
                      ),
                      const Divider(color: Colors.white10, height: 32),
                      TextFormField(
                        controller: _contentController,
                        decoration: _inputDecoration(
                            'Main Content (Markdown supported)'),
                        maxLines: 15,
                        validator: (v) => v!.length < 100
                            ? 'Minimum 100 characters required'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('LaTeX Equations (Optional)'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _latexController,
                    decoration: _inputDecoration('e.g. E = mc^2'),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: Colors.grey[900],
              icon: const Icon(LucideIcons.chevronDown, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title.toUpperCase(),
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white38,
            letterSpacing: 1.2));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    try {
      final repo = ref.read(newsRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) throw 'User not authenticated';

      final article = NewsArticle(
        id: const Uuid().v4(),
        authorId: userId,
        title: _titleController.text,
        description: _descController.text,
        content: {'text': _contentController.text}, // Simple wrapper for now
        latexContent: _latexController.text,
        subject: _selectedSubject,
        audienceType: _selectedAudience,
        articleType: _selectedType,
        readingTime:
            (_contentController.text.length / 500).ceil(), // Rough estimate
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.publishArticle(article);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error publishing: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }
}
