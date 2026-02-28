import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';

import '../../learning/data/course_models.dart';
import '../../learning/data/course_repository.dart';
import '../../profile/data/profile_model.dart';
import '../../profile/data/profile_repository.dart';
import '../../talent/data/talent_profile_model.dart';
import '../../talent/data/talent_profile_repository.dart';
import '../data/community_model.dart';
import '../data/community_repository.dart';
import '../data/feed_repository.dart';
import '../data/post_model.dart';

/// Provider for the [SearchController].
final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController(
    ref.watch(profileRepositoryProvider),
    ref.watch(feedRepositoryProvider),
    ref.watch(courseRepositoryProvider),
    ref.watch(talentProfileRepositoryProvider),
    ref.watch(communityRepositoryProvider),
  );
});

/// Controller for managing global search across users, posts, courses, and communities.
class SearchController extends StateNotifier<SearchState> {
  final ProfileRepository _userRepo;
  final FeedRepository _feedRepo;
  final CourseRepository _courseRepo;
  final TalentProfileRepository _talentRepo;
  final CommunityRepository _communityRepo;
  Timer? _debounce;

  /// Creates a [SearchController] instance.
  SearchController(this._userRepo, this._feedRepo, this._courseRepo,
      this._talentRepo, this._communityRepo)
      : super(SearchState());

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Initiates a debounced search across all categories.
  Future<void> search(String query) async {
    _debounce?.cancel();
    if (query.isEmpty) {
      state = SearchState();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      state = state.copyWith(isLoading: true);

      try {
        final results = await Future.wait([
          _userRepo.searchUsers(query),
          _feedRepo.searchPosts(query),
          _courseRepo.searchCourses(query),
          _talentRepo.searchMentors(query),
          _communityRepo.searchCommunities(query),
        ]);

        state = SearchState(
          userResults: results[0] as List<Profile>,
          postResults: results[1] as List<Post>,
          courseResults: results[2] as List<Course>,
          mentorResults: results[3] as List<TalentProfile>,
          communityResults: results[4] as List<Community>,
          isLoading: false,
        );
      } catch (e) {
        state = SearchState(isLoading: false);
      }
    });
  }
}

/// Represents the results of a global search.
class SearchState {
  /// Matching user profiles.
  final List<Profile> userResults;

  /// Matching social posts.
  final List<Post> postResults;

  /// Matching learning courses.
  final List<Course> courseResults;

  /// Matching mentors/talents.
  final List<TalentProfile> mentorResults;

  /// Matching learning communities.
  final List<Community> communityResults;

  /// Whether a search operation is currently in progress.
  final bool isLoading;

  /// Creates a [SearchState] instance.
  SearchState(
      {this.userResults = const [],
      this.postResults = const [],
      this.courseResults = const [],
      this.mentorResults = const [],
      this.communityResults = const [],
      this.isLoading = false});

  /// Creates a copy of this state with the given fields replaced.
  SearchState copyWith({
    List<Profile>? userResults,
    List<Post>? postResults,
    List<Course>? courseResults,
    List<TalentProfile>? mentorResults,
    List<Community>? communityResults,
    bool? isLoading,
  }) {
    return SearchState(
      userResults: userResults ?? this.userResults,
      postResults: postResults ?? this.postResults,
      courseResults: courseResults ?? this.courseResults,
      mentorResults: mentorResults ?? this.mentorResults,
      communityResults: communityResults ?? this.communityResults,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
