-- ==========================================
-- VERIFICATION QUERIES
-- Run these AFTER applying the security lockdown migration
-- to confirm everything applied correctly.
-- ==========================================

-- 1. Check that critical tables exist
SELECT tablename FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('post_likes', 'story_likes', 'story_replies', 'quest_completions', 'post_saves')
ORDER BY tablename;

-- 2. Check that RPCs exist
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_friend_suggestions', 'add_sidequest_xp', 'check_username_availability', 'delete_post_safe')
ORDER BY routine_name;

-- 3. Check RLS is enabled on all critical tables
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('profiles', 'posts', 'comments', 'follows', 'messages', 'doubts', 'quest_completions', 'post_saves', 'post_likes')
ORDER BY tablename;

-- 4. Check unique constraints exist
SELECT conname, conrelid::regclass 
FROM pg_constraint 
WHERE contype = 'u' 
AND conrelid::regclass::text IN ('post_likes', 'post_saves')
ORDER BY conname;

-- 5. Check storage bucket limits
SELECT id, file_size_limit, allowed_mime_types 
FROM storage.buckets 
WHERE id IN ('avatars', 'feed_media', 'quest-photos');

-- 6. Check pg_cron cleanup job exists
SELECT jobid, schedule, command FROM cron.job WHERE jobname = 'cleanup_action_logs';
