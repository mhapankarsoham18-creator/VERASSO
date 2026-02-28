-- ============================================================
-- VERASSO Schema — Part 20: User Interests & Weighted Recommendations
-- ============================================================
CREATE TABLE public.user_interests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    category TEXT NOT NULL,
    score INT DEFAULT 0,
    -- Increments with likes, shares, etc.
    weight DECIMAL(3, 2) DEFAULT 1.0,
    -- Manual preference weight
    last_interacted_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    UNIQUE(user_id, category)
);
ALTER TABLE public.user_interests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own interests" ON public.user_interests FOR ALL USING (auth.uid() = user_id);
CREATE INDEX idx_user_interests_user ON public.user_interests(user_id);
CREATE INDEX idx_user_interests_category ON public.user_interests(category);
-- Trigger to increment interest score when a post is liked
CREATE OR REPLACE FUNCTION public.handle_interest_on_like() RETURNS TRIGGER AS $$
DECLARE v_post_tags TEXT [];
v_tag TEXT;
BEGIN IF NEW.post_id IS NOT NULL THEN
SELECT tags INTO v_post_tags
FROM public.posts
WHERE id = NEW.post_id;
IF v_post_tags IS NOT NULL THEN FOREACH v_tag IN ARRAY v_post_tags LOOP
INSERT INTO public.user_interests (user_id, category, score, last_interacted_at)
VALUES (NEW.user_id, v_tag, 1, now()) ON CONFLICT (user_id, category) DO
UPDATE
SET score = user_interests.score + 1,
    last_interacted_at = now();
END LOOP;
END IF;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_like_update_interests
AFTER
INSERT ON public.likes FOR EACH ROW EXECUTE FUNCTION public.handle_interest_on_like();
-- Migration of existing profile interests to the new table
INSERT INTO public.user_interests (user_id, category, score, weight)
SELECT id,
    unnest(interests),
    5,
    1.0
FROM public.profiles
WHERE interests IS NOT NULL
    AND array_length(interests, 1) > 0 ON CONFLICT DO NOTHING;