-- Migration 019: Seasonal Events Logic
-- Description: Helper functions and triggers for handling active seasonal events and XP multipliers.
-- Function to get current active events with their rewards
CREATE OR REPLACE FUNCTION get_active_seasonal_events_with_rewards() RETURNS TABLE (
        event_id UUID,
        title TEXT,
        description TEXT,
        start_at TIMESTAMPTZ,
        end_at TIMESTAMPTZ,
        metadata JSONB,
        rewards JSONB
    ) AS $$ BEGIN RETURN QUERY
SELECT e.id,
    e.title,
    e.description,
    e.start_at,
    e.end_at,
    e.metadata,
    jsonb_agg(r.*) as rewards
FROM seasonal_events e
    LEFT JOIN event_rewards r ON e.id = r.event_id
WHERE e.is_active = true
    AND e.start_at <= now()
    AND e.end_at >= now()
GROUP BY e.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Function to check and award event-based achievements
CREATE OR REPLACE FUNCTION check_seasonal_event_completion(p_user_id UUID, p_event_id UUID) RETURNS void AS $$
DECLARE v_reward RECORD;
v_user_points INT;
BEGIN -- Get user's points for this specific event (e.g. from user_activities)
-- This assumes event-specific activity tracking or filters
-- For now, we'll placeholder this or base it on total XP earned during event
FOR v_reward IN
SELECT *
FROM event_rewards
WHERE event_id = p_event_id LOOP -- Check if requirement is met (simplistic check for example)
    -- requirement_criteria: {"type": "min_xp", "value": 500}
    IF v_reward.requirement_criteria->>'type' = 'min_xp' THEN
SELECT COALESCE(SUM(xp_earned), 0) INTO v_user_points
FROM user_activities
WHERE user_id = p_user_id
    AND created_at >= (
        SELECT start_at
        FROM seasonal_events
        WHERE id = p_event_id
    );
IF v_user_points >= (v_reward.requirement_criteria->>'value')::INT THEN -- Award achievement or bonus XP
IF v_reward.achievement_id IS NOT NULL THEN
INSERT INTO user_achievements (user_id, achievement_id, is_completed, earned_at)
VALUES (p_user_id, v_reward.achievement_id, true, now()) ON CONFLICT (user_id, achievement_id) DO NOTHING;
END IF;
IF v_reward.xp_bonus > 0 THEN
UPDATE user_progress_summary
SET total_xp = total_xp + v_reward.xp_bonus
WHERE user_id = p_user_id;
END IF;
END IF;
END IF;
END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;