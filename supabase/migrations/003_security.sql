-- ============================================================
-- VERASSO Schema — Part 3: Security Hardening
-- Rate limiting, auth sessions, bcrypt backup codes, audit log
-- ============================================================

-- Ensure pgcrypto is available (for bcrypt / gen_salt)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. RATE LIMITING
-- ============================================================
CREATE TABLE public.rate_limit_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    endpoint_pattern TEXT NOT NULL,
    max_requests INT NOT NULL DEFAULT 60,
    window_seconds INT NOT NULL DEFAULT 60,
    block_duration_seconds INT DEFAULT 300,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.api_rate_limits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ip_address INET,
    endpoint TEXT NOT NULL,
    request_count INT DEFAULT 1,
    window_start TIMESTAMPTZ DEFAULT now(),
    last_request TIMESTAMPTZ DEFAULT now(),
    is_blocked BOOLEAN DEFAULT false,
    blocked_until TIMESTAMPTZ
);

CREATE INDEX idx_rate_limits_lookup ON public.api_rate_limits(user_id, endpoint, window_start);
CREATE INDEX idx_rate_limits_ip ON public.api_rate_limits(ip_address, endpoint);

ALTER TABLE public.rate_limit_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_rate_limits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Rules viewable" ON public.rate_limit_rules FOR SELECT USING (true);
CREATE POLICY "Own rate limits" ON public.api_rate_limits FOR SELECT USING (auth.uid() = user_id);

-- Default rate limit rules
INSERT INTO public.rate_limit_rules (endpoint_pattern, max_requests, window_seconds, block_duration_seconds) VALUES
    ('/auth/%', 10, 60, 900),       -- Auth: 10 req/min, 15min block
    ('/rest/v1/posts%', 30, 60, 300),  -- Posts: 30 req/min
    ('/rest/v1/messages%', 60, 60, 120), -- Messages: 60 req/min
    ('/storage/%', 20, 60, 300),     -- Storage: 20 req/min
    ('/%', 120, 60, 60)              -- Global fallback: 120 req/min
ON CONFLICT DO NOTHING;

-- Rate limit check function
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_user_id UUID,
    p_ip_address INET,
    p_endpoint TEXT
) RETURNS JSONB AS $$
DECLARE
    v_rule RECORD;
    v_limit RECORD;
    v_window_start TIMESTAMPTZ;
BEGIN
    -- Find matching rule
    SELECT * INTO v_rule FROM public.rate_limit_rules
    WHERE p_endpoint LIKE endpoint_pattern AND is_active = true
    ORDER BY length(endpoint_pattern) DESC LIMIT 1;

    IF v_rule IS NULL THEN
        RETURN jsonb_build_object('allowed', true, 'remaining', 999999);
    END IF;

    v_window_start := now() - (v_rule.window_seconds || ' seconds')::INTERVAL;

    -- Check existing limit
    SELECT * INTO v_limit FROM public.api_rate_limits
    WHERE (user_id = p_user_id OR ip_address = p_ip_address)
        AND endpoint = p_endpoint
        AND window_start >= v_window_start
    FOR UPDATE;

    -- Blocked?
    IF v_limit IS NOT NULL AND v_limit.blocked_until IS NOT NULL AND v_limit.blocked_until > now() THEN
        RETURN jsonb_build_object(
            'allowed', false, 'blocked', true,
            'retry_after', EXTRACT(EPOCH FROM (v_limit.blocked_until - now()))::INT
        );
    END IF;

    IF v_limit IS NULL THEN
        INSERT INTO public.api_rate_limits (user_id, ip_address, endpoint, window_start)
        VALUES (p_user_id, p_ip_address, p_endpoint, now());
        RETURN jsonb_build_object('allowed', true, 'remaining', v_rule.max_requests - 1);
    END IF;

    IF v_limit.request_count >= v_rule.max_requests THEN
        UPDATE public.api_rate_limits SET
            is_blocked = true,
            blocked_until = now() + (v_rule.block_duration_seconds || ' seconds')::INTERVAL
        WHERE id = v_limit.id;
        RETURN jsonb_build_object('allowed', false, 'blocked', true, 'retry_after', v_rule.block_duration_seconds);
    END IF;

    UPDATE public.api_rate_limits SET
        request_count = request_count + 1, last_request = now()
    WHERE id = v_limit.id;

    RETURN jsonb_build_object('allowed', true, 'remaining', v_rule.max_requests - v_limit.request_count - 1);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 2. AUTH SESSIONS & FAILED LOGIN TRACKING
-- ============================================================
CREATE TABLE public.auth_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_token TEXT NOT NULL,
    ip_address INET,
    user_agent TEXT,
    device_info JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    last_activity TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days')
);

