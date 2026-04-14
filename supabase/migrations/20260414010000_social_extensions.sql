-- PHASE 3: SOCIAL EXTENSIONS & GAMIFICATION

-- 1. Comments Table
CREATE TABLE IF NOT EXISTS comments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    author_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    parent_comment_id uuid REFERENCES comments(id) ON DELETE CASCADE, -- For threaded comments
    content text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 2. Post Collections (Saves)
CREATE TABLE IF NOT EXISTS post_saves (
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    saved_at timestamptz DEFAULT now(),
    PRIMARY KEY (user_id, post_id)
);

-- 3. Polls Integration (Extension to posts)
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS poll_data JSONB, -- e.g. {"options": ["Option A", "Option B"]}
ADD COLUMN IF NOT EXISTS has_math boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS attachments JSONB; -- array of media URLs

-- 4. Poll Votes
CREATE TABLE IF NOT EXISTS poll_votes (
    post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    option_index int NOT NULL,
    voted_at timestamptz DEFAULT now(),
    PRIMARY KEY (post_id, user_id)
);

-- 5. Gamification (Badges)
CREATE TABLE IF NOT EXISTS user_badges (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    badge_name text NOT NULL, -- e.g. "Curious Pioneer", "Helpful Coder"
    awarded_at timestamptz DEFAULT now()
);

-- 6. RLS Policies
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_saves ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Comments are public" ON comments;
CREATE POLICY "Comments are public" ON comments FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can insert comments" ON comments;
CREATE POLICY "Users can insert comments" ON comments FOR INSERT WITH CHECK (auth.uid() = author_id);
DROP POLICY IF EXISTS "Users can delete own comments" ON comments;
CREATE POLICY "Users can delete own comments" ON comments FOR DELETE USING (auth.uid() = author_id);

DROP POLICY IF EXISTS "Users can see own saves" ON post_saves;
CREATE POLICY "Users can see own saves" ON post_saves FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can save posts" ON post_saves;
CREATE POLICY "Users can save posts" ON post_saves FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can unsave posts" ON post_saves;
CREATE POLICY "Users can unsave posts" ON post_saves FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Poll votes are public" ON poll_votes;
CREATE POLICY "Poll votes are public" ON poll_votes FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can vote" ON poll_votes;
CREATE POLICY "Users can vote" ON poll_votes FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Badges are public" ON user_badges;
CREATE POLICY "Badges are public" ON user_badges FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users cannot insert badges" ON user_badges;
CREATE POLICY "Users cannot insert badges" ON user_badges FOR INSERT WITH CHECK (false);
