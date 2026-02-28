-- Add privacy_settings JSONB column to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS privacy_settings JSONB DEFAULT '{}'::jsonb;
-- Optional: Update existing profiles with default settings if needed
-- UPDATE public.profiles SET privacy_settings = '{"mask_email": false, "mask_full_name": false}'::jsonb WHERE privacy_settings IS NULL;