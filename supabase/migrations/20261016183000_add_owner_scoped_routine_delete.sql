-- GitHub #526 / Linear TNYX-81: owner-approved, Routine-only permanent Delete.
-- Additive SECDEF RPC: preserve older Create/Edit RPCs and all client grants.
-- DO NOT grant direct DELETE to authenticated on Routine, Exercise or Set.

create function public.delete_user_workout_routine(
  p_routine_id uuid,
  p_program_id uuid,
  p_expected_revision bigint
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_revision bigint;
  v_deleted bigint;
begin
  if v_user_id is null then
    raise exception 'routine_delete_not_authenticated' using errcode = '28000';
  end if;

  if p_routine_id is null
      or p_program_id is null
      or p_expected_revision is null
      or p_expected_revision < 0 then
    raise exception 'invalid_routine_delete_request' using errcode = '22023';
  end if;

  -- Owner / parent identity is the only visibility boundary. Lock the same
  -- parent row as the 4-arg and 7-arg Create/Edit/Save clients so Delete
  -- serializes with all in-flight aggregate Name+composition mutations.
  select routine.composition_revision into v_revision
  from public.user_workout_routines as routine
  where routine.id = p_routine_id
    and routine.program_id = p_program_id
    and routine.user_id = v_user_id
  for update;

  if not found then
    -- Missing, foreign-owned, wrong Program and already-deleted Routine are
    -- deliberately indistinguishable (no cross-user existence disclosure).
    raise exception 'routine_delete_not_found' using errcode = 'P0002';
  end if;

  if v_revision <> p_expected_revision then
    raise exception 'routine_delete_revision_conflict' using errcode = 'P0001';
  end if;

  -- Existing composite owner-bound FKs atomically cascade only THIS Routine's
  -- prescription Entries and Sets. They do not touch the parent Program or
  -- Exercise catalog/custom definitions. Future history/plan references are
  -- never explicitly deleted here.
  delete from public.user_workout_routines
  where id = p_routine_id
    and user_id = v_user_id
    and program_id = p_program_id
    and composition_revision = p_expected_revision;
  get diagnostics v_deleted = row_count;

  if v_deleted <> 1 then
    -- Defense in depth; never advertise deletion unless target row deleted.
    raise exception 'routine_delete_revision_conflict' using errcode = 'P0001';
  end if;

  return true;
end;
$$;

revoke all on function public.delete_user_workout_routine(uuid,uuid,bigint)
  from public, anon, authenticated, service_role;
grant execute on function public.delete_user_workout_routine(uuid,uuid,bigint)
  to authenticated;

comment on function public.delete_user_workout_routine(uuid,uuid,bigint)
  is 'Owner-scoped, revision-CAS hard delete of one Program Routine and FK-owned composition; no direct authenticated DELETE grant; not a Program Delete or Move Routine contract.';
