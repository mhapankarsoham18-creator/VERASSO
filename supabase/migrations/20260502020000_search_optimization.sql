-- Migration: Search Optimization and Username Availability
-- Description: Enables Trigram indexes for fast search and dedicated RPCs for 2B+ user scale

-- 1. Enable Trigram extension for fuzzy/substring search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Create optimized indexes
-- GIN Trigram index for substring search (ilike '%query%')
CREATE INDEX IF NOT EXISTS idx_profiles_username_trgm ON public.profiles USING gin (username gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_profiles_display_name_trgm ON public.profiles USING gin (display_name gin_trgm_ops);

-- Lowercase unique index for case-insensitive availability checks
-- (Already unique from previous migration, but this ensures fast case-insensitive lookups)
CREATE INDEX IF NOT EXISTS idx_profiles_username_lower ON public.profiles (lower(username));

-- 3. Create RPC for extremely fast username availability check
CREATE OR REPLACE FUNCTION check_username_availability(target_username text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 
        FROM public.profiles 
        WHERE lower(username) = lower(target_username)
    );
END;
$$;

-- 4. Create RPC for optimized multi-column search with relevance scoring
-- Prioritizes exact matches, then high similarity
CREATE OR REPLACE FUNCTION search_profiles(search_query text, limit_val int DEFAULT 20)
RETURNS TABLE (
    id uuid,
    username text,
    display_name text,
    avatar_url text,
    role text,
    similarity_score float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.username,
        p.display_name,
        p.avatar_url,
        p.role,
        similarity(p.username, search_query) as similarity_score
    FROM public.profiles p
    WHERE 
        p.username % search_query OR 
        p.display_name % search_query OR
        p.username ILIKE '%' || search_query || '%' OR
        p.display_name ILIKE '%' || search_query || '%'
    ORDER BY 
        (p.username = search_query) DESC,             -- Exact username match first
        (p.display_name = search_query) DESC,         -- Exact display name match second
        similarity_score DESC                         -- Then highest similarity
    LIMIT limit_val;
END;
$$;
