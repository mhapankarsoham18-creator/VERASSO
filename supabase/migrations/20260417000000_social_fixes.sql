-- ==========================================
-- SOCIAL FIXES: INCREMENT LIKES, DELETE POST, RLS BRIDGE
-- ==========================================

-- 1. Create the increment_likes RPC (SECURITY DEFINER bypasses RLS)
CREATE OR REPLACE FUNCTION increment_likes(post_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE posts SET likes = COALESCE(likes, 0) + 1 WHERE id = post_id;
END;
$$;

-- 2. Create delete_post_safe RPC — validates ownership via firebase_uid
CREATE OR REPLACE FUNCTION delete_post_safe(p_post_id uuid, p_firebase_uid text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_author_id uuid;
    v_profile_id uuid;
BEGIN
    -- Resolve the profile ID from firebase_uid
    SELECT id INTO v_profile_id FROM profiles WHERE firebase_uid = p_firebase_uid;
    IF v_profile_id IS NULL THEN
        RAISE EXCEPTION 'Profile not found for this user.';
    END IF;

    -- Verify the post belongs to this author
    SELECT author_id INTO v_author_id FROM posts WHERE id = p_post_id;
    IF v_author_id IS NULL THEN
        RAISE EXCEPTION 'Post not found.';
    END IF;
    IF v_author_id != v_profile_id THEN
        RAISE EXCEPTION 'You are not the author of this post.';
    END IF;

    -- Safe to delete
    DELETE FROM posts WHERE id = p_post_id;
END;
$$;

-- 3. Fix RLS for comments — allow anon role to insert (Firebase bridge)
-- The existing policies check auth.uid() = author_id, but since we use
-- Firebase Auth (not Supabase Auth), auth.uid() is always null.
-- Solution: Use a permissive INSERT policy and rely on the app code
-- to set the correct author_id from the Firebase-mapped profile.

DROP POLICY IF EXISTS "Users can insert their own comments" ON comments;
DROP POLICY IF EXISTS "Users can insert comments" ON comments;
CREATE POLICY "Users can insert comments"
ON comments FOR INSERT
WITH CHECK (true);

-- 4. Fix RLS for posts — allow anon role to insert
DROP POLICY IF EXISTS "Users can insert their own posts" ON posts;
CREATE POLICY "Users can insert posts"
ON posts FOR INSERT
WITH CHECK (true);

-- 5. Fix RLS for post_saves — allow anon role to insert/select
DROP POLICY IF EXISTS "Users can see own saves" ON post_saves;
CREATE POLICY "Users can see saves"
ON post_saves FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Users can save posts" ON post_saves;
CREATE POLICY "Users can save posts"
ON post_saves FOR INSERT
WITH CHECK (true);

-- 6. Fix RLS for profiles — allow anon role to insert/update (Firebase bridge)
-- Since users manage their profile via firebase_uid, not auth.uid()
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
CREATE POLICY "Users can insert profile"
ON profiles FOR INSERT
WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update profile"
ON profiles FOR UPDATE
USING (true)
WITH CHECK (true);

-- 7. Ensure profiles are publicly readable
DROP POLICY IF EXISTS "Profiles are public" ON profiles;
CREATE POLICY "Profiles are public"
ON profiles FOR SELECT
USING (true);

-- 8. Ensure posts likes column exists (idempotent)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS likes integer DEFAULT 0;
