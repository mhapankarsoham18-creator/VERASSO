-- Allow users to delete their own posts
CREATE POLICY "Users can delete own posts"
  ON posts FOR DELETE
  USING (
    author_id IN (
      SELECT id FROM profiles WHERE firebase_uid = auth.uid()::text
    )
  );
