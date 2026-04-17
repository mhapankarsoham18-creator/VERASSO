import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:verasso/core/theme/verasso_loading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import '../../../core/validators/input_validator.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;

  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final data = await Supabase.instance.client
          .from('comments')
          .select('''
            id,
            content,
            created_at,
            author_id,
            profiles (
              display_name,
              username,
              avatar_url
            )
          ''')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      debugPrint('Error fetching comments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _postComment() async {
    final rawComment = _commentController.text.trim();
    if (rawComment.isEmpty) return;

    final validationError = InputValidator.validateComment(rawComment);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    final sanitizedComment = InputValidator.sanitize(rawComment);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please log in to comment.')));
      return;
    }

    try {
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('firebase_uid', user.uid)
          .maybeSingle();

      if (profileRes == null) throw 'Profile not found';

      await Supabase.instance.client.from('comments').insert({
        'post_id': widget.postId,
        'author_id': profileRes['id'],
        'content': sanitizedComment,
      });

      _commentController.clear();
      _fetchComments(); // Refresh comment list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.neutralBg,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                height: 4, width: 40,
                decoration: BoxDecoration(color: context.colors.shadowDark, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("COMMENTS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: context.colors.textPrimary)),
              ),
              Divider(color: context.colors.blockEdge, thickness: 2),

              // Comments List
              Expanded(
                child: _isLoading
                    ? Center(child: VerassoLoading())
                    : _comments.isEmpty
                        ? Center(child: Text("No comments yet. Be the first!", style: TextStyle(color: context.colors.textSecondary)))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _comments.length,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              final profile = comment['profiles'] ?? {};
                              final name = profile['display_name'] ?? profile['username'] ?? 'Explorer';
                              final avatarUrl = profile['avatar_url'];

                              return Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16, backgroundColor: context.colors.blockEdge,
                                      backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                                      child: avatarUrl == null ? Icon(Icons.person, size: 16, color: context.colors.neutralBg) : null,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: NeoPixelBox(
                                        padding: 12,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name.toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.colors.primary)),
                                            SizedBox(height: 4),
                                            Text(comment['content'] ?? '', style: TextStyle(color: context.colors.textPrimary, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Input Area
              Container(
                padding: EdgeInsets.only(
                  left: 16, right: 16, top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: context.colors.neutralBg,
                  border: Border(top: BorderSide(color: context.colors.blockEdge, width: 2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Transmit your thoughts...',
                          hintStyle: TextStyle(color: context.colors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.colors.blockEdge, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.colors.blockEdge, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.colors.primary, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    NeoPixelBox(
                      padding: 12,
                      isButton: true,
                      onTap: _postComment,
                      child: Icon(Icons.send, color: context.colors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
