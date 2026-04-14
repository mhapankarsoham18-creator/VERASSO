-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid primary key default gen_random_uuid(),
  firebase_uid text unique not null,
  email text,
  username text,
  display_name text,
  avatar_url text,
  bio text,
  institute text,
  role text default 'student',
  badges text[],
  trust_score float default 0,
  zk_verified boolean default false,
  mesh_relay_mode text default 'full',
  created_at timestamptz default now()
);

-- Ensure the email column exists in case the table was created before Phase 2 schema update
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email text;

-- 2. Posts Table (The Feed)
CREATE TABLE IF NOT EXISTS posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references profiles(id),
  type text, -- video | image | audio | gif | text
  content text, 
  media_url text, 
  subject text,
  chapter text,
  exam_tags text[],
  likes int default 0,
  created_at timestamptz default now()
);

-- 3. Doubts Table
CREATE TABLE IF NOT EXISTS doubts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid references profiles(id),
  title text,
  body text,
  subject text,
  tags text[],
  solved boolean default false,
  created_at timestamptz default now()
);

-- 4. Avatars Storage Bucket Initialization
-- Using plpgsql DO block to safely insert only if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM storage.buckets WHERE id = 'avatars') THEN
    INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Avatar Images are publicly accessible.') THEN
    CREATE POLICY "Avatar Images are publicly accessible." 
    ON storage.objects FOR SELECT USING ( bucket_id = 'avatars' );
  END IF;

  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can upload Avatars') THEN
    CREATE POLICY "Users can upload Avatars" 
    ON storage.objects FOR INSERT WITH CHECK ( bucket_id = 'avatars' );
  END IF;
END $$;

-- 5. Global Content Storage Bucket
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM storage.buckets WHERE id = 'feed_media') THEN
    INSERT INTO storage.buckets (id, name, public) VALUES ('feed_media', 'feed_media', true);
  END IF;

  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Feed Media is publicly accessible.') THEN
    CREATE POLICY "Feed Media is publicly accessible." 
    ON storage.objects FOR SELECT USING ( bucket_id = 'feed_media' );
  END IF;

  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can upload Feed Media') THEN
    CREATE POLICY "Users can upload Feed Media" 
    ON storage.objects FOR INSERT WITH CHECK ( bucket_id = 'feed_media' );
  END IF;
END $$;
