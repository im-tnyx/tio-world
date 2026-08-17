-- ============================================================================
-- Migration: 20260815000002_create_tnyxhub_canonical_tables.sql
-- Description: Align public.users and create canonical tnyxhub profile tables:
--              1. public.users
--              2. public.user_nutrition_profiles
--              3. public.user_workout_profiles
--              4. public.user_devices
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Align public.users
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR,
    ADD COLUMN IF NOT EXISTS name VARCHAR,
    ADD COLUMN IF NOT EXISTS username VARCHAR,
    ADD COLUMN IF NOT EXISTS email VARCHAR,
    ADD COLUMN IF NOT EXISTS mobile VARCHAR,
    ADD COLUMN IF NOT EXISTS profile_image TEXT,
    ADD COLUMN IF NOT EXISTS avatar_url TEXT,
    ADD COLUMN IF NOT EXISTS gender VARCHAR,
    ADD COLUMN IF NOT EXISTS dob DATE,
    ADD COLUMN IF NOT EXISTS date_of_birth DATE,
    ADD COLUMN IF NOT EXISTS timezone VARCHAR,
    ADD COLUMN IF NOT EXISTS is_onboarded BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS best_streak INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS referral_code VARCHAR,
    ADD COLUMN IF NOT EXISTS referred_by_id UUID,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
    ADD COLUMN IF NOT EXISTS plan TEXT NOT NULL DEFAULT 'free',
    ADD COLUMN IF NOT EXISTS height_cm NUMERIC,
    ADD COLUMN IF NOT EXISTS current_weight_kg NUMERIC,
    ADD COLUMN IF NOT EXISTS activity_level VARCHAR,
    ADD COLUMN IF NOT EXISTS primary_goal VARCHAR,
    ADD COLUMN IF NOT EXISTS health_conditions TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS other_health_condition TEXT,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS mobile_verified_at TIMESTAMPTZ;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_select_own" ON public.users;
CREATE POLICY "users_select_own"
    ON public.users
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own"
    ON public.users
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own"
    ON public.users
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);


-- ----------------------------------------------------------------------------
-- 2. Create public.user_nutrition_profiles (Canonical Nutrition & Targets)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_nutrition_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    height_cm NUMERIC,
    current_weight_kg NUMERIC,
    target_weight_kg NUMERIC,
    weekly_weight_change_kg NUMERIC,
    bed_time TIME,
    wake_up_time TIME,
    activity_level VARCHAR,
    steps_target INTEGER,
    water_target_ml NUMERIC,
    preferred_diet VARCHAR,
    allergies TEXT[] DEFAULT '{}',
    disliked_foods TEXT[] DEFAULT '{}',
    medical_conditions TEXT[] DEFAULT '{}',
    macro_targets JSONB,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.user_nutrition_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_nutrition_profiles_select_own" ON public.user_nutrition_profiles;
CREATE POLICY "user_nutrition_profiles_select_own"
    ON public.user_nutrition_profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_nutrition_profiles_insert_own" ON public.user_nutrition_profiles;
CREATE POLICY "user_nutrition_profiles_insert_own"
    ON public.user_nutrition_profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_nutrition_profiles_update_own" ON public.user_nutrition_profiles;
CREATE POLICY "user_nutrition_profiles_update_own"
    ON public.user_nutrition_profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_nutrition_profiles_delete_own" ON public.user_nutrition_profiles;
CREATE POLICY "user_nutrition_profiles_delete_own"
    ON public.user_nutrition_profiles
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 3. Create public.user_workout_profiles (Canonical Workout Preferences)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_workout_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    experience_level VARCHAR,
    special_event_goal VARCHAR,
    workout_location VARCHAR,
    available_equipment TEXT[] DEFAULT '{}',
    workout_duration_mins INTEGER,
    training_days TEXT[] DEFAULT '{}',
    split_program VARCHAR,
    focus_areas TEXT[] DEFAULT '{}',
    health_concerns TEXT[] DEFAULT '{}',
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.user_workout_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_workout_profiles_select_own" ON public.user_workout_profiles;
CREATE POLICY "user_workout_profiles_select_own"
    ON public.user_workout_profiles
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_workout_profiles_insert_own" ON public.user_workout_profiles;
CREATE POLICY "user_workout_profiles_insert_own"
    ON public.user_workout_profiles
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_workout_profiles_update_own" ON public.user_workout_profiles;
CREATE POLICY "user_workout_profiles_update_own"
    ON public.user_workout_profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_workout_profiles_delete_own" ON public.user_workout_profiles;
CREATE POLICY "user_workout_profiles_delete_own"
    ON public.user_workout_profiles
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 4. Create public.user_devices (Canonical Hardware & Tokens)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id VARCHAR NOT NULL,
    device_fingerprint TEXT NOT NULL,
    is_trial_used BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()),
    platform VARCHAR,
    os_version VARCHAR,
    app_version VARCHAR,
    last_login_at TIMESTAMPTZ,
    fcm_token TEXT,
    app_build INTEGER,
    CONSTRAINT uq_user_devices_user_device UNIQUE(user_id, device_id)
);

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_devices_select_own" ON public.user_devices;
CREATE POLICY "user_devices_select_own"
    ON public.user_devices
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_devices_insert_own" ON public.user_devices;
CREATE POLICY "user_devices_insert_own"
    ON public.user_devices
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_devices_update_own" ON public.user_devices;
CREATE POLICY "user_devices_update_own"
    ON public.user_devices
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_devices_delete_own" ON public.user_devices;
CREATE POLICY "user_devices_delete_own"
    ON public.user_devices
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
