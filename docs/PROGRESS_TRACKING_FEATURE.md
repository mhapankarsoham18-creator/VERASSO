# Progress Tracking Feature Documentation

## Overview

The Progress Tracking system gamifies user engagement in VERASSO by providing:
- **XP and Level System**: 7 levels from Novice (Level 1) to Grandmaster (Level 7)
- **Achievement Badges**: Unlockable achievements with rarity tiers
- **Milestone Tracking**: Goal-based progression with point rewards
- **Leaderboard**: Real-time ranking of top users by total points
- **Activity Logging**: Complete history of user activities with point awards
- **Login Streaks**: Consecutive day tracking with bonus multipliers

## Architecture

### Database Schema

#### Core Tables

**user_progress** (Main user progress tracking)
- `id`: UUID primary key
- `user_id`: Reference to auth.users
- `total_points`: Sum of all earned points (INT)
- `current_level`: Current level (1-7, INT)
- `current_xp`: XP progress toward next level (INT)
- `xp_to_next_level`: XP required for next level (INT)
- `total_posts`: Lifetime post count
- `total_comments`: Lifetime comment count
- `total_likes_received`: Lifetime likes received
- `total_followers_gained`: Lifetime follower gains
- `total_shares`: Lifetime post shares
- `login_streak`: Current consecutive login days
- `last_login`: Last login timestamp
- `posts_this_month`: Posts created in current month
- `comments_this_month`: Comments in current month
- `joined_date`: User account creation date
- `profile_completeness`: Profile completion percentage (0-100)
- `engagement_score`: Calculated engagement metric (0-10)
- `total_achievements_unlocked`: Count of unlocked achievements
- `current_milestone_count`: Number of active milestones

**progress_milestones** (Goal tracking)
- `id`: UUID primary key
- `user_id`: User reference
- `title`: Milestone name
- `description`: Milestone description
- `target_value`: Goal target value
- `current_value`: Current progress value
- `progress_percentage`: Calculated percentage (0-100)
- `is_completed`: Completion status
- `reward_points`: Points awarded on completion
- `completed_at`: Completion timestamp

**user_achievements** (Achievement unlocks)
- `id`: UUID primary key
- `user_id`: User reference
- `achievement_id`: Achievement reference
- `unlocked_at`: Unlock timestamp
- `points_awarded`: Points for unlock

**progress_activity_log** (Activity history)
- `id`: UUID primary key
- `user_id`: User reference
- `activity_type`: Type of activity (post_created, comment_posted, etc.)
- `points_awarded`: Points for this activity
- `created_at`: Activity timestamp

**progress_levels** (Level definitions)
- `id`: INT primary key (1-7)
- `title`: Level name (Novice, Apprentice, etc.)
- `min_xp`: Minimum XP for this level
- `max_xp`: Maximum XP for this level
- `icon_url`: Level icon
- `description`: Level description

### Database Functions

**calculate_activity_xp(activity_type VARCHAR)**
- Determines base XP for activity type
- Returns: INT (XP points)
- Activity types: post_created (50), comment_posted (10), post_liked (5), etc.

**get_user_level(total_xp INT)**
- Calculates level based on total XP
- Returns: INT (level 1-7)
- Uses cumulative XP thresholds

**calculate_progress_percentage(current INT, target INT)**
- Calculates percentage progress
- Returns: INT (0-100)
- Clamps to 100% maximum

**update_user_level(user_id UUID)**
- Updates user level based on total XP
- Triggers on user_progress INSERT/UPDATE
- Handles XP reset when leveling up

**log_activity_and_award_points(user_id UUID, activity_type VARCHAR)**
- Records activity in activity_log
- Awards XP to user
- Triggers level calculation
- Handles streak bonuses

**check_and_award_milestones(user_id UUID)**
- Checks all user milestones for completion
- Awards points for completed milestones
- Returns: TABLE of completed milestones
- Called after activities

**update_login_streak(user_id UUID)**
- Increments login streak for consecutive days
- Resets on missed days
- Awards bonus XP for streaks
- Returns: INT (current streak)

### Database Views

**v_user_progress_summary** (User progress overview)
- Joins user_progress with calculated fields
- Returns all 20+ progress fields
- Used for quick progress retrieval
- Optimized with proper indexing

**v_leaderboard** (Top users ranking)
- Ranks users by total_points DESC
- Includes user profile info (username, avatar)
- Window function for rank calculation
- Limit 100 top users

## Service Implementation

### ProgressTrackingService

Located in `lib/features/progress/services/progress_tracking_service.dart`

#### Core Methods

