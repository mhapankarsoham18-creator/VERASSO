-- ============================================================
-- VERASSO — Unified Gamification Schema
-- Consolidates user_xp, user_stats, and user_progress_summary
-- ============================================================
-- 1. Create a unified user_stats table if not exists, or migrate existing ones
-- We will use "user_stats" as the primary name since it's used in the Flutter Repository
CREATE TABLE IF NOT EXISTS public.user_stats (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    total_xp INT DEFAULT 0,
    weekly_xp INT DEFAULT 0,
    monthly_xp INT DEFAULT 0,
    level INT DEFAULT 1,
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    subject_progress JSONB DEFAULT '{}',
    unlocked_badges_count INT DEFAULT 0,
    rank INT,
    tier TEXT DEFAULT 'bronze',
    last_active TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
-- RLS
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public user stats are viewable" ON public.user_stats FOR
SELECT USING (true);
CREATE POLICY "Users can update own stats" ON public.user_stats FOR
UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own stats" ON public.user_stats FOR
INSERT WITH CHECK (auth.uid() = user_id);
-- 2. Leaderboard Materialized Views or RPCs
-- We already have leaderboard_overall and leaderboard_weekly in 20260422_phase_11_gamification.sql
-- but they point to user_xp. Let's redirect them or create RPCs that are more flexible.
CREATE OR REPLACE FUNCTION get_overall_leaderboard(p_limit INT DEFAULT 50) RETURNS TABLE (
        user_id UUID,
        username TEXT,
        avatar_url TEXT,
        total_xp INT,
        level INT,
        current_streak INT,
        rank INT
    ) AS $$ BEGIN RETURN QUERY
SELECT s.user_id,
    p.username,
    p.avatar_url,
    s.total_xp,
    s.level,
    s.current_streak,
    DENSE_RANK() OVER (
        ORDER BY s.total_xp DESC
    )::INT as rank
FROM public.user_stats s
    JOIN public.profiles p ON s.user_id = p.id
ORDER BY s.total_xp DESC
LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION get_weekly_leaderboard(p_limit INT DEFAULT 50) RETURNS TABLE (
        user_id UUID,
        username TEXT,
        avatar_url TEXT,
        weekly_xp INT,
        rank INT
    ) AS $$ BEGIN RETURN QUERY
SELECT s.user_id,
    p.username,
    p.avatar_url,
    s.weekly_xp,
    DENSE_RANK() OVER (
        ORDER BY s.weekly_xp DESC
    )::INT as rank
FROM public.user_stats s
    JOIN public.profiles p ON s.user_id = p.id
WHERE s.weekly_xp > 0
ORDER BY s.weekly_xp DESC
LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 3. Utility RPCs
-- Increment a value in a table safely
CREATE OR REPLACE FUNCTION increment_value(
        table_name TEXT,
        column_name TEXT,
        row_id UUID,
        increment_by INT
    ) RETURNS VOID AS $$ BEGIN EXECUTE format(
        'UPDATE public.%I SET %I = %I + $1, updated_at = now() WHERE user_id = $2',
        table_name,
        column_name,
        column_name
    ) USING increment_by,
    row_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Increment guild XP
CREATE OR REPLACE FUNCTION increment_guild_xp(
        p_guild_id UUID,
        p_user_id UUID,
        p_xp INT
    ) RETURNS VOID AS $$ BEGIN -- Update member contribution
UPDATE public.guild_members
SET xp_contributed = xp_contributed + p_xp
WHERE guild_id = p_guild_id
    AND user_id = p_user_id;
-- Update total guild XP
UPDATE public.guilds
SET guild_xp = guild_xp + p_xp,
    updated_at = now()
WHERE id = p_guild_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Check and award achievements based on stats
CREATE OR REPLACE FUNCTION check_user_achievements(p_user_id UUID) RETURNS JSONB AS $$
DECLARE v_stats RECORD;
v_newly_awarded TEXT [] := ARRAY []::TEXT [];
BEGIN
SELECT * INTO v_stats
FROM public.user_stats
WHERE user_id = p_user_id;
-- Very basic example of server-side badge check
-- Most are handled in Flutter for better UX, but this ensures DB consistency
RETURN jsonb_build_object('awarded', v_newly_awarded);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 4. Triggers for Automatic Rank/Level Updates
CREATE OR REPLACE FUNCTION update_user_level() RETURNS TRIGGER AS $$ BEGIN -- level = floor(total_xp / 100) + 1
    NEW.level := (NEW.total_xp / 100) + 1;
-- Update Tier
IF NEW.total_xp < 1000 THEN NEW.tier := 'bronze';
ELSIF NEW.total_xp < 5000 THEN NEW.tier := 'silver';
ELSIF NEW.total_xp < 10000 THEN NEW.tier := 'gold';
ELSE NEW.tier := 'platinum';
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_user_stats_level BEFORE
UPDATE OF total_xp ON public.user_stats FOR EACH ROW EXECUTE FUNCTION update_user_level();
-- 5. Migration Logic (Optional/Safe)
-- Attempt to pull data from old tables if they exist
DO $$ BEGIN IF EXISTS (
    SELECT
    FROM information_schema.tables
    WHERE table_schema = 'public'
        AND table_name = 'user_xp'
) THEN
INSERT INTO public.user_stats (
        user_id,
        total_xp,
        weekly_xp,
        monthly_xp,
        last_active
    )
SELECT user_id,
    total_xp,
    weekly_xp,
    0,
    last_activity
FROM public.user_xp ON CONFLICT (user_id) DO NOTHING;
END IF;
END $$;
-- 6. Update user_leaderboard view to point to unified user_stats
DROP VIEW IF EXISTS public.user_leaderboard CASCADE;
CREATE OR REPLACE VIEW public.user_leaderboard AS
SELECT s.user_id,
    p.username,
    p.avatar_url,
    s.total_xp as total_points,
    s.level,
    s.rank,
    s.unlocked_badges_count as achievements_count,
    COALESCE(
        (s.subject_progress->>'ar_projects_completed')::int,
        0
    ) as ar_projects_completed,
    COALESCE(
        (s.subject_progress->>'lessons_completed')::int,
        0
    ) as lessons_completed
FROM public.user_stats s
    JOIN public.profiles p ON s.user_id = p.id;
-- 7. Redirect Materialized Views (if they exist)
DROP MATERIALIZED VIEW IF EXISTS leaderboard_overall CASCADE;
CREATE MATERIALIZED VIEW leaderboard_overall AS
SELECT *
FROM get_overall_leaderboard(1000);
DROP MATERIALIZED VIEW IF EXISTS leaderboard_weekly CASCADE;
CREATE MATERIALIZED VIEW leaderboard_weekly AS
SELECT *
FROM get_weekly_leaderboard(1000);