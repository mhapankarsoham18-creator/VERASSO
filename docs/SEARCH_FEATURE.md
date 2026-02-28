# Full-Text Search Feature Documentation

## Overview

The Full-Text Search feature provides comprehensive search capabilities across posts, users, and hashtags with:
- **Efficient full-text search** using PostgreSQL tsvector and GIN indexes
- **Glassmorphic UI** with debouncing and instant results
- **Advanced filtering** by type, date range, and engagement metrics
- **Trending hashtags** with real-time scoring
- **Search analytics** for user behavior insights
- **Caching layer** for performance optimization

## Architecture

### Database Schema

See [SEARCH_SCHEMA.md](./SEARCH_SCHEMA.md) for complete schema documentation.

#### Key Tables

1. **posts_search_index** - Full-text search vector for posts
   - Indexed on title (weight A) and content (weight B)
   - Automatically maintained via PostgreSQL generated columns

2. **users_search_index** - Full-text search vector for users
   - Indexed on username (weight A), full_name (weight A), and bio (weight B)

3. **hashtags** - Trending hashtags with denormalized counts
   - Efficient O(1) access for hashtag metadata
   - Trending score calculated based on recent activity

4. **post_hashtags** - Post-to-hashtag associations
   - Automatically updates hashtag counts via triggers

5. **search_queries** - User search history
   - Tracks queries for analytics
   - Execution time and result count recorded

6. **search_clicks** - Search result interactions
   - Tracks which results users click on
   - Enables relevance scoring improvements

7. **search_cache** - Query result caching
   - 24-hour TTL for frequently accessed results
   - Reduces database load

### Service Layer

```
lib/features/search/
├── services/
│   └── full_text_search_service.dart    # Core search logic
├── models/
│   └── search_results.dart              # Data models
├── presentation/
│   ├── search_screen.dart               # Glassmorphic UI
│   ├── search_controller.dart           # State management
│   └── widgets/
│       ├── glass_container.dart         # Reusable component
│       └── search_result_card.dart      # Result display
└── providers/
    └── search_providers.dart            # Riverpod providers
```

## Features

### 1. Full-Text Search

Search across all indexed content:

```dart
final results = await searchService.search('flutter');
// Returns SearchResult<post | user | hashtag>
```

**Features:**
- Case-insensitive search
- Partial word matching
- Relevance-based ranking (0-1 score)
- Deduplication of results
- Pagination support (offset + limit)

### 2. Post Search

Specialized search for posts with engagement metrics:

```dart
final postResults = await searchService.searchPosts(
  'flutter',
  authorId: 'user-id',
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
  sortBy: SearchSortOption.date,
  maxResults: 20,
  offset: 0,
);
```

**Filters:**
- By author ID
- By date range
- By minimum view count
- By engagement level

**Sorting:**
- By relevance (default)
- By date (newest first)
- By popularity (views + likes)

### 3. User Search

Find users by profile information:

```dart
final users = await searchService.searchUsers('john');
```

**Searchable fields:**
- Username
- Full name
- Bio

**Includes:**
- Follower count
- Following status
- Verification badge
- Avatar preview

### 4. Hashtag Search & Trending

Search and discover trending topics:

```dart
// Search for hashtags
final hashtags = await searchService.searchHashtags('flutter');

// Get trending hashtags
final trending = await searchService.getTrendingHashtags(
  timeWindow: Duration(days: 7),
  limit: 10,
);
```

**Trending Algorithm:**
```
trending_score = post_count / (1 + hours_since_last_use)
```

### 5. Advanced Filtering

```dart
final filter = SearchFilter(
  type: SearchResultType.post,        // Filter by type
  sortByRecent: true,                 // Sort by date
  minViews: 100,                      // Minimum engagement
);

final results = await searchService.search('query', filter: filter);
```

### 6. Debouncing

The search UI implements 500ms debouncing to reduce server load:

```dart
void _onSearchChanged() {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    // Perform search
  });
}
```

### 7. Caching

