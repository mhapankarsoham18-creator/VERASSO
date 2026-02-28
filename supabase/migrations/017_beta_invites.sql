-- Migration 017: Beta Invite Codes Generation
-- Created: 2026-02-27
-- Description: Generates 50 initial beta invite codes for the Closed Beta phase.
-- Ensure invite_codes table exists (assuming it was created in Phase 1/2)
-- If not, this serves as a safeguard.
CREATE TABLE IF NOT EXISTS public.invite_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    max_uses INT DEFAULT 1,
    current_uses INT DEFAULT 0,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID REFERENCES auth.users(id)
);
-- RLS for invite_codes
ALTER TABLE public.invite_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Invite codes are readable by anyone" ON public.invite_codes FOR
SELECT USING (true);
-- Insert 50 codes
-- Sequence: VERASSO-BETA-001 to VERASSO-BETA-050
INSERT INTO public.invite_codes (code, max_uses, expires_at)
SELECT 'VERASSO-BETA-' || LPAD(s.i::text, 3, '0'),
    10,
    -- Each code can be used 10 times
    NOW() + INTERVAL '30 days'
FROM generate_series(1, 50) s(i) ON CONFLICT (code) DO NOTHING;
-- Create feedback table for Phase 5 feedback loop
CREATE TABLE IF NOT EXISTS public.user_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    type TEXT NOT NULL,
    -- 'bug', 'feature', 'general'
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.user_feedback ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their own feedback" ON public.user_feedback FOR
INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view their own feedback" ON public.user_feedback FOR
SELECT TO authenticated USING (auth.uid() = user_id);