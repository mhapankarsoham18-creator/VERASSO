-- ============================================================
-- VERASSO — GDPR Compliance: User Data Deletion
-- SECURITY DEFINER function to allow a user to purge their own data
-- ============================================================
-- Function to completely delete a user's account and all associated data
-- This is called from the mobile app when a user requests "Delete Account"
CREATE OR REPLACE FUNCTION public.delete_user_account() RETURNS VOID AS $$
DECLARE v_user_id UUID;
BEGIN -- Get the UID of the user calling the function
v_user_id := auth.uid();
IF v_user_id IS NULL THEN RAISE EXCEPTION 'Not authenticated';
END IF;
-- NOTE: Most tables in VERASSO have "ON DELETE CASCADE" linking to profiles or auth.users.
-- Deleting from profiles will trigger cascades for posts, comments, likes, notifications, stats, etc.
-- 1. Log the deletion for audit purposes (optional, since the user is being deleted)
-- We can log it to a separate sys_audit table that SET NULLs the user_id if we want a record.
-- 2. Delete the profile record
-- This triggers cascades to almost all local application tables.
DELETE FROM public.profiles
WHERE id = v_user_id;
-- 3. Delete from user_stats (if not already cascaded)
DELETE FROM public.user_stats
WHERE user_id = v_user_id;
-- 4. Delete the auth.user record
-- Warning: Standard SQL users cannot delete from auth.users.
-- In a production environment, you would typically use an Edge Function 
-- or a trigger that listens for profile deletion and uses the service_role 
-- to wipe the auth record.
-- For this RPC, we focus on purging APPLICATION data.
-- If you want to delete the actual AUTH record via SQL, the function needs 
-- to be OWNED by a superuser or the service_role user.
-- DELETE FROM auth.users WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- Grant access to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;