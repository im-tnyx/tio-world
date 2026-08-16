-- ============================================================================
-- Migration: 20260816000002_add_recommended_indexes.sql
-- Description: Production-grade indexes based on Supabase & Postgres Performance Best Practices.
-- Optimizes RLS evaluation, Foreign Key lookups, and fast auth/search queries.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. users table indexes
-- ----------------------------------------------------------------------------
-- Fast lookup by email (Case-insensitive unique lookup)
CREATE INDEX IF NOT EXISTS idx_users_email_lower
    ON public.users (lower(email))
    WHERE email IS NOT NULL;

-- Fast lookup by username (Case-insensitive)
CREATE INDEX IF NOT EXISTS idx_users_username_lower
    ON public.users (lower(username))
    WHERE username IS NOT NULL;

-- Fast lookup by mobile number (OTP / Truecaller / Phone login)
CREATE INDEX IF NOT EXISTS idx_users_mobile
    ON public.users (mobile)
    WHERE mobile IS NOT NULL;

-- Fast lookup by referral code
CREATE INDEX IF NOT EXISTS idx_users_referral_code
    ON public.users (referral_code)
    WHERE referral_code IS NOT NULL;

-- Foreign key index on referred_by_id (Critical for joins and cascading)
CREATE INDEX IF NOT EXISTS idx_users_referred_by_id
    ON public.users (referred_by_id)
    WHERE referred_by_id IS NOT NULL;

-- Partial index for active and onboarded users (Analytics & batch queries)
CREATE INDEX IF NOT EXISTS idx_users_active_onboarded
    ON public.users (id)
    WHERE is_active = true AND is_onboarded = true;


-- ----------------------------------------------------------------------------
-- 2. user_devices table indexes
-- ----------------------------------------------------------------------------
-- Foreign key index on user_id (Critical for RLS policy evaluation and JOINs)
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id
    ON public.user_devices (user_id);

-- Lookup by device_id (Hardware checks, token lookups, trial validation)
CREATE INDEX IF NOT EXISTS idx_user_devices_device_id
    ON public.user_devices (device_id);

-- Device activity sorting / pruning
CREATE INDEX IF NOT EXISTS idx_user_devices_last_active_at
    ON public.user_devices (last_active_at DESC NULLS LAST);

-- Device login audit
CREATE INDEX IF NOT EXISTS idx_user_devices_last_login_at
    ON public.user_devices (last_login_at DESC NULLS LAST);


-- ----------------------------------------------------------------------------
-- 3. onboarding_drafts table indexes
-- ----------------------------------------------------------------------------
-- Foreign key / RLS index on user_id
CREATE INDEX IF NOT EXISTS idx_onboarding_drafts_user_id
    ON public.onboarding_drafts (user_id);

-- Sorting by updated_at for draft resumption
CREATE INDEX IF NOT EXISTS idx_onboarding_drafts_updated_at
    ON public.onboarding_drafts (updated_at DESC);


-- ----------------------------------------------------------------------------
-- 4. user_nutrition_profiles & user_workout_profiles indexes
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_user_nutrition_profiles_user_id
    ON public.user_nutrition_profiles (user_id);

CREATE INDEX IF NOT EXISTS idx_user_workout_profiles_user_id
    ON public.user_workout_profiles (user_id);
