-- GitHub #569 / Linear TNYX-81: M5B-B1 Full Undo for atomic Create & Move.
-- Owner-approved bounded backend slice. Hosted deployment and client EXECUTE
-- activation remain separate approvals.

alter table public.user_workout_programs
  add column create_move_mutation_id uuid,
  add column create_move_routine_id uuid,
  add column create_move_source_program_id uuid,
  add constraint user_workout_programs_create_move_provenance_coherent
    check (
      (create_move_mutation_id is null
       and create_move_routine_id is null
       and create_move_source_program_id is null)
      or
      (create_move_mutation_id is not null
       and create_move_routine_id is not null
       and create_move_source_program_id is not null)
    );

create or replace function public.create_user_workout_program_and_move_routine(
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
  v_source_exists boolean := false;
  v_destination_exists boolean := false;
  v_program uuid;
  v_inserted bigint;
  v_updated bigint;
begin
  if v_user_id is null then
    raise exception 'routine_create_move_not_authenticated'
      using errcode = '28000';
  end if;

  if not exists (
    select 1 from auth.users as auth_identity
    where auth_identity.id = v_user_id
      and auth_identity.is_anonymous is false
  ) then
    raise exception 'routine_create_move_registered_account_required'
      using errcode = '28000';
  end if;

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

  if pg_catalog.current_setting('transaction_isolation') <> 'read committed' then
    raise exception 'routine_create_move_isolation_unsupported'
      using errcode = '25001';
  end if;

  perform 1 from public.users as account
    where account.id = v_user_id for key share;
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
    into v_current_program, v_current_revision, v_last_mutation, v_last_hash
  from public.user_workout_routines as routine
  where routine.id = p_routine_id and routine.user_id = v_user_id
  for update;
  if not found then
    raise exception 'routine_create_move_not_found' using errcode = 'P0002';
  end if;

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
    return v_current_revision;
  end if;

  if not v_source_exists or v_current_program <> p_source_program_id then
    raise exception 'routine_create_move_not_found' using errcode = 'P0002';
  end if;
  if v_current_revision <> p_expected_revision then
    raise exception 'routine_create_move_revision_conflict'
      using errcode = 'P0001';
  end if;
  if v_destination_exists then
    raise exception 'routine_create_move_program_conflict'
      using errcode = 'P0001';
  end if;

  insert into public.user_workout_programs (
    id, user_id, name, create_move_mutation_id,
    create_move_routine_id, create_move_source_program_id
  )
  values (
    p_new_program_id, v_user_id, p_new_program_name, p_client_mutation_id,
    p_routine_id, p_source_program_id
  )
  on conflict (id) do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted <> 1 then
    raise exception 'routine_create_move_program_conflict'
      using errcode = 'P0001';
  end if;

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

create or replace function public.undo_create_user_workout_program_and_move_routine(
  p_routine_id uuid,
  p_original_program_id uuid,
  p_created_program_id uuid,
  p_original_move_mutation_id uuid,
  p_expected_revision bigint,
  p_undo_mutation_id uuid
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_routine_program_id uuid;
  v_revision bigint;
  v_last_mutation uuid;
  v_last_hash bytea;
  v_original_hash bytea;
  v_undo_hash bytea;
  v_program uuid;
  v_original_exists boolean := false;
  v_created_exists boolean := false;
  v_created_is_default boolean;
  v_created_name text;
  v_created_at timestamptz;
  v_created_updated_at timestamptz;
  v_routines_in_created bigint;
  v_updated bigint;
  v_deleted bigint;
begin
  if v_user_id is null then
    raise exception 'routine_create_move_undo_not_authenticated'
      using errcode = '28000';
  end if;

  if not exists (
    select 1 from auth.users as auth_identity
    where auth_identity.id = v_user_id
      and auth_identity.is_anonymous is false
  ) then
    raise exception 'routine_create_move_undo_registered_account_required'
      using errcode = '28000';
  end if;

  if p_routine_id is null
      or p_original_program_id is null
      or p_created_program_id is null
      or p_original_move_mutation_id is null
      or p_undo_mutation_id is null
      or p_expected_revision is null
      or p_expected_revision < 1
      or p_expected_revision = 9223372036854775807
      or p_original_program_id = p_created_program_id
      or p_original_move_mutation_id = p_undo_mutation_id then
    raise exception 'invalid_routine_create_move_undo_request'
      using errcode = '22023';
  end if;

  if pg_catalog.current_setting('transaction_isolation') <> 'read committed' then
    raise exception 'routine_create_move_undo_isolation_unsupported'
      using errcode = '25001';
  end if;

  perform 1 from public.users as account
    where account.id = v_user_id for key share;
  if not found then
    raise exception 'routine_create_move_undo_not_found' using errcode = 'P0002';
  end if;

  -- The same account -> Programs (sorted UUID) -> Routine UUID -> Routine row
  -- hierarchy is used by Move/Create/Delete, preventing lock-order deadlocks.
  for v_program in
    select ids.program_id
    from (values (p_original_program_id), (p_created_program_id))
      as ids(program_id)
    order by ids.program_id
  loop
    perform 1 from public.user_workout_programs as program
    where program.id = v_program and program.user_id = v_user_id
    for update;
    if found then
      if v_program = p_original_program_id then
        v_original_exists := true;
      else
        v_created_exists := true;
        select program.is_default, program.name, program.created_at,
               program.updated_at
          into v_created_is_default, v_created_name,
               v_created_at, v_created_updated_at
        from public.user_workout_programs as program
        where program.id = v_program and program.user_id = v_user_id;
      end if;
    end if;
  end loop;

  perform private.lock_user_workout_routine_identity(p_routine_id);
  select routine.program_id, routine.composition_revision,
         routine.last_composition_mutation_id,
         routine.last_routine_update_request_hash
    into v_routine_program_id, v_revision, v_last_mutation, v_last_hash
  from public.user_workout_routines as routine
  where routine.id = p_routine_id and routine.user_id = v_user_id
  for update;

  v_undo_hash := pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_object(
      'action', 'undo_create_program_and_move_routine_v1',
      'routine_id', p_routine_id::text,
      'original_program_id', p_original_program_id::text,
      'created_program_id', p_created_program_id::text,
      'original_move_mutation_id', p_original_move_mutation_id::text,
      'expected_revision', p_expected_revision,
      'undo_mutation_id', p_undo_mutation_id::text
    )::text, 'UTF8'
  ));

  -- After a committed Undo, B is gone. The stable Routine aggregate is the
  -- durable receipt: exact token, exact hash and expected post-Undo revision.
  -- A later edit/move or a recreated B makes this proof invalid.
  if not v_created_exists
      and v_original_exists
      and v_routine_program_id = p_original_program_id
      and v_revision = p_expected_revision + 1
      and v_last_mutation = p_undo_mutation_id
      and v_last_hash = v_undo_hash then
    return v_revision;
  end if;

  if not found or not v_original_exists or not v_created_exists then
    raise exception 'routine_create_move_undo_not_found' using errcode = 'P0002';
  end if;
  if v_created_is_default then
    raise exception 'routine_create_move_undo_default_program'
      using errcode = 'P0001';
  end if;

  -- The current Program name participates in the original immutable request
  -- hash. A rename, no-op update or other Program edit changes updated_at or
  -- the hash and therefore fails closed before any reparent/delete.
  if v_created_updated_at is distinct from v_created_at then
    raise exception 'routine_create_move_undo_program_modified'
      using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.user_workout_programs as created_program
    where created_program.id = p_created_program_id
      and created_program.user_id = v_user_id
      and created_program.create_move_mutation_id = p_original_move_mutation_id
      and created_program.create_move_routine_id = p_routine_id
      and created_program.create_move_source_program_id = p_original_program_id
  ) then
    raise exception 'routine_create_move_undo_provenance_conflict'
      using errcode = 'P0001';
  end if;

  select count(*)
    into v_routines_in_created
  from public.user_workout_routines as routine
  where routine.user_id = v_user_id
    and routine.program_id = p_created_program_id;
  if v_routines_in_created <> 1
      or v_routine_program_id <> p_created_program_id
      or v_revision <> p_expected_revision
      or v_last_mutation <> p_original_move_mutation_id then
    raise exception 'routine_create_move_undo_revision_conflict'
      using errcode = 'P0001';
  end if;

  v_original_hash := pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_object(
      'action', 'create_program_and_move_routine_v1',
      'routine_id', p_routine_id::text,
      'source_program_id', p_original_program_id::text,
      'new_program_id', p_created_program_id::text,
      'new_program_name', v_created_name,
      'expected_revision', p_expected_revision - 1,
      'mutation_id', p_original_move_mutation_id::text
    )::text, 'UTF8'
  ));
  if v_last_hash is distinct from v_original_hash then
    raise exception 'routine_create_move_undo_mutation_conflict'
      using errcode = 'P0001';
  end if;

  update public.user_workout_routines as routine
  set program_id = p_original_program_id,
      composition_revision = v_revision + 1,
      last_composition_mutation_id = p_undo_mutation_id,
      last_routine_update_request_hash = v_undo_hash
  where routine.id = p_routine_id
    and routine.user_id = v_user_id
    and routine.program_id = p_created_program_id
    and routine.composition_revision = p_expected_revision
    and routine.last_composition_mutation_id = p_original_move_mutation_id;
  get diagnostics v_updated = row_count;
  if v_updated <> 1 then
    raise exception 'routine_create_move_undo_revision_conflict'
      using errcode = 'P0001';
  end if;

  delete from public.user_workout_programs as program
  where program.id = p_created_program_id
    and program.user_id = v_user_id
    and program.is_default is false
    and program.create_move_mutation_id = p_original_move_mutation_id
    and program.create_move_routine_id = p_routine_id
    and program.create_move_source_program_id = p_original_program_id
    and not exists (
      select 1 from public.user_workout_routines as routine
      where routine.user_id = v_user_id
        and routine.program_id = p_created_program_id
    );
  get diagnostics v_deleted = row_count;
  if v_deleted <> 1 then
    raise exception 'routine_create_move_undo_delete_conflict'
      using errcode = 'P0001';
  end if;

  return v_revision + 1;
end;
$$;

revoke all on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) from public, anon, authenticated, service_role;

revoke all on function public.undo_create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, uuid, bigint, uuid
) from public, anon, authenticated, service_role;

comment on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) is 'M5B staged atomic Create+Move: server-managed exact provenance is stamped for protected full Undo; client EXECUTE remains withheld pending release approval.';

comment on function public.undo_create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, uuid, bigint, uuid
) is 'M5B staged protected full Undo: exact Create+Move provenance, CAS, immutable hash, empty non-default Program deletion and Routine receipt idempotency; client EXECUTE withheld.';
