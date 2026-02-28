-- ============================================================
-- VERASSO Schema — Part 25: Communities & Membership RPC
-- ============================================================
-- 1. Create communities table if missing
CREATE TABLE IF NOT EXISTS public.communities (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    avatar_url TEXT,
    subject TEXT NOT NULL,
    member_count INT DEFAULT 0,
    is_private BOOLEAN DEFAULT false,
    creator_id UUID REFERENCES public.profiles(id) ON DELETE
    SET NULL,
        created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
-- 2. Create community_members table if missing
CREATE TABLE IF NOT EXISTS public.community_members (
    community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    PRIMARY KEY (community_id, user_id)
);
-- 3. RLS Policies
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Communities are viewable by everyone" ON public.communities FOR
SELECT USING (true);
CREATE POLICY "Community memberships are viewable by everyone" ON public.community_members FOR
SELECT USING (true);
CREATE POLICY "Users can join communities" ON public.community_members FOR
INSERT WITH CHECK (auth.uid() = user_id);
-- 4. Atomic join_community RPC
-- This function handles the insertion and increments the member_count in one transaction.
CREATE OR REPLACE FUNCTION join_community(p_community_id UUID, p_user_id UUID) RETURNS VOID AS $$ BEGIN -- Check if already a member
    IF EXISTS (
        SELECT 1
        FROM public.community_members
        WHERE community_id = p_community_id
            AND user_id = p_user_id
    ) THEN RETURN;
END IF;
-- Add member
INSERT INTO public.community_members (community_id, user_id)
VALUES (p_community_id, p_user_id);
-- Increment count
UPDATE public.communities
SET member_count = member_count + 1
WHERE id = p_community_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;