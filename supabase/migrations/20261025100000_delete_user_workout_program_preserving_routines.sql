-- GitHub #567 / Linear TNYX-81: D1 protected, atomic Delete Program.
-- This source migration is NOT a hosted deployment or a client activation.
-- No table/column change, no direct Program DELETE/Routine UPDATE privilege.
-- Approved semantics: preserve every Routine (and stable child IDs) in the
-- owner's canonical My Program, then delete only the non-default source.
--
-- Caller supplies the exact Routine UUID membership visible at confirmation.
-- A stale membership fails closed; UI MUST refresh before asking again.
-- Deleted-source retries are NOT silently acknowledged: without a durable
-- deleted-Program receipt, missing source means UNKNOWN/not-found, not success.

create function public.delete_user_workout_program_preserving_routines(
  p_source_program_id uuid,
  p_expected_routine_ids uuid[],
  p_client_mutation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_default_program_id uuid;
  v_probe_ids uuid[];
  v_actual_ids uuid[];
  v_expected_ids uuid[];
  v_source_is_default boolean;
  v_locked_is_default boolean;
  v_source_found boolean := false;
  v_default_found boolean := false;
  v_created_default boolean := false;
  v_program_id uuid;
  v_routine_id uuid;
  v_revision bigint;
  v_request_hash bytea;
  v_updated bigint;
  v_deleted bigint;
  v_moved bigint := 0;
begin
  if v_user_id is null then
    raise exception 'program_delete_not_authenticated' using errcode = '28000';
  end if;

  -- Supabase anonymous sign-ins also use the "authenticated" SQL role.
  -- Admission is based on the trusted Auth row, never a JWT user_meta flag.
  if not exists (
    select 1 from auth.users as identity
    where identity.id = v_user_id and identity.is_anonymous is false
  ) then
    raise exception 'program_delete_registered_account_required'
      using errcode = '28000';
  end if;

  if p_source_program_id is null or p_client_mutation_id is null
      or p_expected_routine_ids is null
      or pg_catalog.cardinality(p_expected_routine_ids) > 20000
      or pg_catalog.array_position(p_expected_routine_ids, null) is not null then
    raise exception 'invalid_program_delete_request' using errcode = '22023';
  end if;

  -- Do not allow ambiguous duplicate/unsorted caller membership to slip
  -- through a set comparison. Sorting is server-owned and deterministic.
  select pg_catalog.coalesce(
      pg_catalog.array_agg(ids.id order by ids.id), '{}'::uuid[])
    into v_expected_ids
  from pg_catalog.unnest(p_expected_routine_ids) as ids(id);
  if pg_catalog.cardinality(v_expected_ids) <>
      (select pg_catalog.count(distinct id)
       from pg_catalog.unnest(p_expected_routine_ids) as ids(id)) then
    raise exception 'invalid_program_delete_request' using errcode = '22023';
  end if;

  if pg_catalog.current_setting('transaction_isolation') <> 'read committed' then
    raise exception 'program_delete_isolation_unsupported' using errcode = '25001';
  end if;

  -- Existing #568 canonical-default resolver obtains FOR NO KEY UPDATE.
  -- Serializing that choice here prevents two concurrent absent-defaults.
  -- #569 Move holds account KEY SHARE: compatible with this account lock.
  perform 1 from public.users as account
  where account.id = v_user_id for no key update;
  if not found then
    raise exception 'program_delete_not_found' using errcode = 'P0002';
  end if;

  -- Preflight source without taking a Program lock out of UUID order.
  -- We recheck authoritatively after all applicable Program locks below.
  select program.is_default into v_source_is_default
  from public.user_workout_programs as program
  where program.id = p_source_program_id and program.user_id = v_user_id;
  if not found then
    raise exception 'program_delete_not_found' using errcode = 'P0002';
  end if;
  if v_source_is_default then
    raise exception 'program_delete_default_forbidden' using errcode = 'P0001';
  end if;

  select pg_catalog.coalesce(
      pg_catalog.array_agg(routine.id order by routine.id), '{}'::uuid[])
    into v_probe_ids
  from public.user_workout_routines as routine
  where routine.program_id = p_source_program_id and routine.user_id = v_user_id;

  select program.id into v_default_program_id
  from public.user_workout_programs as program
  where program.user_id = v_user_id and program.is_default is true;

  -- Only prepare a canonical default when initially needed. It remains
  -- uncommitted until every subsequent check + source removal succeeds.
  if v_default_program_id is null and
      pg_catalog.cardinality(v_probe_ids) > 0 then
    v_default_program_id := pg_catalog.gen_random_uuid();
    insert into public.user_workout_programs
      (id, user_id, name, is_default)
    values (v_default_program_id, v_user_id, 'My Program', true);
    v_created_default := true;
  end if;

  -- Hold all extant owner Program rows in UUID order BEFORE acquiring any
  -- Routine advisory/row lock, same hierarchy as protected #569 Move/Undo.
  for v_program_id in
    select distinct ids.id from
      pg_catalog.unnest(array[p_source_program_id, v_default_program_id]) as ids(id)
    where ids.id is not null
    order by ids.id
  loop
    select program.is_default into v_locked_is_default
    from public.user_workout_programs as program
    where program.id = v_program_id and program.user_id = v_user_id
    for update;
    if found then
      if v_program_id = p_source_program_id then
        v_source_found := true;
        if v_locked_is_default then
          raise exception 'program_delete_default_forbidden'
            using errcode = 'P0001';
        end if;
      else
        v_default_found := v_locked_is_default;
      end if;
    end if;
  end loop;

  if not v_source_found then
    raise exception 'program_delete_not_found' using errcode = 'P0002';
  end if;
  if v_default_program_id is not null and not v_default_found then
    raise exception 'program_delete_default_conflict' using errcode = 'P0001';
  end if;

  -- While source Program FOR UPDATE is held, existing owner-scoped
  -- Create/Edit/Move/Delete lock it via KEY SHARE before Routine mutation;
  -- even FK checks for legacy inserts must wait. This is the authoritative
  -- stable membership snapshot against the user's confirmation.
  select pg_catalog.coalesce(
      pg_catalog.array_agg(routine.id order by routine.id), '{}'::uuid[])
    into v_actual_ids
  from public.user_workout_routines as routine
  where routine.program_id = p_source_program_id and routine.user_id = v_user_id;

  if v_actual_ids is distinct from v_expected_ids then
    raise exception 'program_delete_membership_conflict' using errcode = 'P0001';
  end if;

  if pg_catalog.cardinality(v_actual_ids) > 0
      and v_default_program_id is null then
    -- Source changed from empty to populated before the Program lock,
    -- and no destination was prepared; the caller may refresh and retry.
    raise exception 'program_delete_membership_conflict' using errcode = 'P0001';
  end if;

  -- As in #569, take per-Routine private UUID locks before Routine row locks.
  -- Increment aggregate revision and overwrite last mutation/hash: stale
  -- pre-delete Edit/Move retries must fail instead of moving back from default.
  foreach v_routine_id in array v_actual_ids loop
    perform private.lock_user_workout_routine_identity(v_routine_id);

    select routine.composition_revision into v_revision
    from public.user_workout_routines as routine
    where routine.id = v_routine_id and routine.user_id = v_user_id
      and routine.program_id = p_source_program_id
    for update;
    if not found or v_revision = 9223372036854775807 then
      raise exception 'program_delete_revision_conflict' using errcode = 'P0001';
    end if;

    v_request_hash := pg_catalog.sha256(pg_catalog.convert_to(
      pg_catalog.jsonb_build_object(
        'action', 'delete_program_reparent_v1',
        'source_program_id', p_source_program_id::text,
        'destination_program_id', v_default_program_id::text,
        'routine_id', v_routine_id::text,
        'expected_revision', v_revision,
        'mutation_id', p_client_mutation_id::text
      )::text, 'UTF8'
    ));

    update public.user_workout_routines as routine
    set program_id = v_default_program_id,
        composition_revision = v_revision + 1,
        last_composition_mutation_id = p_client_mutation_id,
        last_routine_update_request_hash = v_request_hash
    where routine.id = v_routine_id and routine.user_id = v_user_id
      and routine.program_id = p_source_program_id
      and routine.composition_revision = v_revision;
    get diagnostics v_updated = row_count;
    if v_updated <> 1 then
      raise exception 'program_delete_revision_conflict' using errcode = 'P0001';
    end if;
    v_moved := v_moved + 1;
  end loop;

  -- An as-yet unreviewed new FK child of Program might use CASCADE.
  -- Never silently destroy its rows just because Routine reparent succeeded.
  if exists (
    select 1 from pg_catalog.pg_constraint as constraint_row
    where constraint_row.contype = 'f'
      and constraint_row.confrelid = 'public.user_workout_programs'::regclass
      and constraint_row.conname <> 'user_workout_routines_program_owner_fkey'
  ) then
    raise exception 'program_delete_unreviewed_dependency'
      using errcode = 'P0001';
  end if;

  -- If the source was emptied concurrently while acquiring locks, the
  -- preliminary default was unnecessary. Remove ONLY our own uncommitted
  -- provisional default; never delete an existing canonical default.
  if v_created_default and v_moved = 0 then
    delete from public.user_workout_programs as program
    where program.id = v_default_program_id and program.user_id = v_user_id
      and program.is_default is true
      and not exists (
        select 1 from public.user_workout_routines as routine
        where routine.user_id = v_user_id and
          routine.program_id = v_default_program_id
      );
    get diagnostics v_deleted = row_count;
    if v_deleted <> 1 then
      raise exception 'program_delete_default_conflict' using errcode = 'P0001';
    end if;
    v_default_program_id := null;
  end if;

  -- Parent deletion MUST prove zero children after the reparent.
  -- Any error rolls back every Routine update and any default creation.
  delete from public.user_workout_programs as program
  where program.id = p_source_program_id and program.user_id = v_user_id
    and program.is_default is false
    and not exists (
      select 1 from public.user_workout_routines as routine
      where routine.user_id = v_user_id
        and routine.program_id = p_source_program_id
    );
  get diagnostics v_deleted = row_count;
  if v_deleted <> 1 then
    raise exception 'program_delete_source_conflict' using errcode = 'P0001';
  end if;

  return pg_catalog.jsonb_build_object(
    'deleted_program_id', p_source_program_id,
    'destination_program_id', v_default_program_id,
    'moved_routine_count', v_moved
  );
end;
$$;

-- Future explicit hosted grant/deployment decision is a separate gate.
-- Revoke PUBLIC's default EXECUTE in the SAME source migration.
revoke all on function public.delete_user_workout_program_preserving_routines(
  uuid, uuid[], uuid
) from public, anon, authenticated, service_role;

comment on function public.delete_user_workout_program_preserving_routines(
  uuid, uuid[], uuid
) is 'Staged #567 D1 owner-scoped atomic Program removal preserving all Routines in canonical default. Client EXECUTE denied pending reviewed activation and hosted QA.';
