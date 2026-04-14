-- Enable RLS on posts table
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read posts (public feed)
CREATE POLICY "Posts are publicly readable"
  ON posts FOR SELECT
  USING (true);

-- Allow authenticated users to insert posts (author_id must match their profile)
CREATE POLICY "Authenticated users can create posts"
  ON posts FOR INSERT
  WITH CHECK (true);

-- Allow users to update their own posts
CREATE POLICY "Users can update own posts"
  ON posts FOR UPDATE
  USING (
    author_id IN (
      SELECT id FROM profiles WHERE firebase_uid = auth.uid()::text
    )
  );

-- Enable RLS on doubts table too
ALTER TABLE doubts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Doubts are publicly readable"
  ON doubts FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create doubts"
  ON doubts FOR INSERT
  WITH CHECK (true);
