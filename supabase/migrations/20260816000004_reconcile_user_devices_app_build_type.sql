-- ============================================================================
-- Migration: 20260816000004_reconcile_user_devices_app_build_type.sql
-- Description: Reconcile public.user_devices.app_build column type from TEXT to INTEGER
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'user_devices'
          AND column_name = 'app_build'
          AND data_type = 'text'
    ) THEN
        ALTER TABLE public.user_devices
            ALTER COLUMN app_build TYPE INTEGER
            USING NULLIF(regexp_replace(app_build, '[^0-9]', '', 'g'), '')::INTEGER;
    END IF;
END $$;

COMMENT ON COLUMN public.user_devices.app_build IS
    'Flutter app numeric build number (e.g. 1, 42). Stored as integer.';
