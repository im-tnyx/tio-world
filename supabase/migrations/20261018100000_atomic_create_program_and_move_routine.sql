-- GitHub #569 / Linear TNYX-81: atomic new-Program destination for Move Routine.
-- No table/column change, no app callback and NO production EXECUTE grant.
-- The existing user-created Program contract is exactly id/user_id/name.
-- Calling this function is one transaction: failed reparenting cannot
-- leave an empty newly-created Program.
create function public.create_user_workout_program_and_move_routine(
  p_routine_id uuid,
  p_source_program_id uuid,
  p_new_program_id uuid,
  p_new_program_name text,
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
  v_current_program uuid;
  v_current_revision bigint;
  v_last_mutation uuid;
  v_last_hash bytea;
  v_request_hash bytea;
  v_source_exists boolean;
  v_inserted bigint;
  v_updated bigint;
begin
  if v_user_id is null then
    raise exception 'routine_create_move_not_authenticated'
      using errcode = '28000';
  end if;

  -- Match the canonical Dart Program trim semantics (Unicode White_Space/BOM).
  if p_routine_id is null
      or p_source_program_id is null
      or p_new_program_id is null
      or p_client_mutation_id is null
      or p_new_program_name is null
      or pg_catalog.btrim(p_new_program_name,
        U&'\0009\000A\000B\000C\000D\0020\0085\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF'
      ) = ''
      or p_expected_revision is null or p_expected_revision < 0
      or p_expected_revision = 9223372036854775807
      or p_source_program_id = p_new_program_id then
    raise exception 'invalid_routine_create_move_request'
      using errcode = '22023';
  end if;

  -- Keep the same account -> owner Program -> Routine UUID -> Routine row
  -- lock order as protected Create/Move and Delete/anti-resurrection.
  if pg_catalog.current_setting('transaction_isolation') <> 'read committed' then
    raise exception 'routine_create_move_isolation_unsupported'
      using errcode = '25001';
  end if;

  perform 1 from public.users as account
    where account.id = v_user_id for key share;
  if not found then
    raise exception 'routine_create_move_not_found' using errcode = 'P0002';
  end if;

  perform 1 from public.user_workout_programs as program
    where program.id = p_source_program_id and program.user_id = v_user_id
    for key share;
  v_source_exists := found;

  perform private.lock_user_workout_routine_identity(p_routine_id);
  select routine.program_id, routine.composition_revision,
         routine.last_composition_mutation_id,
         routine.last_routine_update_request_hash
    into v_current_program, v_current_revision, v_last_mutation, v_last_hash
  from public.user_workout_routines as routine
  where routine.id = p_routine_id and routine.user_id = v_user_id
  for update;
  if not found then
    raise exception 'routine_create_move_not_found' using errcode = 'P0002';
  end if;

  -- Fingerprint every immutable input, including the user-edited Program name.
  -- Later Edit/Rename/Move must invalidate this same-request replay proof.
  v_request_hash := pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_object(
      'action', 'create_program_and_move_routine_v1',
      'routine_id', p_routine_id::text,
      'source_program_id', p_source_program_id::text,
      'new_program_id', p_new_program_id::text,
      'new_program_name', p_new_program_name,
      'expected_revision', p_expected_revision,
      'mutation_id', p_client_mutation_id::text
    )::text, 'UTF8'
  ));

  if v_last_mutation = p_client_mutation_id then
    if v_last_hash is distinct from v_request_hash
        or v_current_program <> p_new_program_id
        or v_current_revision <> p_expected_revision + 1 then
      raise exception 'routine_create_move_mutation_conflict'
        using errcode = 'P0001';
    end if;
    -- Do not require a name match here: the destination may subsequently
    -- be renamed without changing the Routine's latest aggregate mutation.
    perform 1 from public.user_workout_programs as program
      where program.id = p_new_program_id and program.user_id = v_user_id
      for key share;
    if not found then
      raise exception 'routine_create_move_not_found' using errcode = 'P0002';
    end if;
    return v_current_revision;
  end if;

  if not v_source_exists or v_current_program <> p_source_program_id then
    raise exception 'routine_create_move_not_found' using errcode = 'P0002';
  end if;
  if v_current_revision <> p_expected_revision then
    raise exception 'routine_create_move_revision_conflict'
      using errcode = 'P0001';
  end if;

  -- The new Program UUID is client-generated and stable across uncertain
  -- results. Never reuse an existing Program ID, even if owner/name match:
  -- only the exact already-committed aggregate token is an idempotent replay.
  insert into public.user_workout_programs (id, user_id, name)
  values (p_new_program_id, v_user_id, p_new_program_name)
  on conflict (id) do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted <> 1 then
    raise exception 'routine_create_move_program_conflict'
      using errcode = 'P0001';
  end if;

  -- Same stable Routine/Exercise/Set UUIDs and composition, one revision bump.
  -- Any failure here aborts the entire transaction and rolls back the Program
  -- INSERT. Do not use the public existing-Program RPC as a second client call.
  update public.user_workout_routines as routine
  set program_id = p_new_program_id,
      composition_revision = v_current_revision + 1,
      last_composition_mutation_id = p_client_mutation_id,
      last_routine_update_request_hash = v_request_hash
  where routine.id = p_routine_id and routine.user_id = v_user_id
    and routine.program_id = p_source_program_id
    and routine.composition_revision = p_expected_revision;
  get diagnostics v_updated = row_count;
  if v_updated <> 1 then
    raise exception 'routine_create_move_revision_conflict'
      using errcode = 'P0001';
  end if;

  return v_current_revision + 1;
end;
$$;

-- Additive staged contract, intentionally unreachable to Data API clients.
revoke all on function public.create_user_workout_program_and_move_routine(
  uuid,uuid,uuid,text,bigint,uuid
) from public, anon, authenticated, service_role;

comment on function public.create_user_workout_program_and_move_routine(
  uuid,uuid,uuid,text,bigint,uuid
) is 'Dormant #569 atomic Create Program + reparent one owner Routine; stable IDs, revision CAS, exact-token replay. EXECUTE withheld until reviewed Flutter activation gate.';
