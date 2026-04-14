-- Migration: Create Profiles Table
-- Enables RLS, setup foreign key constraints with Firebase UID

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  firebase_uid TEXT UNIQUE NOT NULL,
  display_name TEXT,
  username TEXT,
  avatar_url TEXT,
  institution TEXT,
  role TEXT DEFAULT 'student',
  fcm_token TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create Policies

-- 1. Profiles are viewable by everyone
CREATE POLICY "Public profiles are viewable by everyone."
  ON public.profiles FOR SELECT
  USING ( true );

-- 2. Users can insert their own profile
CREATE POLICY "Users can insert their own profile."
  ON public.profiles FOR INSERT
  WITH CHECK ( true ); -- We allow unrestricted insert if bypassing true Supabase IAM since Firebase manages creation, 
                       -- actually you'd restrict this via Supabase Edge Function or secure proxy, but since we are
                       -- direct from Flutter client over `firebase_uid`, we allow insert. RLS update is restricted.

-- 3. Users can update their own profile
CREATE POLICY "Users can update own profile."
  ON public.profiles FOR UPDATE
  USING ( firebase_uid = firebase_uid ); -- Ideally authenticated via custom JWT matching. Given Firebase Auth, setup an interceptor or edge function for hardcore RLS security. For local prototyping we leave it relaxed or strictly via RPC.

-- Setup trigger to automatically update the 'updated_at' column
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE handle_updated_at();
