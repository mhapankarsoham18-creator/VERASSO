import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/theme/app_colors.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../data/comment_model.dart';
import '../data/feed_repository.dart';
import '../data/post_model.dart';
import 'comments_controller.dart';
import 'feed_screen.dart';

/// Screen for viewing a single [Post] in full detail with its comments.
class PostDetailScreen extends ConsumerStatefulWidget {
  /// The post to display (optional if [postId] is provided).
  final Post? post;

  /// The unique ID of the post to fetch (for deep linking).
  final String? postId;

  /// Creates a [PostDetailScreen] instance.
  const PostDetailScreen({super.key, this.post, this.postId})
      : assert(post != null || postId != null);

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.authorAvatar != null
                ? NetworkImage(comment.authorAvatar!)
                : null,
            child: comment.authorAvatar == null
                ? const Icon(LucideIcons.user, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName ?? 'User',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMd().format(comment.createdAt),
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  late String _postId;
  Post? _post;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_post == null) {
      return const Scaffold(body: Center(child: Text('Post not found')));
    }
    final post = _post!;
    final commentsAsync = ref.watch(commentsProvider(post.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LiquidBackground(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                      child: SizedBox(height: kToolbarHeight + 20)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: PostCard(post: post),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Comments',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  commentsAsync.when(
                    data: (comments) => SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _CommentTile(comment: comments[index]),
                        childCount: comments.length,
                      ),
                    ),
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => SliverFillRemaining(
                      child:
                          Center(child: Text('Error loading comments: $err')),
                    ),
                  ),
                ],
              ),
            ),
            // Comment Input
            GlassContainer(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a thought...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: null,
                      ),
                    ),
                    IconButton(
                      onPressed: _submitComment,
                      icon:
                          const Icon(LucideIcons.send, color: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _postId = widget.post?.id ?? widget.postId!;
    if (_post == null) {
      _fetchPost();
    }
  }

  Future<void> _fetchPost() async {
    setState(() => _isLoading = true);
    try {
      final fetchedPost =
          await ref.read(feedRepositoryProvider).getPostById(_postId);
      setState(() {
        _post = fetchedPost;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    ref.read(commentsProvider(_post!.id).notifier).addComment(content);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }
}
