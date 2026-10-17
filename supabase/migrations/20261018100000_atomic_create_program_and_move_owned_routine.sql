-- GitHub #569 / Linear TNYX-81: M3B2A new-Program Move atomic DB contract.
-- Code-only, dormant. No table/column changes, hosted execution, direct
-- authenticated UPDATE(program_id), or new authenticated RPC EXECUTE grant.
-- This is a distinct endpoint from Move-to-existing; creating Program then
-- invoking the old Move RPC as two client requests is NOT transaction-safe.
create function public.create_program_and_move_user_workout_routine(
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
  v_program_id uuid;
  v_revision bigint;
  v_last_mutation uuid;
  v_last_hash bytea;
  v_request_hash bytea;
  v_program uuid;
  v_source_exists boolean := false;
  v_destination_exists boolean := false;
  v_updated bigint;
begin
  if v_user_id is null then
    raise exception 'routine_create_move_not_authenticated' using errcode = '28000';
  end if;

  if p_routine_id is null or p_source_program_id is null
      or p_new_program_id is null or p_client_mutation_id is null
      or p_new_program_name is null
      or pg_catalog.btrim(p_new_program_name,
        U&'\0009\000A\000B\000C\000D\0020\0085\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF'
      ) = ''
      or p_expected_revision is null or p_expected_revision < 0
      or p_expected_revision = 9223372036854775807
      or p_source_program_id = p_new_program_id then
    raise exception 'invalid_routine_create_move_request' using errcode = '22023';
  end if;

  -- Maintain the same account -> ordered Programs -> Routine UUID -> Routine
  -- row lock order used by Delete/Create and M1 Move to avoid cross-RPC
  -- deadlocks. The new destination has no row to lock until it is created.
  if pg_catalog.current_setting('transaction_isolation') <> 'read committed' then
    raise exception 'routine_create_move_isolation_unsupported'
      using errcode = '25001';
  end if;

  perform 1 from public.users as account
  where account.id = v_user_id
  for key share;
  if not found then
    raise exception 'routine_create_move_not_found' using errcode = 'P0002';
  end if;

  for v_program in
    select ids.program_id
    from (values (p_source_program_id), (p_new_program_id))
      as ids(program_id)
    order by ids.program_id
  loop
    perform 1 from public.user_workout_programs as program
    where program.id = v_program and program.user_id = v_user_id
    for key share;
    if found then
      if v_program = p_source_program_id then
        v_source_exists := true;
      else
        v_destination_exists := true;
      end if;
    end if;
  end loop;

  perform private.lock_user_workout_routine_identity(p_routine_id);

  select routine.program_id, routine.composition_revision,
         routine.last_composition_mutation_id,
         routine.last_routine_update_request_hash
    into v_program_id, v_revision, v_last_mutation, v_last_hash
  from public.user_workout_routines as routine
  where routine.id = p_routine_id and routine.user_id = v_user_id
  for update;

  if not found then
    raise exception 'routine_create_move_not_found' using errcode = 'P0002';
  end if;

  -- Same client-generated Program UUID and mutation token are frozen across
  -- network uncertainty. This hash binds all original request inputs;
  -- client retry with a new Program UUID/token is never safe by default.
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

  -- Exact latest successful request is idempotent: no second Program, no
  -- revision bump. The source may have since been removed; the owned
  -- destination must still exist and hold this unchanged Routine aggregate.
  if v_last_mutation = p_client_mutation_id then
    if v_last_hash is distinct from v_request_hash
        or v_program_id <> p_new_program_id
        or v_revision <> p_expected_revision + 1
        or not v_destination_exists then
      raise exception 'routine_create_move_mutation_conflict'
        using errcode = 'P0001';
    end if;
    return v_revision;
  end if;

  if not v_source_exists or v_program_id <> p_source_program_id then
    raise exception 'routine_create_move_not_found' using errcode = 'P0002';
  end if;

  if v_revision <> p_expected_revision then
    raise exception 'routine_create_move_revision_conflict'
      using errcode = 'P0001';
  end if;

  if v_destination_exists then
    raise exception 'routine_create_move_destination_conflict'
      using errcode = 'P0001';
  end if;

  -- This INSERT and the following guarded UPDATE are ONE RPC transaction:
  -- any failure (including FK/trigger/CAS conflict) rolls the Program back.
  -- No direct authenticated DELETE permission and no client-side compensation.
  begin
    insert into public.user_workout_programs (id, user_id, name)
    values (p_new_program_id, v_user_id, p_new_program_name);
  exception when unique_violation then
    -- Do not disclose whether a colliding ID belongs to another owner.
    raise exception 'routine_create_move_destination_conflict'
      using errcode = 'P0001';
  end;

  update public.user_workout_routines as routine
  set program_id = p_new_program_id,
      composition_revision = v_revision + 1,
      last_composition_mutation_id = p_client_mutation_id,
      last_routine_update_request_hash = v_request_hash
  where routine.id = p_routine_id
    and routine.user_id = v_user_id
    and routine.program_id = p_source_program_id
    and routine.composition_revision = p_expected_revision;
  get diagnostics v_updated = row_count;

  if v_updated <> 1 then
    raise exception 'routine_create_move_revision_conflict'
      using errcode = 'P0001';
  end if;

  return v_revision + 1;
end;
$$;

-- Staged SQL capability ONLY. Tested in disposable CI using an isolated
-- transaction-local or short-lived authenticated grant that is revoked.
-- Never expose the atomic Create & Move path before client/release gates.
revoke all on function public.create_program_and_move_user_workout_routine(
  uuid, uuid, uuid, text, bigint, uuid
) from public, anon, authenticated, service_role;

comment on function public.create_program_and_move_user_workout_routine(
  uuid, uuid, uuid, text, bigint, uuid
) is 'M3B2A dormant: one owner-scoped transaction creates a Program and reparents an existing Routine with CAS/one-use replay; no client grant or schema shape change.';