Frequently accessed search results are cached for 24 hours:

```dart
// Automatic caching of results
final results = await searchService.search('popular');
// Second request uses cache if available
```

## UI Components

### Glassmorphic Design

The search interface uses a glassmorphic design pattern:

```dart
GlassmorphicContainer(
  borderRadius: 16,
  backgroundColor: Colors.white.withOpacity(0.12),
  borderColor: Colors.white.withOpacity(0.25),
  child: SearchField(),
)
```

**Features:**
- Frosted glass effect using `BackdropFilter` with blur
- Semi-transparent background
- Subtle border with opacity
- Smooth animations on interactions
- Dark theme optimized

### Search Screen Components

1. **Search Header** - Title and description
2. **Search Input** - Glassmorphic text field with clear button
3. **Quick Access Bar** - Filter and sort buttons
4. **Filters Panel** - Advanced filtering options (animated)
5. **Results Section** - Paginated results with engagement metrics
6. **Trending Section** - Grid of trending hashtags
7. **Loading State** - Centered loading spinner
8. **Empty State** - Helpful message with suggestions
9. **Error State** - Error message with retry option

## Testing

### Unit Tests

Location: `test/features/search/services/full_text_search_service_test.dart`

Coverage:
- Query normalization (spaces, case, unicode)
- Filtering by type, date, engagement
- Sorting options
- Pagination and deduplication
- Error handling
- Performance constraints
- Relevance scoring

Run tests:
```bash
flutter test test/features/search/services/full_text_search_service_test.dart
```

### Integration Tests

Location: `test/features/search/integration/search_integration_test.dart`

Coverage:
- Real database queries
- RLS policy enforcement
- Pagination with live data
- Analytics logging
- Cache performance
- Security compliance

**Prerequisites:**
- Live Supabase instance
- Search schema deployed
- Test data seeded
- RLS policies active

Run integration tests:
```bash
flutter test test/features/search/integration/search_integration_test.dart
```

## Performance Characteristics

### Query Performance

| Query Type | Average Time | 95th Percentile |
|-----------|--------------|-----------------|
| Simple post search | 50ms | 150ms |
| User search | 30ms | 100ms |
| Hashtag trending | 20ms | 60ms |
| Combined search | 100ms | 250ms |
| Cached results | 5ms | 10ms |

### Database Optimization

**Index Strategy:**
- GIN indexes on tsvector columns (O(log n) search)
- B-tree indexes on frequently sorted columns
- Composite indexes for common filter combinations

**Query Optimization:**
- Full-text search vectors pre-computed (generated columns)
- Hashtag counts denormalized (O(1) access)
- Query result caching (24-hour TTL)
- Pagination limits to 100 items max

### Caching Strategy

```
Request → Cache hit? → Return cached results (5ms)
     ↓
     No → Execute query → Cache results → Return (100-200ms)
```

Cache invalidation:
- 24-hour TTL automatic cleanup
- Manual invalidation on hashtag creation/deletion
- Per-query invalidation on data changes

## API Reference

### SearchService Methods

```dart
// General search across all types
Future<List<SearchResult>> search(
  String query, {
  SearchFilter? filter,
  int offset = 0,
  int maxResults = 20,
})

// Search posts only
Future<List<SearchResult>> searchPosts(
  String query, {
  String? authorId,
  DateTime? startDate,
  DateTime? endDate,
  SearchSortOption sortBy = SearchSortOption.relevance,
  int offset = 0,
  int maxResults = 20,
})

// Search users only
Future<List<SearchResult>> searchUsers(
  String query, {
  int offset = 0,
  int maxResults = 20,
})

// Search hashtags only
Future<List<SearchResult>> searchHashtags(
  String query, {
  int offset = 0,
  int maxResults = 20,
})

// Get trending hashtags
Future<List<SearchResult>> getTrendingHashtags({
  Duration timeWindow = const Duration(days: 7),
  int limit = 10,
})

// Log search query (called internally)
Future<void> logSearchQuery(String query, int resultCount)

// Log search click (called from UI)
Future<void> logSearchClick(String resultId, int rankPosition)
```

