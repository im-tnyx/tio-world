-- ============================================================================
-- Migration: 20260815000003_delete_user_account_rpc.sql
-- Description: Create atomic RPC function to securely delete user account, storage objects, and cascade data.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, storage
AS $$
DECLARE
    current_uid UUID;
BEGIN
    current_uid := auth.uid();
    IF current_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 1. Clean up user storage objects (avatars / uploads)
    BEGIN
        DELETE FROM storage.objects
        WHERE bucket_id = 'avatars'
          AND (storage.foldername(name))[1] = current_uid::text;
    EXCEPTION
        WHEN OTHERS THEN
            -- Storage cleanup failure should not prevent user deletion
            NULL;
    END;

    -- 2. Explicitly delete user profile and data (will cascade to child tables)
    DELETE FROM public.users WHERE id = current_uid;
    DELETE FROM public.onboarding_drafts WHERE user_id = current_uid;
    DELETE FROM public.user_devices WHERE user_id = current_uid;

    -- 3. Delete the user from auth.users (cascades sessions, identities, MFA)
    DELETE FROM auth.users WHERE id = current_uid;
END;
$$;

-- Grant execution permission to authenticated users
REVOKE EXECUTE ON FUNCTION public.delete_user_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
