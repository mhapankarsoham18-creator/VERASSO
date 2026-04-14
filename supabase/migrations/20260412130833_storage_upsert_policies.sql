-- Storage UPDATE policies for upsert capability
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can update Avatars') THEN
    CREATE POLICY "Users can update Avatars" 
    ON storage.objects FOR UPDATE USING ( bucket_id = 'avatars' );
  END IF;

  IF NOT EXISTS (SELECT FROM pg_policies WHERE policyname = 'Users can update Feed Media') THEN
    CREATE POLICY "Users can update Feed Media" 
    ON storage.objects FOR UPDATE USING ( bucket_id = 'feed_media' );
  END IF;
END $$;
