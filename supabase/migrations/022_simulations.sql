-- ============================================================
-- VERASSO Schema — Part 22: Simulations
-- ============================================================
-- 1. Extend posts table to support simulation data
ALTER TABLE public.posts
ADD COLUMN IF NOT EXISTS simulation_data JSONB DEFAULT NULL;
-- 2. Update type constraint to include 'simulation'
-- We have to drop and recreate the constraint to modify the enum-like check
DO $$ BEGIN
ALTER TABLE public.posts DROP CONSTRAINT IF EXISTS posts_type_check;
ALTER TABLE public.posts
ADD CONSTRAINT posts_type_check CHECK (
        type IN ('text', 'media', 'poll', 'audio', 'simulation')
    );
EXCEPTION
WHEN undefined_object THEN -- If constraint name is different, we handle it or rely on the ADD
NULL;
END $$;