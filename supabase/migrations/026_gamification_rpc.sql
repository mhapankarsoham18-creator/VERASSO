-- ============================================================
-- VERASSO Schema — Part 26: Unified Badge Claims RPC
-- ============================================================
-- 1. Ensure user_badges exists (it should from 002)
-- 2. Ensure user_stats exists (it should from 011)
-- 3. Atomic claim_badge RPC
-- This function handles the insertion into user_badges and increments total_xp in user_stats.
CREATE OR REPLACE FUNCTION claim_badge(p_user_id UUID, p_badge_id TEXT, p_xp_reward INT) RETURNS JSONB AS $$ BEGIN -- 1. Check if already claimed
    IF EXISTS (
        SELECT 1
        FROM public.user_badges
        WHERE user_id = p_user_id
            AND badge_id = p_badge_id
    ) THEN RETURN jsonb_build_object('success', false, 'reason', 'already_unlocked');
END IF;
-- 2. Record unlock
INSERT INTO public.user_badges (user_id, badge_id, unlocked_at)
VALUES (p_user_id, p_badge_id, now());
-- 3. Update user stats atomically
-- Note: level and tier are handled by triggers on user_stats (from 011_gamification_unified.sql)
UPDATE public.user_stats
SET total_xp = total_xp + p_xp_reward,
    unlocked_badges_count = unlocked_badges_count + 1,
    updated_at = now()
WHERE user_id = p_user_id;
RETURN jsonb_build_object('success', true, 'xp_awarded', p_xp_reward);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;