CREATE TABLE public.auth_failed_attempts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL,
    ip_address INET NOT NULL,
    user_agent TEXT,
    attempt_count INT DEFAULT 1,
    last_attempt TIMESTAMPTZ DEFAULT now(),
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_auth_sessions_user ON public.auth_sessions(user_id, is_active);
CREATE INDEX idx_auth_sessions_token ON public.auth_sessions(session_token);
CREATE INDEX idx_failed_attempts_email ON public.auth_failed_attempts(email, ip_address);

ALTER TABLE public.auth_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auth_failed_attempts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View own sessions" ON public.auth_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Create session" ON public.auth_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Revoke own session" ON public.auth_sessions FOR UPDATE USING (auth.uid() = user_id);
-- Failed attempts: no user access (server-side only via security definer functions)

-- Track failed login (with automatic lockout after 5 attempts for 15 minutes)
CREATE OR REPLACE FUNCTION track_failed_login(
    p_email TEXT,
    p_ip_address INET,
    p_user_agent TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_attempt RECORD;
    v_max_attempts INT := 5;
    v_lock_duration INTERVAL := INTERVAL '15 minutes';
BEGIN
    SELECT * INTO v_attempt FROM public.auth_failed_attempts
    WHERE email = p_email AND ip_address = p_ip_address
    FOR UPDATE;

    IF v_attempt IS NULL THEN
        INSERT INTO public.auth_failed_attempts (email, ip_address, user_agent)
        VALUES (p_email, p_ip_address, p_user_agent);
        RETURN true;  -- allowed
    END IF;

    -- Still locked?
    IF v_attempt.locked_until IS NOT NULL AND v_attempt.locked_until > now() THEN
        RETURN false;
    END IF;

    -- Increment
    UPDATE public.auth_failed_attempts SET
        attempt_count = attempt_count + 1,
        last_attempt = now(),
        locked_until = CASE
            WHEN attempt_count + 1 >= v_max_attempts THEN now() + v_lock_duration
            ELSE NULL
        END
    WHERE email = p_email AND ip_address = p_ip_address;

    RETURN (v_attempt.attempt_count + 1) < v_max_attempts;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clear failed attempts on successful login
CREATE OR REPLACE FUNCTION clear_failed_login_attempts(p_email TEXT, p_ip_address INET)
RETURNS VOID AS $$
BEGIN
    DELETE FROM public.auth_failed_attempts
    WHERE email = p_email AND ip_address = p_ip_address;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create auth session
CREATE OR REPLACE FUNCTION create_auth_session(
    p_user_id UUID,
    p_session_token TEXT,
    p_ip_address INET,
    p_user_agent TEXT DEFAULT NULL,
    p_device_info JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE v_session_id UUID;
BEGIN
    INSERT INTO public.auth_sessions (user_id, session_token, ip_address, user_agent, device_info)
    VALUES (p_user_id, p_session_token, p_ip_address, p_user_agent, p_device_info)
    RETURNING id INTO v_session_id;
    RETURN v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Revoke all sessions (panic button)
CREATE OR REPLACE FUNCTION revoke_all_sessions(p_user_id UUID)
RETURNS INT AS $$
DECLARE v_count INT;
BEGIN
    UPDATE public.auth_sessions SET is_active = false
    WHERE user_id = p_user_id AND is_active = true;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 3. BACKUP CODES — bcrypt (NOT md5)
-- ============================================================
-- Override the backup code functions from 002 to use bcrypt

-- Generate 10 backup codes with bcrypt hashing
CREATE OR REPLACE FUNCTION generate_backup_codes(p_user_id UUID)
RETURNS TABLE(code TEXT) AS $$
DECLARE
    v_code TEXT;
    v_code_hash TEXT;
    i INTEGER;
BEGIN
    -- Delete existing codes
    DELETE FROM public.user_backup_codes WHERE user_id = p_user_id;

    FOR i IN 1..10 LOOP
        -- Generate random 8-char alphanumeric code
        v_code := upper(substring(encode(gen_random_bytes(6), 'hex') FROM 1 FOR 8));
        -- Hash with bcrypt (salt built in)
        v_code_hash := crypt(v_code, gen_salt('bf', 10));
        -- Store hash
        INSERT INTO public.user_backup_codes (user_id, code_hash)
        VALUES (p_user_id, v_code_hash);
        -- Return plain code (only time visible)
        code := v_code;
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify and consume a backup code (bcrypt comparison)
CREATE OR REPLACE FUNCTION verify_backup_code(p_user_id UUID, p_code TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_record RECORD;
BEGIN
    -- Check each unused code with bcrypt comparison
    FOR v_record IN
        SELECT * FROM public.user_backup_codes
        WHERE user_id = p_user_id AND is_used = false
    LOOP
        IF v_record.code_hash = crypt(p_code, v_record.code_hash) THEN
            -- Match found — mark as used
            UPDATE public.user_backup_codes SET is_used = true, used_at = now()
            WHERE id = v_record.id;
            RETURN true;
        END IF;
    END LOOP;

    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Count remaining unused codes
CREATE OR REPLACE FUNCTION count_unused_backup_codes(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM public.user_backup_codes
            WHERE user_id = p_user_id AND is_used = false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 4. SECURITY AUDIT LOG
-- ============================================================
CREATE TABLE public.security_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    resource_type TEXT,
    resource_id TEXT,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',
    severity TEXT DEFAULT 'info' CHECK (severity IN ('info','warning','critical')),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_audit_log_user ON public.security_audit_log(user_id, created_at);
CREATE INDEX idx_audit_log_action ON public.security_audit_log(action, created_at);
CREATE INDEX idx_audit_log_severity ON public.security_audit_log(severity, created_at);

ALTER TABLE public.security_audit_log ENABLE ROW LEVEL SECURITY;
-- No user access — server-side only via security definer functions

-- Log a security event
CREATE OR REPLACE FUNCTION log_security_event(
    p_user_id UUID,
    p_action TEXT,
    p_resource_type TEXT DEFAULT NULL,
    p_resource_id TEXT DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}',
    p_severity TEXT DEFAULT 'info'
) RETURNS UUID AS $$
DECLARE v_id UUID;
BEGIN
    INSERT INTO public.security_audit_log
        (user_id, action, resource_type, resource_id, ip_address, metadata, severity)
    VALUES
        (p_user_id, p_action, p_resource_type, p_resource_id, p_ip_address, p_metadata, p_severity)
    RETURNING id INTO v_id;
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 5. PASSWORD STRENGTH LOG
-- ============================================================
CREATE TABLE public.password_strength_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    strength_score INT CHECK (strength_score >= 0 AND strength_score <= 4),
    checked_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.password_strength_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View own pw log" ON public.password_strength_log FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Record pw check" ON public.password_strength_log FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 6. USER FOLLOWING (Social graph)
-- ============================================================
CREATE TABLE public.user_following (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX idx_user_following_follower ON public.user_following(follower_id);
CREATE INDEX idx_user_following_following ON public.user_following(following_id);

ALTER TABLE public.user_following ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View follows" ON public.user_following FOR SELECT USING (true);
CREATE POLICY "Follow users" ON public.user_following FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Unfollow" ON public.user_following FOR DELETE USING (auth.uid() = follower_id);

-- Update follower/following counts
CREATE OR REPLACE FUNCTION update_follow_counts() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
        UPDATE public.profiles SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.profiles SET following_count = following_count - 1 WHERE id = OLD.follower_id;
        UPDATE public.profiles SET followers_count = followers_count - 1 WHERE id = OLD.following_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



CREATE TRIGGER on_follow_change
    AFTER INSERT OR DELETE ON public.user_following
    FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- Notify on follow
CREATE OR REPLACE FUNCTION notify_on_follow() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (user_id, actor_id, type, entity_type, entity_id)
    VALUES (NEW.following_id, NEW.follower_id, 'follow', 'user', NEW.follower_id);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_follow_notify
    AFTER INSERT ON public.user_following
    FOR EACH ROW EXECUTE FUNCTION notify_on_follow();

-- ============================================================
-- 7. FCM DEVICE TOKENS (for push notifications)
-- ============================================================
CREATE TABLE public.user_devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    device_name TEXT,
    platform TEXT CHECK (platform IN ('android','ios','web')),
    last_active TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, fcm_token)
);

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View own devices" ON public.user_devices FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Register device" ON public.user_devices FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Update device" ON public.user_devices FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Remove device" ON public.user_devices FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- 8. CLEANUP CRON HELPERS
-- ============================================================

-- Clean expired stories
CREATE OR REPLACE FUNCTION cleanup_expired_stories() RETURNS void AS $$
BEGIN
    DELETE FROM public.user_stories WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean expired rate limits (older than 1 hour)
CREATE OR REPLACE FUNCTION cleanup_rate_limits() RETURNS void AS $$
BEGIN
    DELETE FROM public.api_rate_limits
    WHERE window_start < now() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions() RETURNS void AS $$
BEGIN
    UPDATE public.auth_sessions SET is_active = false
    WHERE is_active = true AND expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean old notifications (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_notifications() RETURNS void AS $$
BEGIN
    DELETE FROM public.notifications
    WHERE created_at < now() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 9. STORAGE BUCKETS
-- ============================================================
-- Note: Run these in the Supabase Dashboard > Storage, or via:
-- INSERT INTO storage.buckets (id, name, public) VALUES
--   ('user-stories', 'user-stories', true);
-- The app references bucket: 'user-stories'

-- ============================================================
-- DONE — Security Hardening Complete
-- ============================================================
