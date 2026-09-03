-- ============================================================================
-- Migration: 20260903052101_reconcile_legacy_lineage_state.sql
-- Description: Forward-only reconciliation of two legacy-lineage divergences
--              between supabase/migrations and the tio-world canonical schema.
-- ============================================================================
--
-- Why this migration exists
--
-- Two corrections were first attempted by editing the historical migrations
-- 20260814000001 and 20260814000002 in place. That was wrong. Per
-- docs/DATABASE_BACKUP_RECOVERY.md ("Migration Ownership"), applied history is
-- evidence, not a template to rewrite: corrections are forward-only. Both
-- historical files are preserved byte-for-byte, and the current corrections
-- live here instead, so a fresh replay converges on the canonical state by
-- following the same forward sequence production must follow.
--
-- Scope note: this migration deliberately does NOT touch
-- 20260816000004_reconcile_user_devices_app_build_type.sql. That TEXT ->
-- INTEGER conversion is still genuinely pending against hosted and keeps its
-- own execution gate.
--
-- Idempotent and fail-closed throughout: safe to run more than once, and it
-- aborts rather than guessing whenever reality does not match its
-- preconditions.

-- ----------------------------------------------------------------------------
-- 1. Retire the legacy owner tables created by 20260814000001
-- ----------------------------------------------------------------------------
-- public.user_targets and public.user_workout_preferences were superseded by
-- the canonical owners in 20260821161923_create_canonical_owner_tables
-- (user_nutrition_targets, user_wellness_targets, user_workout_targets).
-- Neither legacy table exists on tio-world hosted, and no migration ever
-- dropped them, so a fresh replay of the historical file would otherwise leave
-- two dead tables behind.
--
-- Deliberately NOT `drop table if exists ... cascade`:
--   * absent          -> no-op, because a replay must converge, not fail;
--   * present + rows  -> RAISE and abort. Another environment may hold real
--                        data these tables still own, and destroying it to
--                        tidy a schema is not a trade this migration may make;
--   * present + empty -> DROP TABLE with no CASCADE. If a view, foreign key or
--                        other dependency still points at it, the drop fails
--                        loudly. CASCADE would silently take that dependent
--                        object with it, which is exactly the outcome a
--                        reconciliation must not cause.

do $$
declare
  v_table text;
  v_rows  bigint;
begin
  foreach v_table in array array['user_workout_preferences', 'user_targets']
  loop
    if to_regclass('public.' || v_table) is null then
      raise notice 'reconcile_legacy_lineage_state: public.% already absent, skipping.', v_table;
      continue;
    end if;

    execute format('select count(*) from public.%I', v_table) into v_rows;

    if v_rows > 0 then
      raise exception
        'Refusing to drop public.% : it still holds % row(s). Migrate or archive that data, then re-run.',
        v_table, v_rows
        using errcode = 'raise_exception';
    end if;

    -- No CASCADE: a surviving dependency must surface as a failure.
    execute format('drop table public.%I', v_table);
    raise notice 'reconcile_legacy_lineage_state: dropped empty legacy table public.%.', v_table;
  end loop;
end
$$;

-- ----------------------------------------------------------------------------
-- 2. Canonical avatars bucket size limit
-- ----------------------------------------------------------------------------
-- 20260814000002 created the bucket at 5242880 (5 MB). The canonical value is
-- 10485760 (10 MB), which hosted has carried for some time with no migration
-- recording the decision. This is that missing source-control evidence.
--
-- Only file_size_limit is touched. The public flag, allowed_mime_types, the
-- Storage RLS policies and object ownership semantics are all left exactly as
-- the historical migration and later policy work established them.
--
-- Fail-closed: a missing bucket means this database is not in the state this
-- reconciliation was written against, so it aborts rather than creating one.

do $$
begin
  if not exists (select 1 from storage.buckets where id = 'avatars') then
    raise exception
      'Expected storage bucket "avatars" is absent; cannot reconcile its size limit.'
      using errcode = 'raise_exception';
  end if;

  update storage.buckets
  set file_size_limit = 10485760
  where id = 'avatars'
    and file_size_limit is distinct from 10485760;
end
$$;
