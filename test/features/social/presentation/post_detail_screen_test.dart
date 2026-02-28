import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/security/moderation_service.dart';
// import 'package:verasso/core/security/moderation_service.dart';
import 'package:verasso/features/auth/presentation/auth_controller.dart';
import 'package:verasso/features/settings/presentation/theme_controller.dart';
import 'package:verasso/features/social/data/comment_model.dart';
import 'package:verasso/features/social/data/comment_repository.dart';
import 'package:verasso/features/social/data/feed_repository.dart';
import 'package:verasso/features/social/data/post_model.dart';
import 'package:verasso/features/social/data/saved_post_repository.dart';
import 'package:verasso/features/social/presentation/comments_controller.dart';
import 'package:verasso/features/social/presentation/feed_controller.dart';
import 'package:verasso/features/social/presentation/post_detail_screen.dart';
import 'package:verasso/features/social/presentation/saved_posts_controller.dart';
import 'package:verasso/l10n/app_localizations.dart';

import '../../../mocks.dart';

void main() {
  late MockFeedRepository mockFeedRepo;
  late MockCommentRepository mockCommentRepo;
  late MockSavedPostRepository mockSavedPostRepo;
  late MockModerationService mockModeration;

  final testPost = Post(
    id: 'post-1',
    userId: 'user-1',
    content: 'Detail View Content',
    createdAt: DateTime.now(),
    authorName: 'Detail Author',
    likesCount: 42,
    commentsCount: 2,
  );

  final testComments = [
    Comment(
      id: 'c1',
      postId: 'post-1',
      userId: 'u2',
      content: 'Interesting point!',
      createdAt: DateTime.now(),
      authorName: 'User Two',
    ),
    Comment(
      id: 'c2',
      postId: 'post-1',
      userId: 'u3',
      content: 'I disagree.',
      createdAt: DateTime.now(),
      authorName: 'User Three',
    ),
  ];

  setUp(() {
    mockFeedRepo = MockFeedRepository();
    mockCommentRepo = MockCommentRepository();
    mockSavedPostRepo = MockSavedPostRepository();
    mockModeration = MockModerationService();

    // Default stubs
    mockCommentRepo.getCommentsStub = (id) async => testComments;
    mockCommentRepo.subscribeToCommentsStub =
        (id, callback) => MockRealtimeChannel();
    mockSavedPostRepo.isSavedStub = (id) async => false;
    mockSavedPostRepo.watchCollectionsStub = () => Stream.value([]);
    mockModeration.getMutedUserIdsStub = (id) async => [];
  });

  Widget createPostDetailScreen({Post? post, String? postId}) {
    final themeController = MockThemeController();
    themeController.state =
        themeController.state.copyWith(isPowerSaveMode: true);

    return ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(mockFeedRepo),
        commentRepositoryProvider.overrideWithValue(mockCommentRepo),
        savedPostRepositoryProvider.overrideWithValue(mockSavedPostRepo),
        moderationServiceProvider.overrideWithValue(mockModeration),
        themeControllerProvider.overrideWith((ref) => themeController),
        // Override the family provider for comments
        commentsProvider(testPost.id).overrideWith(
            (ref) => CommentsNotifier(mockCommentRepo, testPost.id)),
        // PostCard dependencies
        isPostSavedProvider(testPost.id).overrideWith((ref) => false),
        collectionsProvider.overrideWith((ref) => Stream.value([])),
        feedProvider.overrideWith((ref) => FeedNotifier(mockFeedRepo, ref)),
        savedPostsControllerProvider.overrideWith(
            (ref) => SavedPostsController(mockSavedPostRepo, ref)),
        currentUserProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PostDetailScreen(post: post, postId: postId),
      ),
    );
  }

  group('PostDetailScreen Widget Tests', () {
    testWidgets('renders post details and comments', (tester) async {
      await tester.pumpWidget(createPostDetailScreen(post: testPost));
      // Pump to let async comments load
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Detail View Content'), findsOneWidget);
      expect(find.text('Detail Author'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Interesting point!'), findsOneWidget);
      expect(find.text('I disagree.'), findsOneWidget);
      await tester.pumpWidget(Container());
    });

    testWidgets('shows loading state for comments', (tester) async {
      final completer = Completer<List<Comment>>();
      mockCommentRepo.getCommentsStub = (id) => completer.future;

      await tester.pumpWidget(createPostDetailScreen(post: testPost));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Complete the future to avoid pending timers/disposed state issues
      completer.complete([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(Container());
    });

    testWidgets('submits a new comment', (tester) async {
      await tester.pumpWidget(createPostDetailScreen(post: testPost));
      await tester.pump();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'New test comment');
      await tester.pump();

      final sendButton = find.byIcon(LucideIcons.send);
      await tester.tap(sendButton);
      await tester.pump();

      expect(
          mockCommentRepo.addCommentCalls.contains('New test comment'), isTrue);

      // TextField should be cleared
      expect(find.text('New test comment'), findsNothing);

      await tester.pumpWidget(Container());
    });
  });
}
