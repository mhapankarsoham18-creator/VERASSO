-- ============================================================
-- VERASSO Schema — Part 7: Recommendation & Search RPCs
-- Collaborative filtering, Discovery, and Search
-- ============================================================

-- 1. Get Recommended Posts
-- Collaborative Filtering: Find posts liked by users who liked the same posts as you
CREATE OR REPLACE FUNCTION get_recommended_posts(p_user_id UUID, p_limit INT DEFAULT 10)
RETURNS SETOF public.posts AS $$
BEGIN
    RETURN QUERY
    WITH personal_likes AS (
        SELECT post_id FROM public.likes WHERE user_id = p_user_id AND post_id IS NOT NULL
    ),
    similar_users AS (
        SELECT l2.user_id, count(*) as common_likes
        FROM public.likes l1
        JOIN public.likes l2 ON l1.post_id = l2.post_id
        WHERE l1.user_id = p_user_id AND l2.user_id != p_user_id
        GROUP BY l2.user_id
        ORDER BY common_likes DESC
        LIMIT 20
    )
    SELECT p.*
    FROM public.posts p
    JOIN public.likes l ON p.id = l.post_id
    WHERE l.user_id IN (SELECT su.user_id FROM similar_users su)
      AND p.id NOT IN (SELECT pl.post_id FROM personal_likes pl)
      AND p.user_id != p_user_id
    GROUP BY p.id
    ORDER BY count(*) DESC, p.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Get Recommended Users to Follow
-- Friend of Friend: Recommend users followed by people you follow
CREATE OR REPLACE FUNCTION get_recommended_users(p_user_id UUID, p_limit INT DEFAULT 5)
RETURNS SETOF public.profiles AS $$
BEGIN
    RETURN QUERY
    WITH my_following AS (
        SELECT following_id FROM public.user_following WHERE follower_id = p_user_id
    ),
    friend_of_friends AS (
        SELECT f2.following_id, count(*) as follow_count
        FROM public.user_following f1
        JOIN public.user_following f2 ON f1.following_id = f2.follower_id
        WHERE f1.follower_id = p_user_id
          AND f2.following_id != p_user_id
          AND f2.following_id NOT IN (SELECT m.following_id FROM my_following m)
        GROUP BY f2.following_id
    )
    SELECT pr.*
    FROM public.profiles pr
    JOIN friend_of_friends fof ON pr.id = fof.following_id
    ORDER BY fof.follow_count DESC, pr.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Search Posts
-- Basic text search across content and subject
CREATE OR REPLACE FUNCTION search_posts(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS SETOF public.posts AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.posts
    WHERE content ILIKE '%' || p_query || '%'
       OR subject ILIKE '%' || p_query || '%'
    ORDER BY created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Search Users
CREATE OR REPLACE FUNCTION search_users(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS SETOF public.profiles AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.profiles
    WHERE username ILIKE '%' || p_query || '%'
       OR full_name ILIKE '%' || p_query || '%'
    ORDER BY trust_score DESC, created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. General Feed Pagination
-- Returns latest posts from users you follow + top recent public posts
CREATE OR REPLACE FUNCTION get_feed(p_user_id UUID, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS SETOF public.posts AS $$
BEGIN
    RETURN QUERY
    SELECT p.*
    FROM public.posts p
    LEFT JOIN public.user_following f ON p.user_id = f.following_id AND f.follower_id = p_user_id
    WHERE p.is_personal = false
    ORDER BY 
        (f.id IS NOT NULL) DESC, -- Following first
        p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
