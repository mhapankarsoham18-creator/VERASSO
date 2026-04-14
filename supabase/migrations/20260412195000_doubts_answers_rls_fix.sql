-- Drop the restrictive policies from the previous migration that relied on auth.uid()
DROP POLICY IF EXISTS "Users can create doubt answers" ON doubt_answers;
DROP POLICY IF EXISTS "Only doubt author can accept answers" ON doubt_answers;
DROP POLICY IF EXISTS "Users can delete their own answers" ON doubt_answers;

-- Create application-trusted open policies for Phase 2 (Since auth validation happens on Flutter client via Firebase)
CREATE POLICY "Users can create doubt answers" 
  ON doubt_answers FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "Users can update and accept answers" 
  ON doubt_answers FOR UPDATE 
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can delete their own answers"
  ON doubt_answers FOR DELETE
  USING (true);
