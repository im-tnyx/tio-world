-- ============================================================================
-- Migration: 20260814000001_create_onboarding_owner_tables.sql
-- Description: Create the core Profile owner table (public.users) with RLS.
--
-- Scope note (migration-lineage reconciliation, 2026-09-03):
-- This migration originally also created public.user_workout_preferences and
-- public.user_targets. Both are RETIRED legacy owners: neither exists on the
-- tio-world hosted database, and no later migration drops them, so replaying
-- this file as written would CREATE two dead tables in an environment that has
-- never had them. Their blocks are removed here rather than left for a future
-- `db push` to resurrect. Nothing replaces them -- the current owners are
-- public.user_nutrition_targets, public.user_wellness_targets and
-- public.user_workout_targets, created by 20260821161923_create_canonical_owner_tables.
-- A fresh database built from this directory must NOT recreate the retired owners.
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
-- 2. Explicit Performance & Case-Insensitive Indexes
-- ----------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username_lower
    ON public.users (LOWER(username));

CREATE INDEX IF NOT EXISTS idx_users_created_at
    ON public.users (created_at);
