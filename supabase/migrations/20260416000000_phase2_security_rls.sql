-- ==========================================
-- PHASE 2: SECURITY HARDENING RLS
-- ==========================================

-- 1. Hardening Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
CREATE POLICY "Users can insert their own profile"
ON profiles FOR INSERT
WITH CHECK (firebase_uid = auth.uid());

DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (firebase_uid = auth.uid())
WITH CHECK (firebase_uid = auth.uid());


-- 2. Hardening Posts
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "posts_public_read" ON posts;
CREATE POLICY "Posts are public"
ON posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own posts" ON posts;
CREATE POLICY "Users can insert their own posts"
ON posts FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = posts.author_id 
        AND firebase_uid = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can update their own posts" ON posts;
CREATE POLICY "Users can update their own posts"
ON posts FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = posts.author_id 
        AND firebase_uid = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can delete their own posts" ON posts;
CREATE POLICY "Users can delete their own posts"
ON posts FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = posts.author_id 
        AND firebase_uid = auth.uid()
    )
);


-- 3. Hardening Comments (assuming table exists)
ALTER TABLE IF EXISTS comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Comments are public" ON comments;
CREATE POLICY "Comments are public"
ON comments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own comments" ON comments;
CREATE POLICY "Users can insert their own comments"
ON comments FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = comments.author_id 
        AND firebase_uid = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;
CREATE POLICY "Users can delete their own comments"
ON comments FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = comments.author_id 
        AND firebase_uid = auth.uid()
    )
);


-- 4. Hardening Storage
-- Update existing storage policies to ensure authentication
-- NOTE: Supabase storage auth checks use auth.uid() = owner OR auth.uid() IS NOT NULL.

DO $$
BEGIN
  -- Re-create insert policies for Avatars to enforce authentication
  IF EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can upload Avatars') THEN
     DROP POLICY "Users can upload Avatars" ON storage.objects;
  END IF;

  CREATE POLICY "Users can upload Avatars" 
  ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'avatars' AND auth.uid() IS NOT NULL);

  
  -- Re-create insert policies for Feed Media to enforce authentication
  IF EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can upload Feed Media') THEN
     DROP POLICY "Users can upload Feed Media" ON storage.objects;
  END IF;

  CREATE POLICY "Users can upload Feed Media" 
  ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'feed_media' AND auth.uid() IS NOT NULL);

END $$;
