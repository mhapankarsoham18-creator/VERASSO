-- ============================================================
-- VERASSO Schema — Part 24: Classroom & Labs
-- ============================================================
-- 1. Extend courses table with is_lab flag
-- This allows categorizing a course as a practical lab experience
ALTER TABLE public.courses
ADD COLUMN IF NOT EXISTS is_lab BOOLEAN DEFAULT false;
-- 2. Create labs table for specialized practical sessions
CREATE TABLE IF NOT EXISTS public.labs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    lab_data JSONB DEFAULT '{}',
    -- Tooling config, chemicals, virtual hardware, etc.
    requirements TEXT [],
    difficulty_level TEXT CHECK (
        difficulty_level IN ('Beginner', 'Intermediate', 'Advanced')
    ),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.labs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Labs viewable by all" ON public.labs FOR
SELECT USING (true);
-- Indexing
CREATE INDEX idx_courses_is_lab ON public.courses(is_lab)
WHERE is_lab = true;
CREATE INDEX idx_labs_course_id ON public.labs(course_id);