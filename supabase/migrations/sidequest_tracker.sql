-- 1. Safely add Badges and Sidequest tracker columns to the 'profiles' table
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS badges text[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS sidequest_xp int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS sidequest_title text DEFAULT 'Wanderer',
  ADD COLUMN IF NOT EXISTS sidequest_streak int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_quest_date date;

-- 2. Safely Create the missing 'quest_completions' table
CREATE TABLE IF NOT EXISTS public.quest_completions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  quest_id text NOT NULL,
  photo_url text NOT NULL,
  xp_awarded int NOT NULL,
  completed_at timestamptz DEFAULT now()
);

-- 3. Prevent the same quest from being completed twice in one day
-- FIXED: Using AT TIME ZONE 'UTC' makes this expression IMMUTABLE in Postgres!
CREATE UNIQUE INDEX IF NOT EXISTS uq_quest_daily
  ON public.quest_completions (profile_id, quest_id, ((completed_at AT TIME ZONE 'UTC')::date));

-- 4. Create the automated Server-Side XP & Streak calculation function
CREATE OR REPLACE FUNCTION public.add_sidequest_xp(p_profile_id uuid, p_xp int)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.profiles 
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

-- 5. Establish the 'quest-photos' Storage Bucket & RLS Policies securely
DO $$ 
BEGIN
  -- Create bucket
  IF NOT EXISTS (SELECT FROM storage.buckets WHERE id = 'quest-photos') THEN
    INSERT INTO storage.buckets (id, name, public) VALUES ('quest-photos', 'quest-photos', true);
  END IF;

  -- Add public read policy
  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Quest Photos are publicly accessible.' AND tablename = 'objects' AND schemaname = 'storage') THEN
    EXECUTE 'CREATE POLICY "Quest Photos are publicly accessible." ON storage.objects FOR SELECT USING ( bucket_id = ''quest-photos'' )';
  END IF;

  -- Add user upload policy
  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can upload Quest Photos' AND tablename = 'objects' AND schemaname = 'storage') THEN
    EXECUTE 'CREATE POLICY "Users can upload Quest Photos" ON storage.objects FOR INSERT WITH CHECK ( bucket_id = ''quest-photos'' )';
  END IF;
END $$;
