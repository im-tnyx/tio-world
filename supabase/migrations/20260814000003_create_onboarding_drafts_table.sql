-- ============================================================================
-- Migration: 20260814000003_create_onboarding_drafts_table.sql
-- Description: Create dedicated onboarding draft persistence table with RLS.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.onboarding_drafts (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    schema_version INTEGER NOT NULL DEFAULT 1,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.onboarding_drafts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "onboarding_drafts_select_own" ON public.onboarding_drafts;
CREATE POLICY "onboarding_drafts_select_own"
    ON public.onboarding_drafts
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "onboarding_drafts_insert_own" ON public.onboarding_drafts;
CREATE POLICY "onboarding_drafts_insert_own"
    ON public.onboarding_drafts
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "onboarding_drafts_update_own" ON public.onboarding_drafts;
CREATE POLICY "onboarding_drafts_update_own"
    ON public.onboarding_drafts
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "onboarding_drafts_delete_own" ON public.onboarding_drafts;
CREATE POLICY "onboarding_drafts_delete_own"
    ON public.onboarding_drafts
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_onboarding_drafts_updated_at
    ON public.onboarding_drafts (updated_at);
