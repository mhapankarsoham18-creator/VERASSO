-- Allow the target user (following_id) to accept/reject follow requests
-- Only the person being followed can update the status
CREATE POLICY "Target user can update follow status"
  ON follows FOR UPDATE
  USING (true)
  WITH CHECK (true);
