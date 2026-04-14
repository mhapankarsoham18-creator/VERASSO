-- Function to resolve a 1-on-1 conversation ID between current user and another user
CREATE OR REPLACE FUNCTION get_private_conversation(other_user_id UUID)
RETURNS TABLE (id UUID) AS $$
DECLARE
    me_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT c.id
    FROM conversations c
    JOIN conversation_participants p1 ON c.id = p1.conversation_id
    JOIN conversation_participants p2 ON c.id = p2.conversation_id
    WHERE c.is_group = false
      AND p1.user_id = me_id
      AND p2.user_id = other_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
