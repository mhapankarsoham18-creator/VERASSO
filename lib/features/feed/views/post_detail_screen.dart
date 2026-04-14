import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';

/// Full-screen post detail view
class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Map<String, dynamic>? _author;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadAuthor();
    _checkSavedStatus();
  }

  Future<void> _loadAuthor() async {
    final authorId = widget.post['author_id'];
    if (authorId != null) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', authorId)
          .maybeSingle();
      if (mounted) setState(() => _author = profile);
    }
  }

  Future<void> _checkSavedStatus() async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;
    
    // Check if there's a row in post_saves
    try {
      final res = await Supabase.instance.client
        .from('post_saves')
        .select()
        .eq('user_id', myId)
        .eq('post_id', widget.post['id'])
        .maybeSingle();
      if (mounted && res != null) {
         setState(() => _isSaved = true);
      }
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
     final myId = Supabase.instance.client.auth.currentUser?.id;
     if (myId == null) return;
     
     setState(() => _isSaved = !_isSaved);
     try {
       if (_isSaved) {
         await Supabase.instance.client.from('post_saves').insert({
           'user_id': myId,
           'post_id': widget.post['id']
         });
       } else {
         await Supabase.instance.client.from('post_saves')
           .delete()
           .eq('user_id', myId)
           .eq('post_id', widget.post['id']);
       }
     } catch (e) {
       // Revert on error
       if (mounted) setState(() => _isSaved = !_isSaved);
     }
  }

  void _openComments() {
    // Show a bottom sheet for comments
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.neutralBg,
      isScrollControlled: true,
      builder: (context) {
         return DraggableScrollableSheet(
           expand: false,
           initialChildSize: 0.8,
           builder: (context, scrollController) {
             return Column(
               children: [
                 const Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Text("COMMENTS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                 ),
                 Expanded(
                   child: Center(
                     child: Text("Comments logic coming soon in GamificationService Phase", style: TextStyle(color: AppColors.textSecondary)),
                   ),
                 ),
               ],
             );
           }
         );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.post['content'] ?? '';
    final type = widget.post['type'] ?? 'text';
    final mediaUrl = widget.post['media_url'];
    final likes = widget.post['likes'] ?? 0;
    final createdAt = widget.post['created_at'] ?? '';
    final authorName = _author?['display_name'] ?? _author?['username'] ?? 'Unknown';
    final avatarUrl = _author?['avatar_url'];
    final hasMath = widget.post['has_math'] == true;

    return Scaffold(
      backgroundColor: AppColors.neutralBg,
      appBar: AppBar(
        title: const Text('POST', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            NeoPixelBox(
              padding: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22, backgroundColor: AppColors.accent,
                    backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                    child: avatarUrl == null ? const Icon(Icons.person, size: 22, color: AppColors.neutralBg) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(authorName.toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_formatTime(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type == 'audio' ? Icons.mic : type == 'video' ? Icons.videocam : type == 'image' ? Icons.image : Icons.text_fields,
                          size: 14, color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(type.toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accent)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Media
            if (mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.blockEdge, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: type == 'image'
                      ? CachedNetworkImage(
                          imageUrl: mediaUrl, 
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(type == 'audio' ? Icons.graphic_eq : Icons.play_circle_filled, size: 64, color: AppColors.primary),
                              const SizedBox(height: 8),
                              Text('${type.toString().toUpperCase()} FILE', style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                ),
              ),

            if (mediaUrl != null) const SizedBox(height: 20),

            // Content text
            if (content.toString().isNotEmpty)
              NeoPixelBox(
                padding: 20,
                child: hasMath 
                  ? Math.tex(
                      content, 
                      textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 16)
                    )
                  : Text(content, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.5)),
              ),

            const SizedBox(height: 20),

            // Interaction Bar (Likes, Comments, Saves)
            NeoPixelBox(
              padding: 14,
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('$likes Volts', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
                  
                  const Spacer(),
                  
                  // Comments Button
                  GestureDetector(
                    onTap: _openComments,
                    child: const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: AppColors.textSecondary, size: 20),
                        SizedBox(width: 6),
                        Text('Discuss', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Save Button
                  GestureDetector(
                    onTap: _toggleSave,
                    child: Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border, 
                      color: _isSaved ? AppColors.primary : AppColors.textSecondary, 
                      size: 20
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
