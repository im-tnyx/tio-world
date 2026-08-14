-- ============================================================================
-- Migration: 20260814000001_create_onboarding_owner_tables.sql
-- Description: Create core owner tables for Profile, Workout Preferences, and Targets with RLS.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Users Table (Owner: Profile / User)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    username TEXT UNIQUE,
    plan TEXT NOT NULL DEFAULT 'free',
    gender TEXT NOT NULL,
    goals TEXT[] NOT NULL,
    date_of_birth DATE NOT NULL,
    height_cm NUMERIC NOT NULL,
    current_weight_kg NUMERIC NOT NULL,
    target_weight_kg NUMERIC,
    activity_level TEXT NOT NULL,
    health_conditions TEXT[] NOT NULL DEFAULT '{}',
    other_health_condition TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_own"
    ON public.users
    FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "users_insert_own"
    ON public.users
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "users_update_own"
    ON public.users
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);


-- ----------------------------------------------------------------------------
-- 2. User Workout Preferences Table (Owner: Workout)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_workout_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    gym_access TEXT NOT NULL,
    equipment TEXT[] NOT NULL DEFAULT '{}',
    experience_level TEXT NOT NULL,
    focus_areas TEXT[] NOT NULL DEFAULT '{}',
    training_days TEXT[] NOT NULL DEFAULT '{}',
    workout_duration TEXT NOT NULL,
    workout_split TEXT NOT NULL,
    health_concerns TEXT,
    special_event TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.user_workout_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_workout_preferences_select_own"
    ON public.user_workout_preferences
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "user_workout_preferences_insert_own"
    ON public.user_workout_preferences
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_workout_preferences_update_own"
    ON public.user_workout_preferences
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 3. User Targets Table (Owner: Nutrition / Targets)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_targets (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    daily_steps INTEGER NOT NULL,
    sleep_target_minutes INTEGER NOT NULL,
    sleep_time_minutes INTEGER NOT NULL,
    wake_time_minutes INTEGER NOT NULL,
    water_ml INTEGER NOT NULL,
    goal_pace_kg_per_week NUMERIC NOT NULL,
    target_weight_kg NUMERIC,
    target_calories INTEGER,
    target_protein_grams INTEGER,
    target_carbs_grams INTEGER,
    target_fat_grams INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.user_targets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_targets_select_own"
    ON public.user_targets
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "user_targets_insert_own"
    ON public.user_targets
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_targets_update_own"
    ON public.user_targets
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ----------------------------------------------------------------------------
-- 4. Explicit Performance & Case-Insensitive Indexes
-- ----------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_lower
    ON public.users (LOWER(username));

CREATE INDEX IF NOT EXISTS idx_users_created_at
    ON public.users (created_at);

CREATE INDEX IF NOT EXISTS idx_user_workout_preferences_created_at
    ON public.user_workout_preferences (created_at);

CREATE INDEX IF NOT EXISTS idx_user_targets_created_at
    ON public.user_targets (created_at);