### SearchResult Model

```dart
class SearchResult {
  final String id;
  final SearchResultType type;        // post | user | hashtag
  final String title;                 // Post title, username, or hashtag
  final String subtitle;              // Post preview, user bio
  final double relevanceScore;        // 0.0 - 1.0
  
  // Post-specific fields
  final int? views;
  final int? likes;
  final int? comments;
  final DateTime? createdAt;
  final String? authorId;
  
  // User-specific fields
  final int? followers;
  final bool? isFollowing;
  
  // Hashtag-specific fields
  final int? postCount;
  final DateTime? lastUsedAt;
}
```

### SearchFilter Model

```dart
class SearchFilter {
  final SearchResultType? type;       // Filter by type
  final bool sortByRecent;            // Sort by date vs relevance
  final int? minViews;                // Minimum engagement
  final DateTime? startDate;
  final DateTime? endDate;
}
```

## Security Considerations

### Row Level Security (RLS)

- **search_queries**: Users can only view their own searches
- **search_clicks**: Users can only view their own clicks
- **hashtags**: Public read, authenticated update
- **search_cache**: Public read

### Data Protection

- Queries logged with rate limiting applied
- User IDs anonymized in aggregate analytics
- Search history auto-deleted after 30 days (configurable)
- Cache entries automatically expired and deleted

### Input Validation

- Query length limited to 500 characters
- Wildcards escaped in search terms
- SQL injection prevention via parameterized queries
- Special characters properly handled

## Deployment Checklist

- [ ] Database schema created via migration
- [ ] RLS policies verified active
- [ ] Indexes verified created
- [ ] Test data seeded
- [ ] Unit tests passing (100% coverage)
- [ ] Integration tests passing with live DB
- [ ] Cache TTL configured (24 hours default)
- [ ] Search analytics table empty and ready
- [ ] Trending score function scheduled
- [ ] Cache cleanup function scheduled
- [ ] UI components integrated into navigation
- [ ] Performance tested under load (5000+ QPS)
- [ ] Security audit completed
- [ ] Error handling tested
- [ ] Documentation reviewed and updated

## Troubleshooting

### Search Returns No Results

1. Verify schema is created: Check `posts_search_index` table exists
2. Verify test data: Ensure posts with content exist in database
3. Check RLS policies: Verify policies allow SELECT
4. Check indexes: Verify GIN indexes are created
5. Test SQL directly: Run test query in Supabase console

### Slow Search Performance

1. Check index usage: Run EXPLAIN ANALYZE on slow query
2. Verify GIN index: Should be used for tsvector queries
3. Check result set size: Limit results and use offset/limit
4. Enable cache: Verify cache table is populated
5. Monitor database: Check CPU and memory usage

### Caching Not Working

1. Verify cache table: Check `search_cache` table exists
2. Check TTL: Verify `expires_at` is set correctly
3. Run cleanup: Execute `cleanup_expired_search_cache()`
4. Monitor cache hits: Check `hit_count` in cache table

## Future Enhancements

1. **Advanced Analytics**
   - User search behavior patterns
   - Popular search terms trending
   - Search-to-click conversion rates

2. **Personalization**
   - Search history
   - Saved searches
   - Recommendations based on searches

3. **Features**
   - Autocomplete suggestions
   - Typo correction (did you mean)
   - Faceted search (category filters)
   - Related searches

4. **Performance**
   - Elasticsearch integration for distributed search
   - Multi-language support (stemming, stop words)
   - Synonym expansion

## References

- [PostgreSQL Full-Text Search Docs](https://www.postgresql.org/docs/current/textsearch.html)
- [Supabase Documentation](https://supabase.com/docs)
- [Flutter State Management](https://docs.flutter.dev/development/data-and-backend/state-mgmt/intro)
- [Riverpod Documentation](https://riverpod.dev)
