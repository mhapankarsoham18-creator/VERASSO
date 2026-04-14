-- Add fcm_token to profiles for real push notifications
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token text;

-- Create doubt_answers table
CREATE TABLE IF NOT EXISTS doubt_answers (
  id uuid primary key default gen_random_uuid(),
  doubt_id uuid references doubts(id) on delete cascade,
  author_id uuid references profiles(id) on delete cascade,
  content text not null,
  is_accepted boolean default false,
  created_at timestamptz default now()
);

-- Enable RLS
ALTER TABLE doubt_answers ENABLE ROW LEVEL SECURITY;

-- Read policy: Anyone can see answers
CREATE POLICY "Anyone can view doubt answers" 
  ON doubt_answers FOR SELECT 
  USING (true);

-- Insert policy: Authenticated users can answer
CREATE POLICY "Users can create doubt answers" 
  ON doubt_answers FOR INSERT 
  WITH CHECK (auth.uid() = author_id);

-- Update policy: Only the *author of the original doubt* can accept an answer
CREATE POLICY "Only doubt author can accept answers" 
  ON doubt_answers FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM doubts 
      WHERE doubts.id = doubt_answers.doubt_id 
      AND doubts.author_id = auth.uid()
    )
  );

-- Delete policy: Authors can delete their own answers
CREATE POLICY "Users can delete their own answers"
  ON doubt_answers FOR DELETE
  USING (auth.uid() = author_id);

-- Trigger logic for accepting an answer
CREATE OR REPLACE FUNCTION on_answer_accepted()
RETURNS trigger AS $$
DECLARE
  answer_author uuid;
  current_trust float;
  current_badges text[];
BEGIN
  -- We only fire if is_accepted is changing from false to true
  IF NEW.is_accepted = true AND OLD.is_accepted = false THEN

    -- 1. Mark the parent doubt as solved
    UPDATE doubts SET solved = true WHERE id = NEW.doubt_id;

    -- 2. Award Trust Score & Badges to the person who answered
    answer_author := NEW.author_id;

    -- We do not award points if you answer your own doubt
    IF EXISTS (SELECT 1 FROM doubts WHERE id = NEW.doubt_id AND author_id != answer_author) THEN
      
      -- Add 10 points
      UPDATE profiles 
      SET trust_score = trust_score + 10 
      WHERE id = answer_author
      RETURNING trust_score, badges INTO current_trust, current_badges;

      -- Give Helper Badge if score >= 50
      IF current_trust >= 50 AND NOT ('Helper' = ANY(COALESCE(current_badges, '{}'::text[]))) THEN
        UPDATE profiles SET badges = array_append(COALESCE(badges, '{}'::text[]), 'Helper') WHERE id = answer_author;
      END IF;

      -- Give Scholar Badge if score >= 100
      IF current_trust >= 100 AND NOT ('Scholar' = ANY(COALESCE(current_badges, '{}'::text[]))) THEN
        UPDATE profiles SET badges = array_append(COALESCE(badges, '{}'::text[]), 'Scholar') WHERE id = answer_author;
      END IF;

    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS answer_accepted_trigger ON doubt_answers;
CREATE TRIGGER answer_accepted_trigger
  AFTER UPDATE OF is_accepted ON doubt_answers
  FOR EACH ROW
  EXECUTE FUNCTION on_answer_accepted();
