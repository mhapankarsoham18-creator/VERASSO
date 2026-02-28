-- ============================================================
-- VERASSO — Clean Supabase Schema
-- Generated: 2026-02-14
-- Run on a FRESH Supabase project
-- ============================================================
-- ============================================================
-- 1. EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
-- ============================================================
-- 2. CORE — Profiles
-- ============================================================
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    role TEXT DEFAULT 'student' CHECK (
        role IN ('student', 'teacher', 'admin', 'mentor')
    ),
    trust_score INT DEFAULT 0,
    website TEXT,
    interests TEXT [],
    is_private BOOLEAN DEFAULT false,
    preferred_language TEXT DEFAULT 'en',
    is_age_verified BOOLEAN DEFAULT false,
    verification_url TEXT,
    is_mentor BOOLEAN DEFAULT false,
    mentor_title TEXT,
    mentor_verification_status TEXT DEFAULT 'none',
    is_alumni_mentor BOOLEAN DEFAULT false,
    earnings_balance DECIMAL(12, 2) DEFAULT 0.00,
    default_personal_visibility BOOLEAN DEFAULT false,
    accepted_terms_version INT DEFAULT 0,
    fcm_token TEXT,
    followers_count INT DEFAULT 0,
    following_count INT DEFAULT 0,
    posts_count INT DEFAULT 0,
    video_posts_count INT DEFAULT 0,
    audio_posts_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Profiles viewable unless private" ON public.profiles FOR
SELECT USING (
        NOT is_private
        OR id = auth.uid()
    );
CREATE POLICY "Users can insert own profile" ON public.profiles FOR
INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR
UPDATE USING (auth.uid() = id);
CREATE INDEX idx_profiles_username ON public.profiles(username);
-- Auto-create profile on signup with unique username generation
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER AS $$
DECLARE base_username TEXT;
final_username TEXT;
counter INT := 1;
BEGIN -- 1. Get base username from meta data, full name, or use fallback
base_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    regexp_replace(
        LOWER(NEW.raw_user_meta_data->>'full_name'),
        '\s+',
        '',
        'g'
    ),
    'user_' || substr(NEW.id::text, 1, 8)
);
IF base_username IS NULL
OR base_username = '' THEN base_username := 'user_' || substr(NEW.id::text, 1, 8);
END IF;
final_username := base_username;
-- 2. Ensure uniqueness
WHILE EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE username = final_username
) LOOP final_username := base_username || counter::text;
counter := counter + 1;
END LOOP;
-- 3. Insert profile
INSERT INTO public.profiles (id, full_name, avatar_url, username)
VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url',
        final_username
    );
RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_auth_user_created
AFTER
INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
-- ============================================================
-- 3. SOCIAL — Posts, Doubts, Comments, Likes
-- ============================================================
CREATE TABLE public.posts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT,
    media_urls TEXT [],
    subject TEXT,
    tags TEXT [],
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    media_type TEXT DEFAULT 'image' CHECK (
        media_type IN ('image', 'video', 'audio', 'text')
    ),
    type TEXT DEFAULT 'text' CHECK (type IN ('text', 'media', 'poll', 'audio')),
    audio_url TEXT,
    audio_duration INT,
    mentions TEXT [],
    is_personal BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public posts viewable" ON public.posts FOR
SELECT USING (is_personal = false);
CREATE POLICY "Personal posts by owner" ON public.posts FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Auth users create posts" ON public.posts FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own posts" ON public.posts FOR
UPDATE USING (auth.uid() = user_id);
-- Update profile post counts
CREATE OR REPLACE FUNCTION update_profile_post_counts() RETURNS TRIGGER AS $$ BEGIN IF (TG_OP = 'INSERT') THEN
UPDATE public.profiles
SET posts_count = posts_count + 1
WHERE id = NEW.user_id;
IF NEW.media_type = 'video' THEN
UPDATE public.profiles
SET video_posts_count = video_posts_count + 1
WHERE id = NEW.user_id;
ELSIF NEW.media_type = 'audio' THEN
UPDATE public.profiles
SET audio_posts_count = audio_posts_count + 1
WHERE id = NEW.user_id;
END IF;
ELSIF (TG_OP = 'DELETE') THEN
UPDATE public.profiles
SET posts_count = posts_count - 1
WHERE id = OLD.user_id;
IF OLD.media_type = 'video' THEN
UPDATE public.profiles
SET video_posts_count = video_posts_count - 1
WHERE id = OLD.user_id;
ELSIF OLD.media_type = 'audio' THEN
UPDATE public.profiles
SET audio_posts_count = audio_posts_count - 1
WHERE id = OLD.user_id;
END IF;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_post_change
AFTER
INSERT
    OR DELETE ON public.posts FOR EACH ROW EXECUTE FUNCTION update_profile_post_counts();
