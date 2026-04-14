-- 1. Add Sidequest fields to profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS sidequest_xp int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sidequest_title text DEFAULT 'Wanderer',
  ADD COLUMN IF NOT EXISTS sidequest_streak int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_quest_date date;

-- 2. Quest completions table
CREATE TABLE IF NOT EXISTS quest_completions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  quest_id text NOT NULL,
  photo_url text NOT NULL,
  xp_awarded int NOT NULL,
  completed_at timestamptz DEFAULT now()
);

-- Prevent same quest completed twice in one day
CREATE UNIQUE INDEX IF NOT EXISTS uq_quest_daily
  ON quest_completions (profile_id, quest_id, (completed_at::date));

-- 3. XP & Streak increment function
CREATE OR REPLACE FUNCTION add_sidequest_xp(p_profile_id uuid, p_xp int)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE profiles 
  SET sidequest_xp = sidequest_xp + p_xp,
      sidequest_streak = CASE 
        WHEN last_quest_date = CURRENT_DATE THEN sidequest_streak
        WHEN last_quest_date = CURRENT_DATE - INTERVAL '1 day' THEN sidequest_streak + 1
        ELSE 1
      END,
      last_quest_date = CURRENT_DATE
  WHERE id = p_profile_id;
END;
$$;

-- 4. Storage Bucket
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM storage.buckets WHERE id = 'quest-photos') THEN
    INSERT INTO storage.buckets (id, name, public) VALUES ('quest-photos', 'quest-photos', true);
  END IF;

  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Quest Photos are publicly accessible.') THEN
    CREATE POLICY "Quest Photos are publicly accessible." 
    ON storage.objects FOR SELECT USING ( bucket_id = 'quest-photos' );
  END IF;

  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can upload Quest Photos') THEN
    CREATE POLICY "Users can upload Quest Photos" 
    ON storage.objects FOR INSERT WITH CHECK ( bucket_id = 'quest-photos' );
  END IF;
END $$;
