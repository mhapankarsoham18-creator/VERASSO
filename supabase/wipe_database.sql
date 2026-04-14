-- ==========================================
-- VERASSO FULL DATABASE WIPE SCRIPT
-- ==========================================
-- WARNING: This will permanently delete ALL user data, posts, messages,
-- sidequests, and storage bucket files. 
-- Schema and tables will remain intact.

DO $$
BEGIN
  -- Disable triggers temporarily to prevent foreign key constraint issues during TRUNCATE
  SET session_replication_role = 'replica';

  -- Truncate all custom tables cascade safely
  DECLARE
    t_name text;
    tables text[] := ARRAY[
      'profiles', 'posts', 'doubts', 'follows', 'follow_requests', 
      'quest_completions', 'conversations', 'messages', 'comments', 
      'post_saves', 'poll_votes', 'user_badges', 'doubt_answers'
    ];
  BEGIN
    FOREACH t_name IN ARRAY tables
    LOOP
      IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = t_name) THEN
        EXECUTE 'TRUNCATE TABLE public.' || quote_ident(t_name) || ' CASCADE';
      END IF;
    END LOOP;
  END;

  -- Delete all files from storage buckets (avatars, feed_media, quest-photos)
  -- This inherently removes the physical S3 objects via Supabase internal triggers
  DELETE FROM storage.objects;

  -- Re-enable triggers
  SET session_replication_role = 'origin';

END $$;
