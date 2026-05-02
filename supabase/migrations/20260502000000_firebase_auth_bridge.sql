-- ==========================================
-- PHASE 2.1: FIREBASE JWT BRIDGE
-- ==========================================

-- This script modifies the previous security rules to use `auth.jwt() ->> 'sub'`
-- which extracts the Firebase UID from the custom JWT passed by the Flutter app.

-- 1. Profiles
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
CREATE POLICY "Users can insert their own profile"
ON profiles FOR INSERT
WITH CHECK (firebase_uid = (auth.jwt() ->> 'sub')::text);

DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile"
ON profiles FOR UPDATE
USING (firebase_uid = (auth.jwt() ->> 'sub')::text)
WITH CHECK (firebase_uid = (auth.jwt() ->> 'sub')::text);


-- 2. Posts
DROP POLICY IF EXISTS "Users can insert their own posts" ON posts;
CREATE POLICY "Users can insert their own posts"
ON posts FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = posts.author_id 
        AND firebase_uid = (auth.jwt() ->> 'sub')::text
    )
);

DROP POLICY IF EXISTS "Users can update their own posts" ON posts;
CREATE POLICY "Users can update their own posts"
ON posts FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = posts.author_id 
        AND firebase_uid = (auth.jwt() ->> 'sub')::text
    )
);

DROP POLICY IF EXISTS "Users can delete their own posts" ON posts;
CREATE POLICY "Users can delete their own posts"
ON posts FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = posts.author_id 
        AND firebase_uid = (auth.jwt() ->> 'sub')::text
    )
);


-- 3. Comments
DROP POLICY IF EXISTS "Users can insert their own comments" ON comments;
CREATE POLICY "Users can insert their own comments"
ON comments FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = comments.author_id 
        AND firebase_uid = (auth.jwt() ->> 'sub')::text
    )
);

DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;
CREATE POLICY "Users can delete their own comments"
ON comments FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = comments.author_id 
        AND firebase_uid = (auth.jwt() ->> 'sub')::text
    )
);


-- 4. Storage
DO $$
BEGIN
  -- Update Avatars Policy
  IF EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can upload Avatars') THEN
     DROP POLICY "Users can upload Avatars" ON storage.objects;
  END IF;

  CREATE POLICY "Users can upload Avatars" 
  ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'avatars' AND (auth.jwt() ->> 'sub') IS NOT NULL);

  
  -- Update Feed Media Policy
  IF EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can upload Feed Media') THEN
     DROP POLICY "Users can upload Feed Media" ON storage.objects;
  END IF;

  CREATE POLICY "Users can upload Feed Media" 
  ON storage.objects FOR INSERT 
  WITH CHECK (bucket_id = 'feed_media' AND (auth.jwt() ->> 'sub') IS NOT NULL);

END $$;
