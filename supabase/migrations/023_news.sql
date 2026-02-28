-- ============================================================
-- VERASSO Schema — Part 23: News & Current Events
-- ============================================================
CREATE TABLE public.news (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    author_id UUID REFERENCES public.profiles(id) ON DELETE
    SET NULL,
        title TEXT NOT NULL,
        description TEXT,
        content JSONB DEFAULT '{}',
        subject TEXT DEFAULT 'General',
        article_type TEXT DEFAULT 'concept_explainer',
        audience_type TEXT DEFAULT 'All',
        category TEXT NOT NULL,
        image_url TEXT,
        source TEXT,
        importance INT DEFAULT 1,
        -- 1 (Low) to 5 (Urgent/Critical)
        reading_time INT DEFAULT 5,
        is_published BOOLEAN DEFAULT true,
        is_featured BOOLEAN DEFAULT false,
        upvotes_count INT DEFAULT 0,
        comments_count INT DEFAULT 0,
        featured_at TIMESTAMPTZ,
        created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
        updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.news ENABLE ROW LEVEL SECURITY;
CREATE POLICY "News is viewable by everyone" ON public.news FOR
SELECT USING (true);
-- Indexing for performance
CREATE INDEX idx_news_category ON public.news(category);
CREATE INDEX idx_news_importance ON public.news(importance DESC, created_at DESC);