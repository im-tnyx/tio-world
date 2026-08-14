-- ============================================================================
-- Migration: 20260814000004_add_plan_to_users_table.sql
-- Description: Add plan column to users table with default 'free'.
-- ============================================================================

ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS plan TEXT NOT NULL DEFAULT 'free';
