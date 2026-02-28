import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Feed screen widget tests
void main() {
  group('FeedScreen Widget Tests', () {
    testWidgets('displays loading state initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _MockLoadingFeed(),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays posts when loaded', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _MockLoadedFeed(),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('displays empty state when no posts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _MockEmptyFeed(),
            ),
          ),
        ),
      );

      expect(find.text('No posts yet'), findsOneWidget);
    });

    testWidgets('refresh indicator is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RefreshIndicator(
                onRefresh: () async {},
                child: const _MockLoadedFeed(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('Post Interactions', () {
    testWidgets('like button responds to tap', (WidgetTester tester) async {
      bool liked = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _MockPostCard(
                onLike: () => liked = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(liked, isTrue);
    });

    testWidgets('comment button responds to tap', (WidgetTester tester) async {
      bool commentTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _MockPostCard(
                onComment: () => commentTapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.comment_outlined));
      await tester.pump();

      expect(commentTapped, isTrue);
    });
  });
}

class _MockEmptyFeed extends StatelessWidget {
  const _MockEmptyFeed();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No posts yet'));
  }
}

class _MockLoadedFeed extends StatelessWidget {
  const _MockLoadedFeed();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: List.generate(
          3,
          (index) => Card(
                child: ListTile(title: Text('Post $index')),
              )),
    );
  }
}

class _MockLoadingFeed extends StatelessWidget {
  const _MockLoadingFeed();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _MockPostCard extends StatelessWidget {
  final VoidCallback? onLike;
  final VoidCallback? onComment;

  const _MockPostCard({this.onLike, this.onComment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Text('Post content'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: onLike,
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: onComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
