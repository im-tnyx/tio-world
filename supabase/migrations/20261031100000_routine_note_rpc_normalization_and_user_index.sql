-- Normalize direct RPC bodies before legacy validation and request hashing.
-- Add the unfiltered owner index required by the user-wide quota trigger.

create or replace function public.mutate_user_workout_routine_note(
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
  v_body text;
  v_result jsonb;
  v_snapshot jsonb;
begin
  if pg_catalog.lower(pg_catalog.btrim(coalesce(p_operation, '')))
      in ('create', 'update') then
    v_body := private.normalize_user_workout_routine_note_body(p_body);
  else
    v_body := p_body;
  end if;

  v_result := public.mutate_user_workout_routine_note_legacy(
    p_operation,
    p_note_id,
    p_routine_id,
    p_exercise_ref,
    p_note_type,
    v_body,
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

create index idx_user_workout_routine_notes_user_id
  on public.user_workout_routine_notes (user_id);
