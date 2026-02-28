-- ============================================================
-- 010_RLS_HARDENING.SQL
-- Phase 4 Security Blitz: Restricting broad policies
-- ============================================================
-- 1. Tightening Profiles
DROP POLICY IF EXISTS "Profiles viewable unless private" ON public.profiles;
CREATE POLICY "Public profiles viewable" ON public.profiles FOR
SELECT USING (
        (NOT is_private)
        OR (auth.uid() = id)
    );
-- 2. Tightening Attachments (CRITICAL: was public)
DROP POLICY IF EXISTS "Upload attachment" ON public.attachments;
CREATE POLICY "Authenticated users upload own attachments" ON public.attachments FOR
INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "View own attachments" ON public.attachments;
CREATE POLICY "Users view own attachments" ON public.attachments FOR
SELECT USING (auth.uid() = user_id);
-- 3. Tightening Form Attachments (CRITICAL: was public)
DROP POLICY IF EXISTS "Create form link" ON public.form_attachments;
CREATE POLICY "Authenticated users link attachments" ON public.form_attachments FOR
INSERT WITH CHECK (auth.role() = 'authenticated');
-- 4. Tightening Upload Chunks (CRITICAL: was public)
DROP POLICY IF EXISTS "Upload chunk" ON public.upload_chunks;
CREATE POLICY "Authenticated users upload chunks" ON public.upload_chunks FOR
INSERT WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.upload_sessions
            WHERE id = session_id
                AND user_id = auth.uid()
        )
    );
-- 5. Hardening Messages (Prevent unauthorized updates)
DROP POLICY IF EXISTS "Send messages" ON public.messages;
CREATE POLICY "Users can only send as themselves" ON public.messages FOR
INSERT WITH CHECK (auth.uid() = sender_id);
-- 6. Rate Limiting RPC Improvement (Enhanced check_rate_limit)
-- Assuming check_rate_limit already exists in 003_security.sql
-- We ensure it uses the authenticated user ID and logs failures.
CREATE OR REPLACE FUNCTION public.check_rate_limit_auth(
        p_action TEXT,
        p_limit INT,
        p_window_seconds INT
    ) RETURNS BOOLEAN AS $$
DECLARE v_user_id UUID := auth.uid();
v_count INT;
BEGIN IF v_user_id IS NULL THEN RETURN FALSE;
END IF;
-- Delete expired attempts
DELETE FROM public.api_rate_limits
WHERE user_id = v_user_id
    AND endpoint = p_action
    AND created_at < now() - (p_window_seconds || ' seconds')::interval;
-- Count recent attempts
SELECT count(*) INTO v_count
FROM public.api_rate_limits
WHERE user_id = v_user_id
    AND endpoint = p_action;
IF v_count >= p_limit THEN RETURN FALSE;
END IF;
-- Record current attempt
INSERT INTO public.api_rate_limits (user_id, endpoint, created_at)
VALUES (v_user_id, p_action, now());
RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;