CREATE TABLE public.doubts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    question_title TEXT NOT NULL,
    question_description TEXT,
    subject TEXT NOT NULL,
    topic TEXT,
    is_solved BOOLEAN DEFAULT false,
    image_urls TEXT [],
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.doubts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Doubts viewable" ON public.doubts FOR
SELECT USING (true);
CREATE POLICY "Auth users ask doubts" ON public.doubts FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own doubts" ON public.doubts FOR
UPDATE USING (auth.uid() = user_id);
CREATE TABLE public.comments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    doubt_id UUID REFERENCES public.doubts(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_solution BOOLEAN DEFAULT false,
    upvotes INT DEFAULT 0,
    parent_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    CONSTRAINT fk_target CHECK (
        (
            post_id IS NOT NULL
            AND doubt_id IS NULL
        )
        OR (
            post_id IS NULL
            AND doubt_id IS NOT NULL
        )
    )
);
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Comments viewable" ON public.comments FOR
SELECT USING (true);
CREATE POLICY "Auth users comment" ON public.comments FOR
INSERT WITH CHECK (auth.uid() = user_id);
-- Update comments count
CREATE OR REPLACE FUNCTION update_post_comments_count() RETURNS TRIGGER AS $$ BEGIN IF (TG_OP = 'INSERT') THEN
UPDATE public.posts
SET comments_count = comments_count + 1
WHERE id = NEW.post_id;
ELSIF (TG_OP = 'DELETE') THEN
UPDATE public.posts
SET comments_count = comments_count - 1
WHERE id = OLD.post_id;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_comment_change
AFTER
INSERT
    OR DELETE ON public.comments FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();
CREATE TABLE public.likes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    CONSTRAINT fk_like_target CHECK (
        (
            post_id IS NOT NULL
            AND comment_id IS NULL
        )
        OR (
            post_id IS NULL
            AND comment_id IS NOT NULL
        )
    ),
    UNIQUE(user_id, post_id, comment_id)
);
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Likes viewable" ON public.likes FOR
SELECT USING (true);
CREATE POLICY "Users toggle likes" ON public.likes FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users remove likes" ON public.likes FOR DELETE USING (auth.uid() = user_id);
-- Update likes count
CREATE OR REPLACE FUNCTION update_post_likes_count() RETURNS TRIGGER AS $$ BEGIN IF (TG_OP = 'INSERT') THEN IF NEW.post_id IS NOT NULL THEN
UPDATE public.posts
SET likes_count = likes_count + 1
WHERE id = NEW.post_id;
END IF;
ELSIF (TG_OP = 'DELETE') THEN IF OLD.post_id IS NOT NULL THEN
UPDATE public.posts
SET likes_count = likes_count - 1
WHERE id = OLD.post_id;
END IF;
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_like_change
AFTER
INSERT
    OR DELETE ON public.likes FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();
-- Relationships (friends/blocks)
DO $$ BEGIN IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'relationship_status'
) THEN CREATE TYPE relationship_status AS ENUM ('pending', 'friends', 'blocked');
END IF;
END $$;
CREATE TABLE public.relationships (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    target_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('pending', 'friends', 'blocked')),
    user_allows_personal BOOLEAN DEFAULT false,
    target_allows_personal BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, target_id),
    CONSTRAINT different_users CHECK (user_id != target_id)
);
ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View own relationships" ON public.relationships FOR
SELECT USING (
        auth.uid() = user_id
        OR auth.uid() = target_id
    );
CREATE POLICY "Manage own relationships" ON public.relationships FOR ALL USING (auth.uid() = user_id);
CREATE OR REPLACE FUNCTION public.get_relationship_status(current_user_id UUID, other_user_id UUID) RETURNS TEXT AS $$
DECLARE rel_status TEXT;
BEGIN
SELECT status INTO rel_status
FROM public.relationships
WHERE user_id = current_user_id
    AND target_id = other_user_id;
