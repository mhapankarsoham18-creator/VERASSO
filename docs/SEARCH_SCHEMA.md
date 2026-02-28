/// Full-Text Search Service Database Schema Documentation
/// 
/// This document defines all database tables and configurations required
/// for the full-text search feature. All schemas should be created via SQL
/// migrations before the feature is deployed to production.

/*

## 1. MAIN SEARCH TABLES

### posts_fts (Full-Text Search Index for Posts)
- Automatically maintained view/trigger-based index
- Built from posts table
- Includes: id, title, content, author_id, created_at
- Indexed by: title, content (English text search)

CREATE TABLE IF NOT EXISTS posts_search_index (
  id UUID PRIMARY KEY REFERENCES posts(id) ON DELETE CASCADE,
  search_vector tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('english', COALESCE(posts.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(posts.content, '')), 'B')
  ) STORED,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_posts_search_vector 
  ON posts_search_index USING gin(search_vector);

### users_fts (Full-Text Search Index for Users)
- Indexes user profiles for search
- Includes: id, username, full_name, bio
- Indexed by: username, full_name, bio

CREATE TABLE IF NOT EXISTS users_search_index (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  search_vector tsvector GENERATED ALWAYS AS (
    setweight(to_tsvector('english', COALESCE(profiles.username, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(profiles.full_name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(profiles.bio, '')), 'B')
  ) STORED,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_search_vector 
  ON users_search_index USING gin(search_vector);

### hashtags (Hashtag Index)
- Stores and indexes trending hashtags
- Denormalized for fast counting

CREATE TABLE IF NOT EXISTS hashtags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tag_text VARCHAR(100) UNIQUE NOT NULL,
  post_count INT DEFAULT 0,
  trending_score FLOAT DEFAULT 0,
  last_used_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_hashtags_tag_text 
  ON hashtags(tag_text);
CREATE INDEX IF NOT EXISTS idx_hashtags_trending_score 
  ON hashtags(trending_score DESC);
CREATE INDEX IF NOT EXISTS idx_hashtags_last_used 
  ON hashtags(last_used_at DESC);

### post_hashtags (Post-Hashtag Association)
- Junction table for many-to-many relationship

CREATE TABLE IF NOT EXISTS post_hashtags (
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  hashtag_id UUID NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (post_id, hashtag_id)
);

CREATE INDEX IF NOT EXISTS idx_post_hashtags_hashtag_id 
  ON post_hashtags(hashtag_id);

## 2. SEARCH ANALYTICS TABLES

### search_queries (User Search History)
- Track what users search for
- Used for analytics and trending

CREATE TABLE IF NOT EXISTS search_queries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  query_text VARCHAR(500) NOT NULL,
  result_type VARCHAR(50), -- 'post' | 'user' | 'hashtag' | 'all'
  result_count INT DEFAULT 0,
  execution_time_ms INT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_search_queries_user_id 
  ON search_queries(user_id);
CREATE INDEX IF NOT EXISTS idx_search_queries_created_at 
  ON search_queries(created_at DESC);

### search_clicks (User Search Result Interaction)
- Track which results users click on
- Used for relevance scoring

CREATE TABLE IF NOT EXISTS search_clicks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  search_query_id UUID REFERENCES search_queries(id) ON DELETE CASCADE,
  result_type VARCHAR(50), -- 'post' | 'user' | 'hashtag'
  result_id UUID NOT NULL,
  rank_position INT,
  clicked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_search_clicks_user_id 
  ON search_clicks(user_id);
CREATE INDEX IF NOT EXISTS idx_search_clicks_result_id 
  ON search_clicks(result_id);

## 3. PERFORMANCE & CACHING TABLES

### search_cache (Query Result Cache)
- Cache frequent search results
- 24-hour TTL

CREATE TABLE IF NOT EXISTS search_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  query_hash VARCHAR(64) UNIQUE NOT NULL,
  result_type VARCHAR(50),
  cached_results JSONB,
  hit_count INT DEFAULT 1,
  expires_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_search_cache_expires_at 
  ON search_cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_search_cache_query_hash 
  ON search_cache(query_hash);

## 4. ROW LEVEL SECURITY (RLS) POLICIES

-- search_queries: Users can only see their own searches
ALTER TABLE search_queries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own searches"
  ON search_queries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own searches"
  ON search_queries FOR SELECT
  WHERE (auth.uid() = user_id);

-- search_clicks: Users can only see their own clicks
ALTER TABLE search_clicks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own clicks"
  ON search_clicks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own clicks"
  ON search_clicks FOR SELECT
  WHERE (auth.uid() = user_id);

-- hashtags: Everyone can read, service account writes
ALTER TABLE hashtags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can read hashtags"
  ON hashtags FOR SELECT
  USING (true);

-- search_cache: Everyone can read, service account writes/updates
ALTER TABLE search_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Everyone can read search cache"
  ON search_cache FOR SELECT
  USING (true);

## 5. MAINTENANCE FUNCTIONS

-- Cleanup expired cache entries
CREATE OR REPLACE FUNCTION cleanup_expired_search_cache()
RETURNS void AS $$
BEGIN
  DELETE FROM search_cache 
  WHERE expires_at < CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Update hashtag trending score (run periodically)
CREATE OR REPLACE FUNCTION update_hashtag_trending_score()
RETURNS void AS $$
BEGIN
  UPDATE hashtags h
  SET trending_score = (
    SELECT COUNT(*) / (1 + EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - h.last_used_at)) / 3600)
  )
  WHERE last_used_at > CURRENT_TIMESTAMP - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

## 6. PERFORMANCE CONSIDERATIONS

- Full-text search vectors use PostgreSQL tsvector for O(log n) search
- Hashtags denormalized for O(1) trending count access
- Cache layer reduces database load for repeated searches
- Analytics tables are append-only (no updates) for fast INSERTs
- All indexes are CREATED IF NOT EXISTS to support idempotent migrations
- GIN indexes on tsvector provide optimal text search performance

## 7. QUERY PATTERNS

-- Simple full-text search on posts
SELECT p.* FROM posts p
JOIN posts_search_index psi ON p.id = psi.id
WHERE psi.search_vector @@ plainto_tsquery('english', 'query')
ORDER BY ts_rank(psi.search_vector, plainto_tsquery('english', 'query')) DESC
LIMIT 20;

-- Hashtag search
SELECT * FROM hashtags
WHERE tag_text ILIKE '%query%'
ORDER BY trending_score DESC, last_used_at DESC
LIMIT 20;

-- User search with relevance
SELECT p.* FROM profiles p
JOIN users_search_index usi ON p.id = usi.id
WHERE usi.search_vector @@ plainto_tsquery('english', 'query')
ORDER BY ts_rank(usi.search_vector, plainto_tsquery('english', 'query')) DESC
LIMIT 20;

*/
