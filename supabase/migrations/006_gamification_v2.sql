-- ============================================================
-- VERASSO — Gamification Engine v2
-- Quests, Guilds, XP Events, Anti-Cheat, Action Log
-- ============================================================
-- ── Daily / Weekly / Seasonal Quests ──────────────────────────
CREATE TABLE IF NOT EXISTS public.quests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    quest_type TEXT NOT NULL CHECK (quest_type IN ('daily', 'weekly', 'seasonal')),
    action_type TEXT NOT NULL,
    target_count INT NOT NULL DEFAULT 1,
    xp_reward INT NOT NULL DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    season_id UUID,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.user_quest_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    quest_id UUID NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,
    current_count INT DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMPTZ,
    reset_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, quest_id, reset_at)
);
CREATE INDEX IF NOT EXISTS idx_quest_progress_user ON public.user_quest_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_quest_progress_reset ON public.user_quest_progress(reset_at);
-- ── XP Multiplier Events ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.xp_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    multiplier DECIMAL(3, 1) NOT NULL DEFAULT 1.5,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_xp_events_active ON public.xp_events(starts_at, ends_at)
WHERE is_active = true;
-- ── Guilds ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.guilds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    emblem_url TEXT,
    leader_id UUID NOT NULL REFERENCES auth.users(id),
    guild_xp INT DEFAULT 0,
    member_count INT DEFAULT 1,
    max_members INT DEFAULT 20,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.guild_members (
    guild_id UUID NOT NULL REFERENCES public.guilds(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('leader', 'officer', 'member')),
    xp_contributed INT DEFAULT 0,
    joined_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (guild_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_guild_members_user ON public.guild_members(user_id);
CREATE INDEX IF NOT EXISTS idx_guilds_xp ON public.guilds(guild_xp DESC);
-- ── Anti-Cheat: Action Rate Log ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.gamification_action_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL,
    xp_awarded INT DEFAULT 0,
    multiplier DECIMAL(3, 1) DEFAULT 1.0,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_action_log_user_time ON public.gamification_action_log(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_action_log_type_time ON public.gamification_action_log(action_type, created_at DESC);
-- ── RLS ───────────────────────────────────────────────────────
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quest_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guilds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guild_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gamification_action_log ENABLE ROW LEVEL SECURITY;
-- Quests: everyone reads active quests
CREATE POLICY "Anyone can read active quests" ON public.quests FOR
SELECT USING (is_active = true);
-- Quest progress: users see their own
CREATE POLICY "Users read own quest progress" ON public.user_quest_progress FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own quest progress" ON public.user_quest_progress FOR
UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users insert own quest progress" ON public.user_quest_progress FOR
INSERT WITH CHECK (auth.uid() = user_id);
-- XP Events: everyone reads active events
CREATE POLICY "Anyone can read active xp events" ON public.xp_events FOR
SELECT USING (
        is_active = true
        AND starts_at <= now()
        AND ends_at >= now()
    );
-- Guilds: everyone can read, members can update
CREATE POLICY "Anyone can read guilds" ON public.guilds FOR
SELECT USING (true);
CREATE POLICY "Leaders update guilds" ON public.guilds FOR
UPDATE USING (auth.uid() = leader_id);
-- Guild members: everyone reads, users manage own membership
CREATE POLICY "Anyone can read guild members" ON public.guild_members FOR
SELECT USING (true);
CREATE POLICY "Users manage own membership" ON public.guild_members FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users leave guilds" ON public.guild_members FOR DELETE USING (auth.uid() = user_id);
-- Action log: users see their own
CREATE POLICY "Users read own action log" ON public.gamification_action_log FOR
SELECT USING (auth.uid() = user_id);
-- ── Guild member count trigger ────────────────────────────────
CREATE OR REPLACE FUNCTION update_guild_member_count() RETURNS TRIGGER AS $$ BEGIN IF TG_OP = 'INSERT' THEN
UPDATE public.guilds
SET member_count = member_count + 1
WHERE id = NEW.guild_id;
ELSIF TG_OP = 'DELETE' THEN
UPDATE public.guilds
SET member_count = member_count - 1
WHERE id = OLD.guild_id;
END IF;
RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_guild_member_change
AFTER
INSERT
    OR DELETE ON public.guild_members FOR EACH ROW EXECUTE FUNCTION update_guild_member_count();
-- ── Seed: Default Quests ──────────────────────────────────────
INSERT INTO public.quests (
        name,
        description,
        quest_type,
        action_type,
        target_count,
        xp_reward
    )
VALUES (
        'Daily Post',
        'Create a post today',
        'daily',
        'post_created',
        1,
        20
    ),
    (
        'Social Butterfly',
        'Comment on 3 posts',
        'daily',
        'comment_written',
        3,
        15
    ),
    (
        'Daily Learner',
        'Complete a lesson',
        'daily',
        'lesson_completed',
        1,
        30
    ),
    (
        'Chat Champion',
        'Send 5 messages',
        'daily',
        'message_sent',
        5,
        10
    ),
    (
        'Weekly Streak',
        'Maintain a 7-day streak',
        'weekly',
        'streak_maintained',
        7,
        100
    ),
    (
        'Code Warrior',
        'Solve 3 coding challenges',
        'weekly',
        'challenge_solved',
        3,
        75
    ),
    (
        'Course Progress',
        'Complete a course chapter',
        'weekly',
        'lesson_completed',
        5,
        50
    ),
    (
        'Helper',
        'Answer 5 doubts',
        'weekly',
        'doubt_answered',
        5,
        60
    ) ON CONFLICT DO NOTHING;
-- ── Anti-Cheat RPC: Validate Action ──────────────────────────
CREATE OR REPLACE FUNCTION validate_gamification_action(
        p_user_id UUID,
        p_action_type TEXT,
        p_cooldown_seconds INT DEFAULT 60
    ) RETURNS JSONB AS $$
DECLARE v_last_action TIMESTAMPTZ;
v_action_count INT;
v_multiplier DECIMAL(3, 1) := 1.0;
BEGIN -- Check cooldown
SELECT created_at INTO v_last_action
FROM public.gamification_action_log
WHERE user_id = p_user_id
    AND action_type = p_action_type
ORDER BY created_at DESC
LIMIT 1;
IF v_last_action IS NOT NULL
AND v_last_action > now() - (p_cooldown_seconds || ' seconds')::interval THEN RETURN jsonb_build_object(
    'allowed',
    false,
    'reason',
    'cooldown',
    'retry_after',
    EXTRACT(
        EPOCH
        FROM (
                v_last_action + (p_cooldown_seconds || ' seconds')::interval - now()
            )
    )::int
);
END IF;
-- Check daily action limit (max 100 XP-earning actions per day)
SELECT count(*) INTO v_action_count
FROM public.gamification_action_log
WHERE user_id = p_user_id
    AND created_at > date_trunc('day', now());
IF v_action_count >= 200 THEN RETURN jsonb_build_object('allowed', false, 'reason', 'daily_limit');
END IF;
-- Check for active XP multiplier
SELECT COALESCE(MAX(multiplier), 1.0) INTO v_multiplier
FROM public.xp_events
WHERE is_active = true
    AND starts_at <= now()
    AND ends_at >= now();
RETURN jsonb_build_object(
    'allowed',
    true,
    'multiplier',
    v_multiplier,
    'daily_actions',
    v_action_count
);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;