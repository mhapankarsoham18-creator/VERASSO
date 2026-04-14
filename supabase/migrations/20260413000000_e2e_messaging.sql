-- ==========================================
-- PHASE 4: E2E MESSAGING & NOTIFICATIONS
-- ==========================================

-- 1. Update Profiles with Cryptography & Notification fields
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS public_key text,
ADD COLUMN IF NOT EXISTS private_key text, -- Protected tightly by RLS!
ADD COLUMN IF NOT EXISTS fcm_token text;

-- 2. Conversations Table (1-on-1 or Groups)
CREATE TABLE IF NOT EXISTS conversations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    is_group boolean DEFAULT false,
    name text -- null for 1-on-1
);

-- 3. Conversation Participants
CREATE TABLE IF NOT EXISTS conversation_participants (
    conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at timestamptz DEFAULT now(),
    PRIMARY KEY (conversation_id, user_id)
);

-- 4. Messages Table
CREATE TABLE IF NOT EXISTS messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    encrypted_payload text NOT NULL, -- AES-256-GCM ciphertext
    nonce text NOT NULL, -- AES Nonce
    created_at timestamptz DEFAULT now()
);

-- ==========================================
-- strict ROW LEVEL SECURITY (RLS)
-- ==========================================

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Conversations: A user can only view conversations they are part of
CREATE POLICY "Users can view their conversations"
ON conversations FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = conversations.id 
        AND user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert conversations"
ON conversations FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- Participants: A user can view participants of their conversations
CREATE POLICY "Users can view participants of their conversations"
ON conversation_participants FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM conversation_participants cp 
        WHERE cp.conversation_id = conversation_participants.conversation_id 
        AND cp.user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert participants"
ON conversation_participants FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- Messages: A user can view messages in their conversations
CREATE POLICY "Users can view messages in their conversations"
ON messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = messages.conversation_id 
        AND user_id = auth.uid()
    )
);

-- Messages: A user can only insert messages as themselves
CREATE POLICY "Users can insert messages"
ON messages FOR INSERT
WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = messages.conversation_id 
        AND user_id = auth.uid()
    )
);

-- Profiles Private Key Protection Override
-- The original public profile read policy might expose private_key.
-- We must drop the old generic policy and recreate it tightly.
DROP POLICY IF EXISTS "profiles_public_read" ON profiles;

CREATE POLICY "Public profile fields are visible to everyone"
ON profiles FOR SELECT
USING (true);

-- Ensure private_key stays hidden from public queries by restructuring how it's fetched,
-- but PostgreSQL RLS for individual columns is complex. 
-- For MVP, since we added it to `profiles`, any `SELECT * FROM profiles` will fetch it.
-- TO FIX: We'll push the private key to a separate restricted table to guarantee security.

CREATE TABLE IF NOT EXISTS user_keys (
    user_id uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    private_key text NOT NULL,
    updated_at timestamptz DEFAULT now()
);

ALTER TABLE user_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only read their own private key"
ON user_keys FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can only update their own private key"
ON user_keys FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Clean up the accidental column from earlier
ALTER TABLE profiles DROP COLUMN private_key;
