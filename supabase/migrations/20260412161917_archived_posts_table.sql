-- Archive bucket for posts from deleted accounts
-- When a user deletes their account, their posts are moved here
-- so the username becomes available for new users
CREATE TABLE IF NOT EXISTS archived_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  original_post_id UUID,
  original_author_username TEXT,
  original_author_display_name TEXT,
  type TEXT DEFAULT 'text',
  content TEXT,
  media_url TEXT,
  likes INT DEFAULT 0,
  original_created_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE archived_posts ENABLE ROW LEVEL SECURITY;

-- Only admins can read archived posts (not public)
CREATE POLICY "Archived posts are admin-only"
  ON archived_posts FOR SELECT
  USING (false);

-- Create a function that archives posts before a profile is deleted
CREATE OR REPLACE FUNCTION archive_user_posts()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO archived_posts (original_post_id, original_author_username, original_author_display_name, type, content, media_url, likes, original_created_at)
  SELECT id, OLD.username, OLD.display_name, p.type, p.content, p.media_url, p.likes, p.created_at
  FROM posts p
  WHERE p.author_id = OLD.id;
  
  -- Delete the user's posts (freeing the data from live feed)
  DELETE FROM posts WHERE author_id = OLD.id;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger: runs BEFORE a profile row is deleted
CREATE TRIGGER trigger_archive_posts_on_profile_delete
  BEFORE DELETE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION archive_user_posts();