```dart
// Get user progress data
Future<UserProgressData?> getUserProgress(String userId)

// Get user milestones
Future<List<MilestoneData>> getUserMilestones(String userId)

// Get user achievements
Future<List<AchievementData>> getUserAchievements(String userId)

// Log activity and award points
Future<void> logActivity(String userId, String activityType)

// Check and award milestone completions
Future<List<Map<String, dynamic>>> checkAndAwardMilestones(String userId)

// Update user login streak
Future<int> updateLoginStreak(String userId)

// Get top users leaderboard
Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 100})

// Get user rank position
Future<int> getUserRank(String userId)

// Create custom milestone
Future<void> createMilestone({
  required String userId,
  required String title,
  String? description,
  required int targetValue,
  required int rewardPoints,
})

// Award achievement to user
Future<void> awardAchievement(String userId, String achievementId)

// Get next incomplete milestone
Future<MilestoneData?> getNextMilestone(String userId)

// Estimate time to next level
Future<Duration> estimateTimeToNextLevel(String userId)
```

#### Stream Methods (Real-time Updates)

```dart
// Stream user progress updates
Stream<UserProgressData?> streamUserProgress(String userId)

// Stream milestone updates
Stream<List<MilestoneData>> streamUserMilestones(String userId)

// Stream achievement updates
Stream<List<AchievementData>> streamUserAchievements(String userId)
```

### Data Models

**UserProgressData**
```dart
class UserProgressData {
  final String id;
  final String userId;
  final int totalPoints;
  final int currentLevel;
  final int currentXp;
  final int xpToNextLevel;
  final int totalPosts;
  final int totalComments;
  final int totalLikesReceived;
  final int totalFollowersGained;
  final int totalShares;
  final int loginStreak;
  final DateTime? lastLogin;
  final int postsThisMonth;
  final int commentsThisMonth;
  final DateTime? joinedDate;
  final int profileCompleteness;
  final double engagementScore;
  final int totalAchievementsUnlocked;
  final int currentMilestoneCount;
}
```

**MilestoneData**
```dart
class MilestoneData {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final int targetValue;
  final int currentValue;
  final double progressPercentage;
  final bool isCompleted;
  final int rewardPoints;
  final DateTime? completedAt;
}
```

**AchievementData**
```dart
class AchievementData {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? iconUrl;
  final int points;
  final String rarity; // common, uncommon, rare, epic, legendary
  final DateTime? unlockedAt;
}
```

## Riverpod Providers

```dart
// User progress state
final userProgressProvider = FutureProvider.family<UserProgressData?, String>((ref, userId) {
  return ref.watch(progressTrackingServiceProvider).getUserProgress(userId);
});

// User progress stream
final userProgressStreamProvider = StreamProvider.family<UserProgressData?, String>((ref, userId) {
  return ref.watch(progressTrackingServiceProvider).streamUserProgress(userId);
});

// User milestones
final userMilestonesProvider = FutureProvider.family<List<MilestoneData>, String>((ref, userId) {
  return ref.watch(progressTrackingServiceProvider).getUserMilestones(userId);
});

// User achievements
final userAchievementsProvider = FutureProvider.family<List<AchievementData>, String>((ref, userId) {
  return ref.watch(progressTrackingServiceProvider).getUserAchievements(userId);
});

// Leaderboard
final leaderboardProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(progressTrackingServiceProvider).getLeaderboard();
});

// User rank
final userRankProvider = FutureProvider.family<int, String>((ref, userId) {
  return ref.watch(progressTrackingServiceProvider).getUserRank(userId);
});

// Next milestone
final nextMilestoneProvider = FutureProvider.family<MilestoneData?, String>((ref, userId) {
  return ref.watch(progressTrackingServiceProvider).getNextMilestone(userId);
});

// Time to next level
final timeToNextLevelProvider = FutureProvider.family<Duration, String>((ref, userId) {
  return ref.watch(progressTrackingServiceProvider).estimateTimeToNextLevel(userId);
});
```

## UI Components

Located in `lib/features/progress/presentation/progress_widgets.dart`

### AnimatedProgressBar
Animated progress bar with gradient fill and labels
- `progress`: 0.0-1.0 normalized value
- `label`: Label text
- `trailingText`: Optional right-aligned text (e.g., "250/1000 XP")
- Animation duration: 1.5 seconds with easing

### LevelBadge
Displays current level in circular badge with XP progress
- Level number in large font
- Level title (Novice, Apprentice, etc.)
- XP progress bar toward next level
- Gradient styling with shadow effects

### MilestoneCard
Displays milestone with progress tracking
- Title and description
- Progress bar with percentage
- Current/target value display
- Reward points display
- Completion badge when done

### AchievementBadge
Displays achievement badge
- Circular badge with icon or emoji
- Tooltip with achievement name
- Unlocked/locked state
- Optional large variant with name label

### ProgressStatistics
Shows user engagement statistics
- Posts count
- Comments count
- Likes received
- Followers gained
- Login streak with fire emoji

### LeaderboardEntry
Single leaderboard entry
- Rank badge with color (gold/purple)
- Username and level
- Total points
- Highlight for current user

