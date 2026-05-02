-- Migration: API Rate Limiting for Social & Messaging Endpoints
-- Description: Implements identity-based rate limiting to prevent spam and abuse

-- 1. Create an unlogged table for high-performance action logging
CREATE UNLOGGED TABLE IF NOT EXISTS user_action_logs (
    id bigint generated always as identity primary key,
    user_id uuid not null,
    action_type text not null,
    created_at timestamp with time zone default now()
);

-- Index for fast counts
CREATE INDEX IF NOT EXISTS idx_user_action_logs_user_time 
ON user_action_logs(user_id, action_type, created_at);

-- 2. Create the rate limiting function
CREATE OR REPLACE FUNCTION check_rate_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_count int;
    max_requests int := 20; -- default max requests per minute
    time_window interval := '1 minute'::interval;
    action_name text := TG_TABLE_NAME;
BEGIN
    -- Only apply rate limit to authenticated users
    IF auth.uid() IS NULL THEN
        RETURN NEW;
    END IF;

    -- Adjust limits based on action
    IF action_name = 'posts' THEN
        max_requests := 5; -- 5 posts per minute
    ELSIF action_name = 'comments' THEN
        max_requests := 15; -- 15 comments per minute
    ELSIF action_name = 'messages' THEN
        max_requests := 30; -- 30 messages per minute
    END IF;

    -- Count recent actions
    SELECT COUNT(*) INTO request_count
    FROM user_action_logs
    WHERE user_id = auth.uid()
      AND action_type = action_name
      AND created_at > now() - time_window;

    IF request_count >= max_requests THEN
        RAISE EXCEPTION 'Rate limit exceeded for %', action_name USING ERRCODE = '42900';
    END IF;

    -- Log the new action
    INSERT INTO user_action_logs (user_id, action_type)
    VALUES (auth.uid(), action_name);

    RETURN NEW;
END;
$$;

-- 3. Apply triggers to critical tables
DROP TRIGGER IF EXISTS rate_limit_posts ON posts;
CREATE TRIGGER rate_limit_posts
    BEFORE INSERT ON posts
    FOR EACH ROW
    EXECUTE FUNCTION check_rate_limit();

DROP TRIGGER IF EXISTS rate_limit_comments ON comments;
CREATE TRIGGER rate_limit_comments
    BEFORE INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION check_rate_limit();

DROP TRIGGER IF EXISTS rate_limit_messages ON messages;
CREATE TRIGGER rate_limit_messages
    BEFORE INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION check_rate_limit();

-- 4. Function to periodically clean up old logs
CREATE OR REPLACE FUNCTION cleanup_action_logs()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM user_action_logs WHERE created_at < now() - interval '1 hour';
END;
$$;
