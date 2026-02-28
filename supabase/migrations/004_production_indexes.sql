-- ============================================================
-- VERASSO — Production Performance Indexes
-- Apply BEFORE production launch
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
-- Feed performance (resolves full-table scans on post queries)
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_user_created ON public.posts(user_id, created_at DESC);
-- Post detail / comment loading
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_post_time ON public.comments(post_id, created_at DESC);
-- Like queries
CREATE INDEX IF NOT EXISTS idx_likes_post_id ON public.likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_post ON public.likes(user_id, post_id);
-- Chat performance (critical at scale)
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
-- Gamification / activity tracking
CREATE INDEX IF NOT EXISTS idx_user_activities_user_time ON public.user_activities(user_id, created_at DESC);
-- Notification list performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_time ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, is_read)
WHERE is_read = false;
-- Social graph queries
CREATE INDEX IF NOT EXISTS idx_following_follower ON public.user_following(follower_id);
CREATE INDEX IF NOT EXISTS idx_following_following ON public.user_following(following_id);
-- Stories (feed + expiry cleanup)
CREATE INDEX IF NOT EXISTS idx_stories_user ON public.user_stories(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stories_expires ON public.user_stories(expires_at)
WHERE expires_at IS NOT NULL;
-- Conversations (user lookup)
CREATE INDEX IF NOT EXISTS idx_conversations_p1 ON public.conversations(participant1_id);
CREATE INDEX IF NOT EXISTS idx_conversations_p2 ON public.conversations(participant2_id);
-- Search: profiles by username
CREATE INDEX IF NOT EXISTS idx_profiles_username_trgm ON public.profiles USING gin (username gin_trgm_ops);