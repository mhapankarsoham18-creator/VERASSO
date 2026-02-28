-- ============================================================
-- VERASSO Schema — Part 8: Notification Triggers
-- Automated Push Notifications via Edge Functions
-- ============================================================

-- 1. Ensure Extensions
CREATE EXTENSION IF NOT EXISTS "pg_net";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- Backfill for 006

-- 2. Function to call Edge Function
CREATE OR REPLACE FUNCTION public.send_push_notification()
RETURNS TRIGGER AS $$
DECLARE
    request_id BIGINT;
    function_url TEXT;
    anon_key TEXT;
    payload JSONB;
BEGIN
    -- Get project settings (can be hardcoded or retrieved if stored)
    -- Typically these are passed in via Vault or Config, but for simplicity:
    function_url := 'https://' || current_setting('request.headers')::json->>'host' || '/functions/v1/on_notification_created';
    -- Alternatively, use environment variables if using a custom runner or hardcode for now
    -- For local dev: 'http://kong:8000/functions/v1/on_notification_created'
    -- A better way is to use a config table or hardcoded URL for the project
    
    -- Construct payload
    payload := jsonb_build_object(
        'record', jsonb_build_object(
            'id', NEW.id,
            'user_id', NEW.user_id,
            'type', NEW.type,
            'entity_type', NEW.entity_type,
            'entity_id', NEW.entity_id,
            'metadata', NEW.metadata,
            'title', CASE 
                WHEN NEW.type = 'like' THEN 'New Like!'
                WHEN NEW.type = 'comment' THEN 'New Comment!'
                WHEN NEW.type = 'message' THEN 'New Message!'
                ELSE 'Update from VERASSO'
            END,
            'message', 'You have a new ' || NEW.type
        )
    );

    -- Call Edge Function via pg_net (async)
    -- We use the SERVICE_ROLE_KEY if we want to bypass RLS, or Anon if logic handles it
    -- For now, let's assume the Edge Function handles its own auth via Service Role when needed
    
    -- NOTE: In production, substitute these with your actual Supabase URL and Service Role Key
    -- or use standard environment headers if available.
    
    SELECT net.http_post(
        url := 'http://localhost:54321/functions/v1/on_notification_created', -- Local fallback
        body := payload,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('request.headers', true)::json->>'authorization'
        )
    ) INTO request_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Trigger on Notifications table
DROP TRIGGER IF EXISTS on_notification_created_trigger ON public.notifications;
CREATE TRIGGER on_notification_created_trigger
    AFTER INSERT ON public.notifications
    FOR EACH ROW EXECUTE FUNCTION public.send_push_notification();

-- 4. Update create_notification_trigger to handle MESSAGES and POSTS
CREATE OR REPLACE FUNCTION public.create_notification_trigger() RETURNS TRIGGER AS $$
DECLARE
    entity_owner UUID;
    notif_type TEXT;
    entity_type TEXT;
    entity_id UUID;
BEGIN
    -- LIKES
    IF (TG_TABLE_NAME = 'likes') THEN
        notif_type := 'like';
        IF NEW.post_id IS NOT NULL THEN
            entity_type := 'post';
            entity_id := NEW.post_id;
            SELECT user_id INTO entity_owner FROM public.posts WHERE id = NEW.post_id;
        ELSIF NEW.comment_id IS NOT NULL THEN
            entity_type := 'comment';
            entity_id := NEW.comment_id;
            SELECT user_id INTO entity_owner FROM public.comments WHERE id = NEW.comment_id;
        END IF;
    
    -- COMMENTS
    ELSIF (TG_TABLE_NAME = 'comments') THEN
        notif_type := 'comment';
        IF NEW.post_id IS NOT NULL THEN
            entity_type := 'post';
            entity_id := NEW.post_id;
            SELECT user_id INTO entity_owner FROM public.posts WHERE id = NEW.post_id;
        ELSIF NEW.doubt_id IS NOT NULL THEN
            entity_type := 'doubt';
            entity_id := NEW.doubt_id;
            SELECT user_id INTO entity_owner FROM public.doubts WHERE id = NEW.doubt_id;
        END IF;

    -- MESSAGES
    ELSIF (TG_TABLE_NAME = 'messages') THEN
        notif_type := 'message';
        entity_type := 'conversation';
        entity_id := NEW.conversation_id;
        entity_owner := NEW.receiver_id;
    END IF;

    -- Don't notify self
    IF entity_owner IS NOT NULL AND entity_owner != NEW.user_id THEN
        -- Check if notification already exists for this pair to avoid spam (optional)
        INSERT INTO public.notifications (user_id, actor_id, type, entity_type, entity_id)
        VALUES (entity_owner, NEW.user_id, notif_type, entity_type, entity_id);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Add triggers to Messages
DROP TRIGGER IF EXISTS notify_on_message ON public.messages;
CREATE TRIGGER notify_on_message
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.create_notification_trigger();

-- 6. Add triggers to Posts (Followers)
-- Usually posts notify followers. This requires a loop or a bulk insert.
-- For now, let's keep it simple or implement follower notification.
