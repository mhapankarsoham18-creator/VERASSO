-- Configure Supabase Storage Buckets for Media, Videos, and PDF Notes

-- Create buckets (feed_media was used earlier, post_attachments for PDFs/videos)
INSERT INTO storage.buckets (id, name, public) 
VALUES 
  ('feed_media', 'feed_media', true),
  ('post_attachments', 'post_attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for feed_media (Images, general media)
CREATE POLICY "Public Access feed_media" ON storage.objects FOR SELECT USING ( bucket_id = 'feed_media' );
CREATE POLICY "Upload feed_media" ON storage.objects FOR INSERT WITH CHECK ( bucket_id = 'feed_media' AND auth.role() = 'authenticated' );
CREATE POLICY "Delete own feed_media" ON storage.objects FOR DELETE USING ( bucket_id = 'feed_media' AND auth.uid() = owner );

-- Policies for post_attachments (PDFs, Notes, Short Videos)
CREATE POLICY "Public Access post_attachments" ON storage.objects FOR SELECT USING ( bucket_id = 'post_attachments' );
CREATE POLICY "Upload post_attachments" ON storage.objects FOR INSERT WITH CHECK ( bucket_id = 'post_attachments' AND auth.role() = 'authenticated' );
CREATE POLICY "Delete own post_attachments" ON storage.objects FOR DELETE USING ( bucket_id = 'post_attachments' AND auth.uid() = owner );
