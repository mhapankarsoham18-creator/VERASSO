-- Wipe all existing posts first (foreign key dependency)
DELETE FROM posts;

-- Wipe all existing doubts
DELETE FROM doubts;

-- Wipe all existing profiles
DELETE FROM profiles;

-- Now add UNIQUE constraint on username to prevent duplicates
ALTER TABLE profiles ADD CONSTRAINT profiles_username_unique UNIQUE (username);

-- Also enforce unique firebase_uid (one profile per Firebase account)
ALTER TABLE profiles ADD CONSTRAINT profiles_firebase_uid_unique UNIQUE (firebase_uid);