IF rel_status = 'blocked' THEN RETURN 'blocked_by_me';
END IF;
IF rel_status = 'pending' THEN RETURN 'pending_sent';
END IF;
IF rel_status = 'friends' THEN RETURN 'friends';
END IF;
SELECT status INTO rel_status
FROM public.relationships
WHERE user_id = other_user_id
    AND target_id = current_user_id;
IF rel_status = 'blocked' THEN RETURN 'blocked_by_them';
END IF;
IF rel_status = 'pending' THEN RETURN 'pending_received';
END IF;
IF rel_status = 'friends' THEN RETURN 'friends';
END IF;
RETURN 'none';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Notify on friend request
CREATE OR REPLACE FUNCTION notify_on_friend_request() RETURNS TRIGGER AS $$ BEGIN IF (NEW.status = 'pending') THEN
INSERT INTO public.notifications (user_id, actor_id, type, entity_type, entity_id)
VALUES (
        NEW.target_id,
        NEW.user_id,
        'friend_request',
        'user',
        NEW.user_id
    );
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_relationship_change
AFTER
INSERT
    OR
UPDATE ON public.relationships FOR EACH ROW EXECUTE FUNCTION notify_on_friend_request();
-- Polls
CREATE TABLE public.polls (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
    question TEXT NOT NULL,
    expires_at TIMESTAMPTZ,
    total_votes INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.poll_options (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE NOT NULL,
    option_text TEXT NOT NULL,
    votes_count INT DEFAULT 0
);
CREATE TABLE public.poll_votes (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    option_id UUID REFERENCES public.poll_options(id) ON DELETE CASCADE,
    poll_id UUID REFERENCES public.polls(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, poll_id)
);
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Polls public" ON public.polls FOR
SELECT USING (true);
CREATE POLICY "Options public" ON public.poll_options FOR
SELECT USING (true);
CREATE POLICY "Auth vote" ON public.poll_votes FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "See own votes" ON public.poll_votes FOR
SELECT USING (auth.uid() = user_id);
-- Saved Posts & Collections
CREATE TABLE public.saved_posts (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, post_id)
);
CREATE TABLE public.collections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    is_private BOOLEAN DEFAULT true,
    collaborator_ids UUID [] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.collection_posts (
    collection_id UUID REFERENCES public.collections(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (collection_id, post_id)
);
ALTER TABLE public.saved_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage saved" ON public.saved_posts FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "View collections" ON public.collections FOR
SELECT USING (
        NOT is_private
        OR owner_id = auth.uid()
        OR auth.uid() = ANY(collaborator_ids)
    );
CREATE POLICY "Manage collections" ON public.collections FOR ALL USING (owner_id = auth.uid());
CREATE POLICY "View collection posts" ON public.collection_posts FOR
SELECT USING (true);
CREATE POLICY "Add to own collections" ON public.collection_posts FOR
INSERT WITH CHECK (
        EXISTS (
            SELECT 1
            FROM public.collections
            WHERE id = collection_id
                AND (
                    owner_id = auth.uid()
                    OR auth.uid() = ANY(collaborator_ids)
                )
        )
    );
-- ============================================================
-- 4. MESSAGING
-- ============================================================
CREATE TABLE public.user_keys (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    public_key TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.user_keys ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Keys public" ON public.user_keys FOR
SELECT USING (true);
CREATE POLICY "Upload own key" ON public.user_keys FOR
INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Update own key" ON public.user_keys FOR
UPDATE USING (auth.uid() = user_id);
CREATE TABLE public.conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    participant1_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    participant2_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    last_message_content TEXT,
    last_message_at TIMESTAMPTZ DEFAULT now(),
    unread_count_p1 INT DEFAULT 0,
    unread_count_p2 INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    CONSTRAINT p1_p2_diff CHECK (participant1_id != participant2_id)
);
CREATE UNIQUE INDEX unique_conversation_idx ON public.conversations (
    LEAST(participant1_id, participant2_id),
    GREATEST(participant1_id, participant2_id)
);
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View own convos" ON public.conversations FOR
SELECT USING (
        auth.uid() = participant1_id
        OR auth.uid() = participant2_id
    );
CREATE TABLE public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT,
    encrypted_content TEXT,
    iv_text TEXT,
    key_for_receiver TEXT,
    key_for_sender TEXT,
    type TEXT DEFAULT 'text' CHECK (
        type IN (
            'text',
            'image',
            'video',
            'audio',
            'sticker',
            'gif',
            'file'
        )
    ),
    metadata JSONB DEFAULT '{}',
    status TEXT DEFAULT 'sent',
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View own messages" ON public.messages FOR
SELECT USING (
        auth.uid() = sender_id
        OR auth.uid() = receiver_id
    );
CREATE POLICY "Send messages" ON public.messages FOR
INSERT WITH CHECK (auth.uid() = sender_id);
-- Update conversation on new message
CREATE OR REPLACE FUNCTION public.handle_new_message() RETURNS TRIGGER AS $$ BEGIN IF NEW.conversation_id IS NOT NULL THEN
UPDATE public.conversations
SET last_message_content = CASE
        WHEN NEW.type = 'text'
        AND NEW.content IS NOT NULL THEN LEFT(NEW.content, 100)
        WHEN NEW.encrypted_content IS NOT NULL THEN '[Encrypted]'
        ELSE 'Sent a ' || NEW.type
    END,
    last_message_at = COALESCE(NEW.sent_at, now()),
    updated_at = now(),
    unread_count_p1 = CASE
        WHEN participant1_id = NEW.receiver_id THEN unread_count_p1 + 1
        ELSE unread_count_p1
    END,
    unread_count_p2 = CASE
        WHEN participant2_id = NEW.receiver_id THEN unread_count_p2 + 1
        ELSE unread_count_p2
    END
WHERE id = NEW.conversation_id;
END IF;
RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER on_new_message
AFTER
INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.handle_new_message();
-- ============================================================
-- 5. NOTIFICATIONS
-- ============================================================
CREATE TABLE public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (
        type IN (
            'like',
            'comment',
            'reply',
            'mention',
            'follow',
            'system',
            'message',
            'friend_request'
        )
    ),
    entity_type TEXT NOT NULL,
    -- post, comment, user, message
    entity_id UUID NOT NULL,
    metadata JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_notifications_user ON public.notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id)
