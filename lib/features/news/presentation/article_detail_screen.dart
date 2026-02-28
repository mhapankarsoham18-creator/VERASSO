import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../data/news_repository.dart';
import '../domain/news_model.dart';

/// Screen for viewing the full content of a news article, including comments and engagement.
class ArticleDetailScreen extends ConsumerStatefulWidget {
  /// The article to display (optional if [articleId] is provided).
  final NewsArticle? article;

  /// The unique ID of the article to fetch (for deep linking).
  final String? articleId;

  /// Creates an [ArticleDetailScreen].
  const ArticleDetailScreen({super.key, this.article, this.articleId})
      : assert(article != null || articleId != null);

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  late String _articleId;
  NewsArticle? _article;
  bool _isLoading = false;
  double _readProgress = 0.0;
  bool _isUpvoting = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_article == null) {
      return const Scaffold(body: Center(child: Text('Article not found')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: _readProgress,
            backgroundColor: Colors.transparent,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.share2), onPressed: () {}),
          IconButton(icon: const Icon(LucideIcons.bookmark), onPressed: () {}),
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAuthorHeader().animate().fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 24),
              Text(_article!.title,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2))
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 16),
              if (_article!.description != null)
                Text(_article!.description!,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                            fontStyle: FontStyle.italic))
                    .animate()
                    .fadeIn(delay: 200.ms),
              const Divider(color: Colors.white10, height: 48),
              MarkdownBody(
                data: _article!.content['text'] ?? '',
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                      fontSize: 16, height: 1.6, color: Colors.white),
                  h1: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  h2: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  code: TextStyle(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      fontFamily: 'monospace'),
                ),
              ).animate().fadeIn(delay: 300.ms),
              if (_article!.latexContent != null &&
                  _article!.latexContent!.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildSectionTitle('Equations').animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(_article!.latexContent!,
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.orangeAccent,
                            fontFamily: 'serif')),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              _buildEngagementBar(),
              const Divider(color: Colors.white10, height: 48),
              _buildCommentSection(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _articleId = widget.article?.id ?? widget.articleId!;
    if (_article == null) {
      _fetchArticle();
    }
    _scrollController.addListener(_onScroll);
  }

  Widget _buildAuthorHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: _article!.authorAvatar != null
              ? NetworkImage(_article!.authorAvatar!)
              : null,
          child: _article!.authorAvatar == null
              ? const Icon(LucideIcons.user)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_article!.authorName ?? 'Anonymous',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
                '${timeago.format(_article!.createdAt)} • ${_article!.readingTime} min read',
                style: const TextStyle(fontSize: 12, color: Colors.white38)),
          ],
        ),
        const Spacer(),
        if (_article!.authorBadge != null)
          _buildBadgeChip(_article!.authorBadge!),
      ],
    );
  }

  Widget _buildBadgeChip(String badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Text(badge.toUpperCase(),
          style: const TextStyle(
              fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Discussion',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                      hintText: 'Add a thought...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.white24)),
                ),
              ),
              IconButton(
                  icon:
                      const Icon(LucideIcons.send, color: Colors.orangeAccent),
                  onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementBar() {
    return Row(
      children: [
        _EngagementButton(
          icon: LucideIcons.heart,
          label: '${_article!.upvotesCount}',
          onTap: _isUpvoting ? null : _upvote,
          color: Colors.pinkAccent,
        ),
        const SizedBox(width: 24),
        _EngagementButton(
          icon: LucideIcons.messageSquare,
          label: '${_article!.commentsCount}',
          onTap: () {},
          color: Colors.blueAccent,
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

  Future<void> _fetchArticle() async {
    setState(() => _isLoading = true);
    try {
      final fetchedArticle =
          await ref.read(newsRepositoryProvider).getArticleById(_articleId);
      setState(() {
        _article = fetchedArticle;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final progress =
        _scrollController.offset / _scrollController.position.maxScrollExtent;
    setState(() => _readProgress = progress.clamp(0.0, 1.0));
  }

  Future<void> _upvote() async {
    setState(() => _isUpvoting = true);
    try {
      await ref.read(newsRepositoryProvider).upvoteArticle(_article!.id);
      // Update local state for immediate feedback
      setState(() {
        _article = _article!.copyWith(upvotesCount: _article!.upvotesCount + 1);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpvoting = false);
      }
    }
  }
}

class _EngagementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _EngagementButton(
      {required this.icon,
      required this.label,
      this.onTap,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: color.withValues(alpha: 0.8)),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
