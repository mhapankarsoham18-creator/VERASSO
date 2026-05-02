-- ==========================================
-- PHASE 1: SECURITY LOCKDOWN
-- ==========================================

-- 1. GAMIFICATION RLS — Prevent XP manipulation
-- Users can only insert quest completions for their own profile
ALTER TABLE IF EXISTS public.quest_completions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert own completions" ON public.quest_completions;
CREATE POLICY "Users can insert own completions" ON public.quest_completions
    FOR INSERT WITH CHECK (
        profile_id IN (
            SELECT id FROM public.profiles
            WHERE firebase_uid = (auth.jwt() ->> 'sub')
        )
    );

DROP POLICY IF EXISTS "Users can view own completions" ON public.quest_completions;
CREATE POLICY "Users can view own completions" ON public.quest_completions
    FOR SELECT USING (
        profile_id IN (
            SELECT id FROM public.profiles
            WHERE firebase_uid = (auth.jwt() ->> 'sub')
        )
    );

DROP POLICY IF EXISTS "Users can update own completions" ON public.quest_completions;
CREATE POLICY "Users can update own completions" ON public.quest_completions
    FOR UPDATE USING (
        profile_id IN (
            SELECT id FROM public.profiles
            WHERE firebase_uid = (auth.jwt() ->> 'sub')
        )
    );


-- 2. SECURE add_sidequest_xp RPC — verify caller owns the profile
CREATE OR REPLACE FUNCTION public.add_sidequest_xp(p_profile_id UUID, p_xp INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    caller_uid TEXT := (auth.jwt() ->> 'sub');
    profile_owner TEXT;
BEGIN
    -- Verify the caller owns this profile
    SELECT firebase_uid INTO profile_owner
    FROM public.profiles
    WHERE id = p_profile_id;

    IF profile_owner IS NULL OR profile_owner != caller_uid THEN
        RAISE EXCEPTION 'Unauthorized: Cannot modify XP for another user';
    END IF;

    UPDATE public.profiles
    SET sidequest_xp = COALESCE(sidequest_xp, 0) + p_xp
    WHERE id = p_profile_id;
END;
$$;


-- 3. POST_SAVES — Add unique constraint and fix column type
-- Ensure post_saves uses UUID for user_id (matching profiles.id)
DO $$
BEGIN
    -- Add unique constraint if not exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'post_saves_user_post_unique'
    ) THEN
        ALTER TABLE public.post_saves 
        ADD CONSTRAINT post_saves_user_post_unique UNIQUE (user_id, post_id);
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'post_saves constraint may already exist or table structure differs: %', SQLERRM;
END $$;

-- RLS for post_saves
ALTER TABLE IF EXISTS public.post_saves ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can save own posts" ON public.post_saves;
CREATE POLICY "Users can save own posts" ON public.post_saves
    FOR ALL USING (
        user_id IN (
            SELECT id FROM public.profiles
            WHERE firebase_uid = (auth.jwt() ->> 'sub')
        )
    );


-- 4. STORAGE BUCKET SIZE LIMITS
-- Supabase doesn't support SQL-level bucket size limits directly,
-- but we can enforce via storage policies with file size checks.
-- These are configured in the Supabase Dashboard under Storage > Policies.
-- Setting max file sizes:
--   avatars: 5MB
--   feed_media: 50MB
--   quest-photos: 5MB

-- Update bucket configurations
UPDATE storage.buckets SET file_size_limit = 5242880 WHERE id = 'avatars';        -- 5MB
UPDATE storage.buckets SET file_size_limit = 52428800 WHERE id = 'feed_media';    -- 50MB
UPDATE storage.buckets SET file_size_limit = 5242880 WHERE id = 'quest-photos';   -- 5MB

-- Restrict allowed MIME types per bucket
UPDATE storage.buckets 
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
WHERE id = 'avatars';

UPDATE storage.buckets 
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'video/mp4', 'video/quicktime', 'audio/m4a', 'audio/mpeg']
WHERE id = 'feed_media';

UPDATE storage.buckets 
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
WHERE id = 'quest-photos';
