-- ============================================================
-- VERASSO Schema — Part 6: Additional RPC Functions
-- Geospatial queries, Heatmaps, and Utilities
-- ============================================================

-- 1. Get Nearby Users (PostGIS)
-- Returns users within X meters, ordered by distance
CREATE OR REPLACE FUNCTION get_nearby_users(
    lat DOUBLE PRECISION,
    long DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 5000
) RETURNS TABLE (
    id UUID,
    full_name TEXT,
    avatar_url TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    dist_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.full_name,
        p.avatar_url,
        ul.latitude,
        ul.longitude,
        ST_Distance(
            ul.location,
            ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography
        ) as dist_meters
    FROM public.user_locations ul
    JOIN public.profiles p ON ul.user_id = p.id
    WHERE ST_DWithin(
        ul.location,
        ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
        radius_meters
    )
    ORDER BY dist_meters ASC
    LIMIT 50;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Get Activity Heatmap
-- Returns simplified location points for heatmap visualization
CREATE OR REPLACE FUNCTION get_activity_heatmap(
    lat DOUBLE PRECISION,
    long DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION DEFAULT 10000
) RETURNS TABLE (
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    weight INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ul.latitude,
        ul.longitude,
        1 as weight -- Simple weight for now, could be dynamic based on activity
    FROM public.user_locations ul
    WHERE ST_DWithin(
        ul.location,
        ST_SetSRID(ST_MakePoint(long, lat), 4326)::geography,
        radius_meters
    )
    LIMIT 1000;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Increment Shared Counter (Generic Utility)
-- Useful for high-concurrency counters if triggers aren't enough
CREATE OR REPLACE FUNCTION increment_shared_counter(
    row_id UUID,
    table_name TEXT,
    column_name TEXT
) RETURNS VOID AS $$
BEGIN
    EXECUTE format('UPDATE public.%I SET %I = %I + 1 WHERE id = $1', table_name, column_name, column_name)
    USING row_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Decrement Shared Counter
CREATE OR REPLACE FUNCTION decrement_shared_counter(
    row_id UUID,
    table_name TEXT,
    column_name TEXT
) RETURNS VOID AS $$
BEGIN
    EXECUTE format('UPDATE public.%I SET %I = GREATEST(0, %I - 1) WHERE id = $1', table_name, column_name, column_name)
    USING row_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
