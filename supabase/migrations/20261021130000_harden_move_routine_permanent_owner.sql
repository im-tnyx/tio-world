-- GitHub #569 / Linear TNYX-81: M4A permanent-owner admission for BOTH Move RPCs.
-- This repo-only source migration replaces only the existing SECDEF bodies
-- with a trusted auth.users.is_anonymous IS FALSE check before locks/writes.
-- Supabase anonymous signed-in users have SQL role authenticated; auth.uid()
-- and user-supplied JWT claims alone do not establish permanent-account access.
-- Preserve all owner-scoped CAS/idempotency, child identities and lock order.
-- NO client EXECUTE grant, direct UPDATE(program_id), schema change or release.
-- Existing applied 20261017/20261018 migrations remain immutable.
-- Host deployment and any eventual permission grant need separate owner approval.

create or replace function public.move_user_workout_routine(
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

  -- Anonymous Supabase Auth sign-ins use the SQL authenticated role too.
  -- Require the trusted auth.users row, never a caller-controlled JWT flag.
  -- Do this before any Program/Routine lock or write, including exact retries.
  if not exists (
    select 1 from auth.users as auth_identity
    where auth_identity.id = v_user_id
      and auth_identity.is_anonymous is false
  ) then
    raise exception 'routine_move_registered_account_required' using errcode = '28000';
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

  -- Anonymous Supabase Auth sign-ins use the SQL authenticated role too.
  -- Require the trusted auth.users row, never a caller-controlled JWT flag.
  -- Do this before any Program/Routine lock or write, including exact retries.
  if not exists (
    select 1 from auth.users as auth_identity
    where auth_identity.id = v_user_id
      and auth_identity.is_anonymous is false
  ) then
    raise exception 'routine_create_move_registered_account_required' using errcode = '28000';
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

  -- Lock the existing owner Program rows in stable UUID order BEFORE the
  -- shared Routine UUID/row lock. This applies to both first writes and
  -- exact replays; the source may be missing only after a committed Move.
  -- A genuinely new destination has no Program row to lock yet.
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
    -- The locked Routine is already owner-scoped and its composite
    -- (program_id, user_id) FK guarantees the matching owner Program.
    -- During a concurrent identical retry, the destination INSERT can be
    -- uncommitted at the initial sorted Program lookup; waiting on the
    -- Routine UUID lock reveals the committed row only AFTER that lookup.
    -- Do not use that stale v_destination_exists flag for exact replay,
    -- and do not acquire a destination Program row lock after the UUID lock
    -- (that would invert the M1 Move/Delete lock hierarchy).
    -- Subsequent Program rename is independent of the immutable request.
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
  if v_destination_exists then
    raise exception 'routine_create_move_program_conflict'
      using errcode = 'P0001';
  end if;

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

-- CREATE OR REPLACE preserves prior ACLs; assert dormant state explicitly.
revoke all on function public.move_user_workout_routine(
  uuid, uuid, uuid, bigint, uuid
) from public, anon, authenticated, service_role;

revoke all on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) from public, anon, authenticated, service_role;

comment on function public.move_user_workout_routine(
  uuid, uuid, uuid, bigint, uuid
) is 'M4A staged #569 Move: permanent signed-in owner admission via auth.users.is_anonymous=false; CAS/retry identity preserved; client EXECUTE withheld pending separate release gate.';

comment on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) is 'M4A staged #569 atomic Create+Move: permanent signed-in owner admission via auth.users.is_anonymous=false; transaction/CAS/retry preserved; client EXECUTE withheld pending separate release gate.';