WHERE is_read = false;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View own notifications" ON public.notifications FOR
SELECT USING (auth.uid() = user_id);
CREATE POLICY "Update own notifications" ON public.notifications FOR
UPDATE USING (auth.uid() = user_id);
-- FUNCTION: Create Notification
CREATE OR REPLACE FUNCTION public.create_notification_trigger() RETURNS TRIGGER AS $$
DECLARE entity_owner UUID;
notif_type TEXT;
entity_type TEXT;
entity_id UUID;
BEGIN -- LIKES
IF (TG_TABLE_NAME = 'likes') THEN notif_type := 'like';
IF NEW.post_id IS NOT NULL THEN entity_type := 'post';
entity_id := NEW.post_id;
SELECT user_id INTO entity_owner
FROM public.posts
WHERE id = NEW.post_id;
ELSIF NEW.comment_id IS NOT NULL THEN entity_type := 'comment';
entity_id := NEW.comment_id;
SELECT user_id INTO entity_owner
FROM public.comments
WHERE id = NEW.comment_id;
END IF;
-- COMMENTS
ELSIF (TG_TABLE_NAME = 'comments') THEN notif_type := 'comment';
IF NEW.post_id IS NOT NULL THEN entity_type := 'post';
entity_id := NEW.post_id;
SELECT user_id INTO entity_owner
FROM public.posts
WHERE id = NEW.post_id;
ELSIF NEW.doubt_id IS NOT NULL THEN entity_type := 'doubt';
entity_id := NEW.doubt_id;
SELECT user_id INTO entity_owner
FROM public.doubts
WHERE id = NEW.doubt_id;
END IF;
END IF;
-- Don't notify self
IF entity_owner IS NOT NULL
AND entity_owner != NEW.user_id THEN
INSERT INTO public.notifications (user_id, actor_id, type, entity_type, entity_id)
VALUES (
        entity_owner,
        NEW.user_id,
        notif_type,
        entity_type,
        entity_id
    );
END IF;
RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE TRIGGER notify_on_like
AFTER
INSERT ON public.likes FOR EACH ROW EXECUTE FUNCTION public.create_notification_trigger();
CREATE TRIGGER notify_on_comment
AFTER
INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION public.create_notification_trigger();