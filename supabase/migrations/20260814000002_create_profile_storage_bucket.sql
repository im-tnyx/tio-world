-- ============================================================================
-- Migration: 20260814000002_create_profile_storage_bucket.sql
-- Description: Create Supabase Storage bucket for profile avatars with RLS policies.
--
-- Canonical file_size_limit is 10485760 (10 MB), on both the INSERT and the
-- ON CONFLICT path. It was 5242880 (5 MB) here while hosted has long been
-- 10 MB, so replaying this file would have silently downgraded a live bucket
-- setting with no error -- the DO UPDATE makes it an overwrite, not a no-op.
-- Mime types and ownership policies are deliberately unchanged.
-- ============================================================================

-- 1. Insert bucket if not exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    10485760, -- 10 MB limit (canonical; matches hosted)
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 10485760,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- 2. Storage RLS Policies
-- Allow anyone to view public avatar objects
DROP POLICY IF EXISTS "avatars_public_select" ON storage.objects;
CREATE POLICY "avatars_public_select"
    ON storage.objects
    FOR SELECT
    USING (bucket_id = 'avatars');

-- Allow authenticated users to upload avatar to their own user_id folder: <user_id>/...
DROP POLICY IF EXISTS "avatars_user_insert" ON storage.objects;
CREATE POLICY "avatars_user_insert"
    ON storage.objects
    FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow authenticated users to update their own avatar
DROP POLICY IF EXISTS "avatars_user_update" ON storage.objects;
CREATE POLICY "avatars_user_update"
    ON storage.objects
    FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    )
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Allow authenticated users to delete their own avatar
DROP POLICY IF EXISTS "avatars_user_delete" ON storage.objects;
CREATE POLICY "avatars_user_delete"
    ON storage.objects
    FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'avatars'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- 3. Ensure avatar_url column exists in public.users table
ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS avatar_url TEXT;
