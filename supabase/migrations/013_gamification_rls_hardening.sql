-- ============================================================
-- VERASSO — Gamification RLS Hardening (Phase 2)
-- Removes direct client write access to user_stats and user_activities
-- Introduces secure RPC for recording activities
-- ============================================================
-- 1. Drop permissive policies on user_stats
DROP POLICY IF EXISTS "Users can update own stats" ON public.user_stats;
DROP POLICY IF EXISTS "Users can insert own stats" ON public.user_stats;
-- 2. Drop permissive policies on user_activities
DROP POLICY IF EXISTS "Record activity" ON public.user_activities;
-- 3. Ensure SELECT policies remain so clients can read their own stats
-- "Public user stats are viewable" already exists on user_stats
-- "View own activities" already exists on user_activities
-- 4. Create the secure RPC for recording activities
CREATE OR REPLACE FUNCTION record_activity_v2(
        p_activity_name TEXT,
        p_metadata JSONB DEFAULT '{}'
    ) RETURNS void AS $$
DECLARE v_activity_type public.activity_types %ROWTYPE;
v_xp INT;
v_user_id UUID;
BEGIN -- Get current user
v_user_id := auth.uid();
IF v_user_id IS NULL THEN RAISE EXCEPTION 'Not authenticated';
END IF;
-- Validate activity type exists and get server-controlled points
SELECT * INTO v_activity_type
FROM public.activity_types
WHERE name = p_activity_name;
IF NOT FOUND THEN RAISE EXCEPTION 'Invalid activity type: %',
p_activity_name;
END IF;
v_xp := v_activity_type.points;
-- 1. Insert into user_activities (audit trail)
INSERT INTO public.user_activities (
        user_id,
        activity_type,
        activity_category,
        points_earned,
        metadata
    )
VALUES (
        v_user_id,
        p_activity_name,
        v_activity_type.category,
        v_xp,
        p_metadata
    );
-- 2. Update user_stats (XP total)
UPDATE public.user_stats
SET total_xp = total_xp + v_xp,
    updated_at = now()
WHERE user_id = v_user_id;
-- Note: existing trigger `trg_user_stats_level` will auto-calculate level/tier
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;