import 'package:cached_network_image/cached_network_image.dart' as cni;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/services/stories_service.dart';

/// A screen for creating story highlights from archived stories.
class HighlightCreationScreen extends StatefulWidget {
  /// Creates a [HighlightCreationScreen].
  const HighlightCreationScreen({super.key});

  @override
  State<HighlightCreationScreen> createState() =>
      _HighlightCreationScreenState();
}

class _HighlightCreationScreenState extends State<HighlightCreationScreen> {
  final _storiesService = StoriesService();
  final _titleController = TextEditingController();
  List<StoryModel> _archivedStories = [];
  final Set<String> _selectedStoryIds = {};
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Highlight'),
        actions: [
          if (_isCreating)
            const Center(
                child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ))
          else
            TextButton(
              onPressed: _createHighlight,
              child: const Text('Create',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Highlight Name',
                border: OutlineInputBorder(),
                hintText: 'e.g. Vacation, Projects',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Stories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _archivedStories.isEmpty
                    ? const Center(child: Text('No stories found'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(4),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 9 / 16,
                        ),
                        itemCount: _archivedStories.length,
                        itemBuilder: (context, index) {
                          final story = _archivedStories[index];
                          final isSelected =
                              _selectedStoryIds.contains(story.id);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedStoryIds.remove(story.id);
                                } else {
                                  _selectedStoryIds.add(story.id);
                                }
                              });
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                cni.CachedNetworkImage(
                                  imageUrl: story.mediaUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey[300]),
                                  errorWidget: (context, url, error) =>
                                      const Icon(LucideIcons.alertCircle),
                                ),
                                if (story.mediaType == 'video')
                                  const Center(
                                      child: Icon(LucideIcons.playCircle,
                                          color: Colors.white)),
                                Container(
                                  color: isSelected
                                      ? Colors.black45
                                      : Colors.transparent,
                                ),
                                if (isSelected)
                                  const Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Icon(LucideIcons.checkCircle,
                                        color: Colors.blue, size: 24),
                                  )
                                else
                                  const Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Icon(LucideIcons.circle,
                                        color: Colors.white, size: 24),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _createHighlight() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    if (_selectedStoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one story')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await _storiesService.createHighlight(
        title: title,
        storyIds: _selectedStoryIds.toList(),
      );
      if (mounted) {
        Navigator.pop(context, true); // Success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating highlight: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _loadStories() async {
    try {
      final stories = await _storiesService.getArchivedStories();
      if (mounted) {
        setState(() {
          _archivedStories = stories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stories: $e')),
        );
      }
    }
  }
}
