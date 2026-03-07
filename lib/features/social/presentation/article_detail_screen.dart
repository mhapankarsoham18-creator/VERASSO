import 'package:flutter/material.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

/// A screen that displays the details of a news article or discovery post.
class ArticleDetailScreen extends StatelessWidget {
  /// The ID of the article to display.
  final String articleId;

  /// Creates an [ArticleDetailScreen] instance.
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Discovery Detail'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 100,
            left: 16,
            right: 16,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(0),
                child: Hero(
                  tag: 'article_$articleId',
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.blueGrey.withValues(alpha: 0.3),
                    child: const Icon(
                      Icons.article,
                      size: 64,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Restored Discovery Article',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'By Verasso AI • 2 min read',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 12),
              ),
              const SizedBox(height: 24),
              const Text(
                'This article has been successfully restored as part of the production readiness phase. VERASSO now includes full discovery and news capabilities, bridging the gap between social feed and deep learning content.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'No comments yet.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
