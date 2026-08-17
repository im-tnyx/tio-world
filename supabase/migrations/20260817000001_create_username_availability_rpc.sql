-- ============================================================================
-- Migration: 20260817000001_create_username_availability_rpc.sql
-- Description: Expose a narrow authenticated-only username availability check without broad users-table reads.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_username_available(p_username text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    current_uid uuid;
    normalized_username text;
BEGIN
    current_uid := auth.uid();
    IF current_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
    END IF;

    normalized_username := lower(btrim(p_username));

    IF normalized_username IS NULL
       OR char_length(normalized_username) < 3
       OR char_length(normalized_username) > 30
       OR normalized_username !~ '^[a-z0-9._]+$' THEN
        RETURN false;
    END IF;

    RETURN NOT EXISTS (
        SELECT 1
        FROM public.users AS u
        WHERE lower(u.username) = normalized_username
          AND u.id <> current_uid
    );
END;
$$;

-- SECURITY DEFINER is intentional here because public.users SELECT is owner-scoped.
-- The function returns only a boolean and is callable only by authenticated users.
REVOKE EXECUTE ON FUNCTION public.is_username_available(text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.is_username_available(text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_username_available(text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.is_username_available(text) TO authenticated;
