-- ==========================================
-- STORIES SCHEMA & POLICIES
-- ==========================================

CREATE TABLE IF NOT EXISTS public.stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    media_url TEXT,
    media_type TEXT CHECK (media_type IN ('text', 'image', 'video', 'audio')),
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours')
);

-- Enable RLS
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;

-- 1. Anyone can view valid stories
DROP POLICY IF EXISTS "Anyone can view stories" ON public.stories;
CREATE POLICY "Anyone can view stories"
ON public.stories FOR SELECT
USING (true);

-- 2. Users can insert their own stories
DROP POLICY IF EXISTS "Users can insert their own stories" ON public.stories;
CREATE POLICY "Users can insert their own stories"
ON public.stories FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = stories.author_id 
        AND firebase_uid = (auth.jwt() ->> 'sub')::text
    )
);

-- 3. Users can delete their own stories
DROP POLICY IF EXISTS "Users can delete their own stories" ON public.stories;
CREATE POLICY "Users can delete their own stories"
ON public.stories FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = stories.author_id 
        AND firebase_uid = (auth.jwt() ->> 'sub')::text
    )
);

-- Create an index on expires_at and author_id to optimize the stories query
CREATE INDEX IF NOT EXISTS idx_stories_expires_author ON public.stories (author_id, expires_at);
