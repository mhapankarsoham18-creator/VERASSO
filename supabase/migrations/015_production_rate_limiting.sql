-- ============================================================
-- VERASSO — Production Rate Limiting Config
-- Adjusting thresholds for public traffic
-- ============================================================
-- 1. Ensure endpoint_pattern is unique for ON CONFLICT to work
ALTER TABLE public.rate_limit_rules
ADD CONSTRAINT unique_endpoint_pattern UNIQUE (endpoint_pattern);
-- 2. Increase global limits for typical usage
-- Default was 120/min per IP/User
UPDATE public.rate_limit_rules
SET max_requests = 300,
    window_seconds = 60,
    block_duration_seconds = 60
WHERE endpoint_pattern = '/%';
-- 2. Stricter limits for expensive or sensitive operations
-- Authentication: 5 attempts per 10 minutes
UPDATE public.rate_limit_rules
SET max_requests = 5,
    window_seconds = 600,
    block_duration_seconds = 3600 -- 1 hour block for brute force
WHERE endpoint_pattern = '/auth/%';
-- 3. Social Posting limits: 10/min
INSERT INTO public.rate_limit_rules (
        endpoint_pattern,
        max_requests,
        window_seconds,
        block_duration_seconds
    )
VALUES ('/rest/v1/posts%', 10, 60, 300) ON CONFLICT (endpoint_pattern) DO
UPDATE
SET max_requests = EXCLUDED.max_requests,
    window_seconds = EXCLUDED.window_seconds;
-- 4. Messaging limits: 30/min
INSERT INTO public.rate_limit_rules (
        endpoint_pattern,
        max_requests,
        window_seconds,
        block_duration_seconds
    )
VALUES ('/rest/v1/messages%', 30, 60, 60) ON CONFLICT (endpoint_pattern) DO
UPDATE
SET max_requests = EXCLUDED.max_requests,
    window_seconds = EXCLUDED.window_seconds;
-- 5. RPC (Function) limits: 20/min
INSERT INTO public.rate_limit_rules (
        endpoint_pattern,
        max_requests,
        window_seconds,
        block_duration_seconds
    )
VALUES ('/rpc/%', 20, 60, 300) ON CONFLICT (endpoint_pattern) DO
UPDATE
SET max_requests = EXCLUDED.max_requests,
    window_seconds = EXCLUDED.window_seconds;