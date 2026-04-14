-- Follows relationship table
CREATE TABLE IF NOT EXISTS follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT no_self_follow CHECK (follower_id != following_id),
  CONSTRAINT unique_follow UNIQUE (follower_id, following_id)
);

-- Index for fast lookups
CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

-- RLS
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- Anyone can see who follows whom
CREATE POLICY "Follows are publicly readable"
  ON follows FOR SELECT
  USING (true);

-- Users can follow others
CREATE POLICY "Users can follow"
  ON follows FOR INSERT
  WITH CHECK (true);

-- Users can unfollow (delete their own follow rows)
CREATE POLICY "Users can unfollow"
  ON follows FOR DELETE
  USING (true);

-- Add follower/following counts to profiles for quick access
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS followers_count INT DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS following_count INT DEFAULT 0;

-- Realtime on follows
ALTER TABLE follows REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE follows;
