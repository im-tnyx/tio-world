-- ============================================================================
-- Migration: 20260816000001_add_last_login_at_to_user_devices.sql
-- Description: Add last_login_at, app_version, app_build, and fcm_token columns to public.user_devices
-- ============================================================================

ALTER TABLE public.user_devices
ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
ADD COLUMN IF NOT EXISTS app_version TEXT,
ADD COLUMN IF NOT EXISTS app_build TEXT,
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

CREATE INDEX IF NOT EXISTS idx_user_devices_last_login_at
    ON public.user_devices (last_login_at);
