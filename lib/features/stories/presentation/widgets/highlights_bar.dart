import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/cached_image.dart';

import '../../../../services/stories_service.dart';
import '../../models/highlight_model.dart'; // Verify path
import '../highlight_creation_screen.dart';
import 'story_viewer_widget.dart';

/// Widget that displays a horizontal list of story highlights.
class HighlightsBar extends StatefulWidget {
  /// The ID of the user whose highlights are being displayed.
  final String userId;

  /// Whether the current user is the owner of the highlights.
  final bool isOwner;

  /// Creates a [HighlightsBar].
  const HighlightsBar({super.key, required this.userId, required this.isOwner});

  @override
  State<HighlightsBar> createState() => _HighlightsBarState();
}

class _HighlightsBarState extends State<HighlightsBar> {
  final _storiesService = StoriesService();
  List<HighlightModel> _highlights = [];
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator()));
    }

    if (_highlights.isEmpty && !widget.isOwner) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _highlights.length + (widget.isOwner ? 1 : 0),
        itemBuilder: (context, index) {
          if (widget.isOwner && index == 0) {
            return _buildAddButton();
          }

          final highlight =
              widget.isOwner ? _highlights[index - 1] : _highlights[index];

          return _buildHighlightData(highlight);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: _createHighlight,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const Icon(LucideIcons.plus, size: 30),
            ),
            const SizedBox(height: 4),
            const Text('New', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightData(HighlightModel highlight) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _openHighlight(highlight),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipOval(
                child: highlight.coverUrl != null
                    ? CachedImage(
                        imageUrl: highlight.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(LucideIcons.imageOff),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child:
                            const Icon(LucideIcons.image, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                highlight.title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createHighlight() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HighlightCreationScreen()),
    );
    if (result == true) {
      _loadHighlights();
    }
  }

  Future<void> _loadHighlights() async {
    try {
      final highlights = await _storiesService.getUserHighlights(widget.userId);
      if (mounted) {
        setState(() {
          _highlights = highlights;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openHighlight(HighlightModel highlight) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Loading highlight: ${highlight.title}...'),
            duration: const Duration(seconds: 1)),
      );

      final stories = await _storiesService.getStoriesByIds(highlight.storyIds);

      if (mounted) {
        if (stories.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('This highlight has no active stories.')),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewerWidget(
              stories: stories,
              onComplete: () => Navigator.pop(context),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load highlight: $e')),
        );
      }
    }
  }
}
