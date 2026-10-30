-- TNYX-81 / PR #717
-- Add immutable mutation-result snapshots without changing the approved
-- Routine Notes normalization, quota, identity or UI contracts.

-- The receipt table is the shared write boundary for the legacy mutation RPC.
-- Hold this lock for the migration transaction so in-flight receipt writes
-- finish before the compatibility check and new writes cannot enter while
-- the snapshot behavior is being installed.
lock table private.user_workout_routine_note_mutations in access exclusive mode;

alter table private.user_workout_routine_note_mutations
  add column result_snapshot jsonb;

alter table private.user_workout_routine_note_mutations
  add constraint user_workout_routine_note_mutations_snapshot_check
  check (
    result_snapshot is null
    or pg_catalog.jsonb_typeof(result_snapshot) = 'object'
  );

-- This is the critical compatibility barrier. It must run before either public
-- mutation/reconciliation function changes so a legacy receipt failure rolls
-- back the column and leaves the original RPC behavior intact.
do $$
begin
  if exists (
    select 1
    from private.user_workout_routine_note_mutations
    where result_snapshot is null
  ) then
    raise exception 'routine_note_legacy_receipt_snapshot_required'
      using
        errcode = 'P0001',
        detail = 'Existing mutation receipts are missing immutable result snapshots; this migration does not backfill historical results.',
        hint = 'Resolve the legacy receipt set under the approved release procedure, then rerun the migration.';
  end if;
end;
$$;

create function private.user_workout_routine_note_receipt_snapshot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_note jsonb;
begin
  if new.result_kind = 'applied' then
    v_note := private.user_workout_routine_note_payload(
      new.user_id,
      new.note_id
    );
    if v_note is null then
      raise exception 'routine_note_mutation_snapshot_unavailable'
        using errcode = 'P0001';
    end if;
    new.result_snapshot := pg_catalog.jsonb_build_object(
      'status', 'applied',
      'note', v_note,
      'note_id', new.note_id,
      'revision', new.result_revision
    );
  elsif new.result_kind = 'deleted' then
    new.result_snapshot := pg_catalog.jsonb_build_object(
      'status', 'deleted',
      'note_id', new.note_id,
      'revision', new.result_revision
    );
  else
    raise exception 'routine_note_mutation_snapshot_unavailable'
      using errcode = 'P0001';
  end if;
  return new;
end;
$$;

revoke all on function private.user_workout_routine_note_receipt_snapshot()
  from public, anon, authenticated, service_role;

create trigger trg_user_workout_routine_note_receipt_snapshot
before insert on private.user_workout_routine_note_mutations
for each row
execute function private.user_workout_routine_note_receipt_snapshot();

-- Keep the already-reviewed mutation implementation as the write path. The
-- public wrapper below only replaces successful replay output with the stored
-- historical result, so existing locks, authorization and revision behavior
-- remain in one canonical implementation.
alter function public.mutate_user_workout_routine_note(
  text, uuid, uuid, text, text, text, bigint, uuid
) rename to mutate_user_workout_routine_note_legacy;

revoke all on function public.mutate_user_workout_routine_note_legacy(
  text, uuid, uuid, text, text, text, bigint, uuid
) from public, anon, authenticated, service_role;

create function public.mutate_user_workout_routine_note(
  p_operation text,
  p_note_id uuid,
  p_routine_id uuid,
  p_exercise_ref text,
  p_note_type text,
  p_body text,
  p_expected_revision bigint,
  p_mutation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_result jsonb;
  v_snapshot jsonb;
begin
  v_result := public.mutate_user_workout_routine_note_legacy(
    p_operation,
    p_note_id,
    p_routine_id,
    p_exercise_ref,
    p_note_type,
    p_body,
    p_expected_revision,
    p_mutation_id
  );

  select receipt.result_snapshot
    into v_snapshot
  from private.user_workout_routine_note_mutations as receipt
  where receipt.user_id = v_user_id
    and receipt.mutation_id = p_mutation_id;

  if not found or v_snapshot is null then
    raise exception 'routine_note_mutation_snapshot_unavailable'
      using errcode = 'P0001';
  end if;

  return v_snapshot;
end;
$$;

revoke all on function public.mutate_user_workout_routine_note(
  text, uuid, uuid, text, text, text, bigint, uuid
) from public, anon, authenticated, service_role;
grant execute on function public.mutate_user_workout_routine_note(
  text, uuid, uuid, text, text, text, bigint, uuid
) to authenticated;

create or replace function public.reconcile_user_workout_routine_note_mutation(
  p_mutation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_snapshot jsonb;
begin
  if v_user_id is null then
    raise exception 'routine_note_not_authenticated' using errcode = '28000';
  end if;
  if p_mutation_id is null then
    raise exception 'invalid_routine_note_mutation' using errcode = '22023';
  end if;

  select receipt.result_snapshot
    into v_snapshot
  from private.user_workout_routine_note_mutations as receipt
  where receipt.user_id = v_user_id
    and receipt.mutation_id = p_mutation_id;

  if not found then
    return pg_catalog.jsonb_build_object('status', 'pending');
  end if;
  if v_snapshot is null then
    raise exception 'routine_note_mutation_snapshot_unavailable'
      using errcode = 'P0001';
  end if;
  return v_snapshot;
end;
$$;

revoke all on function public.reconcile_user_workout_routine_note_mutation(uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.reconcile_user_workout_routine_note_mutation(uuid)
  to authenticated;

-- The later legacy-receipt migration remains as a defense-in-depth invariant
-- check for deployments that replay the boundary independently.