## UI Screens

Located in `lib/features/progress/presentation/progress_tracking_screen.dart`

### ProgressTrackingScreen
Main progress tracking screen with 3 tabs:

**Overview Tab**
- Level badge with progress
- Quick statistics
- Next milestone preview
- Leaderboard top 5
- User rank display
- Time to next level estimate

**Milestones Tab**
- Active milestones list
- Completed milestones list
- Progress per milestone
- Reward points display

**Achievements Tab**
- Unlocked achievements in grid
- Locked achievements (grayed out)
- Achievement count

## Activity Types and Points

| Activity Type | Points | Notes |
|---|---|---|
| post_created | 50 | Creating a new post |
| comment_posted | 10 | Adding a comment |
| post_liked | 5 | Receiving a like |
| reply_received | 8 | Comment reply |
| share_received | 25 | Post shared |
| follower_gained | 15 | New follower |
| daily_login | 5 | Consecutive login |
| streak_bonus_7d | 35 | 7-day streak bonus |
| streak_bonus_30d | 100 | 30-day streak bonus |
| high_engagement | 50 | Post 100+ engagement |

## Level System

| Level | Title | Min XP | Max XP | Unlocks |
|---|---|---|---|---|
| 1 | Novice | 0 | 999 | Basic features |
| 2 | Apprentice | 1,000 | 4,999 | Custom milestones |
| 3 | Intermediate | 5,000 | 14,999 | Achievement tracking |
| 4 | Advanced | 15,000 | 34,999 | Leaderboard visibility |
| 5 | Expert | 35,000 | 69,999 | Premium achievements |
| 6 | Master | 70,000 | 149,999 | Special badges |
| 7 | Grandmaster | 150,000+ | ∞ | All features |

## Security

### Row-Level Security (RLS) Policies

All progress tables have RLS enabled:
- Users can only view/modify their own data
- Service role has full access for administration
- Prevents unauthorized data access

### Data Validation

- XP values validated as non-negative
- Level clamped to 1-7 range
- Percentage clamped to 0-100
- Activity types validated against enum
- Timestamps automatically generated

## Performance Considerations

### Query Optimization

- Indexed columns: user_id, user_id + is_completed
- GIN indexes on activity logs for fast filtering
- Denormalized progress view for quick retrieval
- Leaderboard view materialized for performance

### Caching Strategy

- User progress cached for 5 minutes
- Leaderboard cached for 30 minutes
- Achievement list cached until unlocks
- Activity log streamed for real-time updates

### Expected Performance

- Get user progress: 5-10ms
- Get leaderboard (top 100): 15-20ms
- Log activity with triggers: 50-100ms
- Get all achievements: 10-15ms

## Testing

### Unit Tests
Located in `test/features/progress/services/progress_tracking_service_test.dart`
- 40+ test cases
- Models serialization
- Helper method logic
- Level calculations
- Milestone progressions
- Streak logic

### Integration Tests
Located in `test/features/progress/integration/progress_integration_test.dart`
- 20+ test cases
- Database operations
- RLS policy enforcement
- Trigger functionality
- Real-time streams
- Leaderboard accuracy

## Deployment Checklist

- [ ] Run database migrations (20240108000000_create_progress_tracking_schema.sql)
- [ ] Apply RLS policies
- [ ] Create service role grants
- [ ] Populate level definitions
- [ ] Set up monitoring for database triggers
- [ ] Configure Riverpod providers
- [ ] Test UI components in Flutter
- [ ] Verify RLS policies with test users
- [ ] Load test leaderboard query
- [ ] Monitor trigger performance
- [ ] Set up analytics for activity logging
- [ ] Create admin dashboard for monitoring

## Troubleshooting

### Progress not updating after activity
- Verify triggers are enabled: `SELECT * FROM information_schema.triggers`
- Check RLS policies: `SELECT * FROM pg_policies`
- Review activity log for errors: `SELECT * FROM progress_activity_log ORDER BY created_at DESC`

### Leaderboard showing wrong ranks
- Materialized view may be stale
- Force refresh: `REFRESH MATERIALIZED VIEW v_leaderboard`
- Check window function calculations

### User not appearing in leaderboard
- Verify user_progress row exists
- Check RLS policy grants
- Ensure total_points is not NULL

### XP not awarding
- Verify activity_type exists in calculate_activity_xp function
- Check function grants
- Review trigger error logs

## Future Enhancements

- [ ] Challenge system (time-limited competitions)
- [ ] Team achievements (group milestones)
- [ ] Seasonal leaderboards
- [ ] Badge trading/gifting
- [ ] Reputation system
- [ ] Social proof (showcase achievements)
- [ ] Notifications on level up
- [ ] Custom milestone creation UI
- [ ] Progress analytics dashboard
- [ ] Export progress data
