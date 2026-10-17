-- GitHub #569 / Linear TNYX-81: M1, owner-scoped Routine move to an existing Program.
-- Additive server contract only. No client UPDATE(program_id) grant, schema shape,
-- Flutter capability, default-Program discovery, Create & Move or quota policy.
-- Existing Routine/Exercise/Set UUIDs are retained; revision protects ABA.
create function public.move_user_workout_routine(
  p_routine_id uuid,
  p_source_program_id uuid,
  p_destination_program_id uuid,
  p_expected_revision bigint,
  p_client_mutation_id uuid
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_program_id uuid;
  v_revision bigint;
  v_last_mutation uuid;
  v_last_hash bytea;
  v_request_hash bytea;
  v_updated bigint;
  v_program uuid;
  v_source_exists boolean := false;
begin
  if v_user_id is null then
    raise exception 'routine_move_not_authenticated' using errcode = '28000';
  end if;
  if p_routine_id is null or p_source_program_id is null
      or p_destination_program_id is null or p_client_mutation_id is null
      or p_expected_revision is null or p_expected_revision < 0
      or p_expected_revision = 9223372036854775807
      or p_source_program_id = p_destination_program_id then
    raise exception 'invalid_routine_move_request' using errcode = '22023';
  end if;

  -- Match the Delete/Create account -> Program -> UUID -> Routine lock order.
  -- READ COMMITTED is required for retry visibility after a waited lock.
  if pg_catalog.current_setting('transaction_isolation') <> 'read committed' then
    raise exception 'routine_move_isolation_unsupported' using errcode = '25001';
  end if;

  perform 1 from public.users as account
  where account.id = v_user_id
  for key share;
  if not found then
    raise exception 'routine_move_not_found' using errcode = 'P0002';
  end if;

  -- Acquire available owner Program locks in stable UUID order, preserving
  -- the existing account -> Programs -> UUID -> Routine lock contract.
  -- The destination must exist. A source removed AFTER a successful Move
  -- may be absent only for a verifiable same-request replay, checked below.
  -- A new Move still requires its source to exist and be owner-matched.
  for v_program in
    select ids.program_id
    from (values (p_source_program_id), (p_destination_program_id))
      as ids(program_id)
    order by ids.program_id
  loop
    perform 1 from public.user_workout_programs as program
    where program.id = v_program and program.user_id = v_user_id
    for key share;
    if found then
      if v_program = p_source_program_id then
        v_source_exists := true;
      end if;
    elsif v_program = p_destination_program_id then
      raise exception 'routine_move_not_found' using errcode = 'P0002';
    end if;
  end loop;

  -- Uses the same private UUID lock as permanent Delete/anti-resurrection.
  perform private.lock_user_workout_routine_identity(p_routine_id);

  select routine.program_id, routine.composition_revision,
         routine.last_composition_mutation_id,
         routine.last_routine_update_request_hash
    into v_program_id, v_revision, v_last_mutation, v_last_hash
  from public.user_workout_routines as routine
  where routine.id = p_routine_id and routine.user_id = v_user_id
  for update;
  if not found then
    raise exception 'routine_move_not_found' using errcode = 'P0002';
  end if;

  -- Existing protected mutation/hash fields are the aggregate's most recent
  -- request discriminator. No new column and no ambiguity with Edit tokens.
  v_request_hash := pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_object(
      'action', 'move_routine_v1',
      'routine_id', p_routine_id::text,
      'source_program_id', p_source_program_id::text,
      'destination_program_id', p_destination_program_id::text,
      'expected_revision', p_expected_revision,
      'mutation_id', p_client_mutation_id::text
    )::text, 'UTF8'
  ));

  -- The exact committed retry is accepted ONLY while this is still the
  -- latest aggregate mutation, at the destination and at expected + 1.
  -- A later Edit, Delete or second Move invalidates this replay proof.
  if v_last_mutation = p_client_mutation_id then
    if v_last_hash is distinct from v_request_hash
        or v_program_id <> p_destination_program_id
        or v_revision <> p_expected_revision + 1 then
      raise exception 'routine_move_mutation_conflict' using errcode = 'P0001';
    end if;
    return v_revision;
  end if;

  -- Never interpret an absent/foreign source as permission for a new Move.
  -- Only a latest exact committed retry can skip that stale source lookup.
  if not v_source_exists then
    raise exception 'routine_move_not_found' using errcode = 'P0002';
  end if;

  if v_program_id <> p_source_program_id then
    raise exception 'routine_move_not_found' using errcode = 'P0002';
  end if;
  if v_revision <> p_expected_revision then
    raise exception 'routine_move_revision_conflict' using errcode = 'P0001';
  end if;

  -- One atomic parent-row update. Children reference the stable Routine UUID,
  -- and the existing owner-matched FK validates the destination.
  -- Invalidate pre-Move Edit/Save replay tokens and prevent A->B->A ABA.
  update public.user_workout_routines as routine
  set program_id = p_destination_program_id,
      composition_revision = v_revision + 1,
      last_composition_mutation_id = p_client_mutation_id,
      last_routine_update_request_hash = v_request_hash
  where routine.id = p_routine_id
    and routine.user_id = v_user_id
    and routine.program_id = p_source_program_id
    and routine.composition_revision = p_expected_revision;
  get diagnostics v_updated = row_count;
  if v_updated <> 1 then
    raise exception 'routine_move_revision_conflict' using errcode = 'P0001';
  end if;

  return v_revision + 1;
end;
$$;

-- REVIEW / MERGE-STAGE SAFETY: the function is deliberately dormant.
-- The legacy authenticated UPDATE(name) contract is still callable by older
-- clients and can rename a Routine from a stale pre-Move Program screen.
-- Granting EXECUTE now would expose Move while that bypass still exists.
-- A separate reviewed activation migration may grant authenticated EXECUTE
-- ONLY after the legacy write contract is retired safely. The function is
-- tested with a short-lived grant inside disposable CI, never in production.
revoke all on function public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)
  from public, anon, authenticated, service_role;

comment on function public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)
  is 'M1 staged dormant: owner-scoped atomic reparent with stable Routine/child IDs and CAS; EXECUTE intentionally withheld until legacy Rename compatibility is retired.';
