-- =========================================================================
-- VERASSO Production Storage Buckets
-- Sets up the optimized storage buckets and their respective RLS policies
-- =========================================================================
-- Profile avatars bucket
INSERT INTO storage.buckets (
        id,
        name,
        public,
        file_size_limit,
        allowed_mime_types
    )
VALUES (
        'avatars',
        'avatars',
        true,
        5242880,
        ARRAY ['image/jpeg', 'image/png', 'image/webp']
    );
-- Post media bucket
INSERT INTO storage.buckets (
        id,
        name,
        public,
        file_size_limit,
        allowed_mime_types
    )
VALUES (
        'post-media',
        'post-media',
        true,
        52428800,
        ARRAY ['image/jpeg', 'image/png', 'image/webp', 'video/mp4']
    );
-- Story media bucket
INSERT INTO storage.buckets (
        id,
        name,
        public,
        file_size_limit,
        allowed_mime_types
    )
VALUES (
        'stories',
        'stories',
        true,
        52428800,
        ARRAY ['image/jpeg', 'image/png', 'image/webp', 'video/mp4']
    );
-- Chat attachments (private bucket)
INSERT INTO storage.buckets (
        id,
        name,
        public,
        file_size_limit,
        allowed_mime_types
    )
VALUES (
        'chat-attachments',
        'chat-attachments',
        false,
        20971520,
        ARRAY ['image/jpeg', 'image/png', 'application/pdf']
    );
-- Course content bucket
INSERT INTO storage.buckets (
        id,
        name,
        public,
        file_size_limit,
        allowed_mime_types
    )
VALUES (
        'course-content',
        'course-content',
        false,
        104857600,
        ARRAY ['video/mp4', 'application/pdf', 'image/jpeg', 'image/png']
    );
-- Storage RLS policies
CREATE POLICY "Avatar upload" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (
        bucket_id = 'avatars'
        AND (storage.foldername(name)) [1] = auth.uid()::text
    );
CREATE POLICY "Avatar public read" ON storage.objects FOR
SELECT TO public USING (bucket_id = 'avatars');
CREATE POLICY "Post media upload" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (
        bucket_id = 'post-media'
        AND (storage.foldername(name)) [1] = auth.uid()::text
    );
CREATE POLICY "Post media public read" ON storage.objects FOR
SELECT TO public USING (bucket_id = 'post-media');
CREATE POLICY "Story media upload" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (
        bucket_id = 'stories'
        AND (storage.foldername(name)) [1] = auth.uid()::text
    );
CREATE POLICY "Story media public read" ON storage.objects FOR
SELECT TO public USING (bucket_id = 'stories');
CREATE POLICY "Chat attachments upload" ON storage.objects FOR
INSERT TO authenticated WITH CHECK (bucket_id = 'chat-attachments');