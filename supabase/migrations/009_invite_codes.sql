-- ============================================================
-- VERASSO Schema — Part 9: Invite Codes
-- ============================================================

-- 1. Create Table
CREATE TABLE public.invite_codes (
    code TEXT PRIMARY KEY,
    owner_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    max_uses INT DEFAULT 1,
    current_uses INT DEFAULT 0,
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Populate with some initial codes (Optional)
INSERT INTO public.invite_codes (code, max_uses) VALUES ('VERASSO-BETA-2026', 100);
INSERT INTO public.invite_codes (code, max_uses) VALUES ('VIP-EARLY-ACCESS', 10);

-- 3. RLS
ALTER TABLE public.invite_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins manage invites" ON public.invite_codes FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);
-- Public can only see if a code exists/is valid via RPC, not direct SELECT
-- This prevents brute-forcing codes via direct API calls easily

-- 4. RPC Function
CREATE OR REPLACE FUNCTION public.validate_invite_code(p_code TEXT)
RETURNS TABLE (
    is_valid BOOLEAN,
    message TEXT,
    metadata JSONB
) AS $$
DECLARE
    found_code public.invite_codes;
BEGIN
    SELECT * INTO found_code FROM public.invite_codes 
    WHERE code = p_code AND is_active = true;

    IF NOT FOUND THEN
        RETURN QUERY SELECT false, 'Invalid invite code.'::TEXT, '{}'::JSONB;
    ELSIF found_code.expires_at IS NOT NULL AND found_code.expires_at < now() THEN
        RETURN QUERY SELECT false, 'Invite code has expired.'::TEXT, '{}'::JSONB;
    ELSIF found_code.current_uses >= found_code.max_uses THEN
        RETURN QUERY SELECT false, 'Invite code has reached maximum uses.'::TEXT, '{}'::JSONB;
    ELSE
        RETURN QUERY SELECT true, 'Valid invite code.'::TEXT, found_code.metadata;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC Function to consume
CREATE OR REPLACE FUNCTION public.consume_invite_code(p_code TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.invite_codes
    SET current_uses = current_uses + 1
    WHERE code = p_code 
      AND is_active = true 
      AND (expires_at IS NULL OR expires_at > now())
      AND current_uses < max_uses;
      
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
