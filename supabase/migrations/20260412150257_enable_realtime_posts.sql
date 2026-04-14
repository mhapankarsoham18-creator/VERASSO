-- Enable full replica identity for realtime streaming
ALTER TABLE posts REPLICA IDENTITY FULL;

-- Add posts to supabase realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE posts;

-- Also enable realtime for profiles so avatar/name changes propagate
ALTER TABLE profiles REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
