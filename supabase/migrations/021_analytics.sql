-- ============================================================
-- VERASSO Schema — Part 21: Analytics & Content Tracking
-- ============================================================
-- 1. Analytics Events (Raw stream for tracking user behavior)
CREATE TABLE public.analytics_events (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    event_name TEXT NOT NULL,
    properties JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert own events" ON public.analytics_events FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own events" ON public.analytics_events FOR
SELECT USING (auth.uid() = user_id);
CREATE INDEX idx_analytics_user_event ON public.analytics_events(user_id, event_name);
CREATE INDEX idx_analytics_created_at ON public.analytics_events(created_at);
-- 2. Content Stats (Aggregated performance metric for posts/simulations)
CREATE TABLE public.content_stats (
    content_id UUID PRIMARY KEY,
    -- references posts.id or simulations.id
    content_type TEXT NOT NULL,
    views_count INT DEFAULT 0,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    engagement_rate DECIMAL(5, 4) DEFAULT 0.0,
    updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.content_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Content stats are public" ON public.content_stats FOR
SELECT USING (true);
-- 3. RPC: Get User Engagement
-- Returns count of events per day for the last N days
CREATE OR REPLACE FUNCTION get_user_engagement(target_user_id UUID, days INT DEFAULT 7) RETURNS TABLE (date DATE, posts INT, likes INT, comments INT) AS $$ BEGIN RETURN QUERY
SELECT created_at::DATE as date,
    COUNT(*) FILTER (
        WHERE event_name = 'post_created'
    )::INT as posts,
    COUNT(*) FILTER (
        WHERE event_name = 'like_added'
    )::INT as likes,
    COUNT(*) FILTER (
        WHERE event_name = 'comment_added'
    )::INT as comments
FROM public.analytics_events
WHERE user_id = target_user_id
    AND created_at >= (now() - (days || ' days')::INTERVAL)
GROUP BY date
ORDER BY date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 4. RPC: Update User Stats
-- Recalculates aggregate stats from other tables into user_stats
CREATE OR REPLACE FUNCTION update_user_stats(target_user_id UUID) RETURNS VOID AS $$
DECLARE v_posts_count INT;
v_total_likes INT;
BEGIN
SELECT COUNT(*) INTO v_posts_count
FROM public.posts
WHERE user_id = target_user_id;
SELECT COALESCE(SUM(likes_count), 0) INTO v_total_likes
FROM public.posts
WHERE user_id = target_user_id;
INSERT INTO public.user_stats (user_id, updated_at)
VALUES (target_user_id, now()) ON CONFLICT (user_id) DO
UPDATE
SET updated_at = now();
-- Future: Here you can also update subject_progress, unlocked_badges_count etc.
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;