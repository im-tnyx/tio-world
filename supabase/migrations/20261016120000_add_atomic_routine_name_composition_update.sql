-- GitHub #564 / Linear TNYX-81: owner-approved Routine aggregate Update.
-- DB-first additive compatibility. No old RPC signature/grant is removed.
-- The full-original-request hash is a replay discriminator, NOT an auth token.

alter table public.user_workout_routines
  add column last_routine_update_request_hash bytea,
  add constraint user_workout_routines_update_hash_length
    check (last_routine_update_request_hash is null
      or pg_catalog.octet_length(last_routine_update_request_hash) = 32);

-- Legacy authenticated Data API UPDATE(name) must advance the aggregate
-- revision and invalidate the last mutation token. Existing 4-argument
-- composition writes must likewise invalidate any new-RPC request hash.
-- New name-aware RPCs set the hash themselves; never double-bump those writes.
create function private.track_user_workout_routine_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.name is distinct from old.name then
    if new.last_routine_update_request_hash
        is distinct from old.last_routine_update_request_hash then
      -- Only the authenticated SECDEF name-aware RPC can set this protected
      -- column. It has already incremented the revision (name-only) OR the
      -- original composition RPC incremented it earlier in this transaction.
      if new.last_routine_update_request_hash is null
          or new.last_composition_mutation_id is null
          or new.composition_revision < old.composition_revision
          or new.composition_revision > old.composition_revision + 1 then
        raise exception 'invalid_routine_aggregate_update'
          using errcode = '22023';
      end if;
    else
      -- Legacy client can only UPDATE(name); keep its aggregate revision
      -- observable by new clients without modifying the legacy API/grants.
      if new.composition_revision is distinct from old.composition_revision
          or new.last_composition_mutation_id
            is distinct from old.last_composition_mutation_id then
        raise exception 'invalid_routine_aggregate_update'
          using errcode = '22023';
      end if;
      new.composition_revision := old.composition_revision + 1;
      new.last_composition_mutation_id := null;
      new.last_routine_update_request_hash := null;
    end if;
  elsif new.last_composition_mutation_id
      is distinct from old.last_composition_mutation_id
      and new.last_routine_update_request_hash
        is not distinct from old.last_routine_update_request_hash then
    -- The 4-argument legacy writer stores the unmodified client UUID.
    -- A new mutation must not inherit an unrelated new-RPC fingerprint.
    new.last_routine_update_request_hash := null;
  end if;
  return new;
end;
$$;

revoke all on function private.track_user_workout_routine_revision()
  from public, anon, authenticated, service_role;

create trigger trg_user_workout_routines_aggregate_revision
before update on public.user_workout_routines
for each row execute function private.track_user_workout_routine_revision();

-- This intentionally has a distinct name, avoiding ambiguous PostgREST
-- overload dispatch. A NULL Name/Exercises means "leave unchanged";
-- [] is an actual empty composition replacement.
create function public.update_user_workout_routine_with_composition(
  p_routine_id uuid,
  p_program_id uuid,
  p_expected_revision bigint,
  p_expected_name text,
  p_client_mutation_id uuid,
  p_name text,
  p_exercises jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_name text;
  v_revision bigint;
  v_last_mutation uuid;
  v_last_hash bytea;
  v_hash bytea;
  v_new_revision bigint;
begin
  if v_user_id is null then
    raise exception 'routine_update_not_authenticated' using errcode = '28000';
  end if;

  if p_routine_id is null or p_program_id is null
      or p_client_mutation_id is null
      or p_expected_revision is null or p_expected_revision < 0
      or p_expected_name is null
      or (p_name is null and p_exercises is null)
      or (p_name is not null
        and pg_catalog.btrim(p_name) = '')
      or (p_exercises is not null
        and pg_catalog.jsonb_typeof(p_exercises) <> 'array') then
    raise exception 'invalid_routine_update_request' using errcode = '22023';
  end if;

  if p_exercises is not null
      and pg_catalog.octet_length(p_exercises::text) > 262144 then
    raise exception 'routine_composition_payload_too_large'
      using errcode = '22023';
  end if;

  -- Owner, Program and Routine identity are checked before parsing child
  -- refs. This row lock serializes legacy Name and composition mutations.
  select routine.name, routine.composition_revision,
         routine.last_composition_mutation_id,
         routine.last_routine_update_request_hash
    into v_name, v_revision, v_last_mutation, v_last_hash
  from public.user_workout_routines as routine
  where routine.id = p_routine_id
    and routine.program_id = p_program_id
    and routine.user_id = v_user_id
  for update;

  if not found then
    raise exception 'routine_update_not_found' using errcode = 'P0002';
  end if;

  -- Digest includes all original request fields and the omission mask;
  -- jsonb's canonical object-key ordering is stable for frozen retries.
  -- The token is kept as the raw client-generated UUID in the old column.
  v_hash := pg_catalog.sha256(pg_catalog.convert_to(
    pg_catalog.jsonb_build_object(
      'routine_id', p_routine_id::text,
      'program_id', p_program_id::text,
      'expected_revision', p_expected_revision,
      'expected_name', p_expected_name,
      'mutation_id', p_client_mutation_id::text,
      'name_present', p_name is not null,
      'name', p_name,
      'composition_present', p_exercises is not null,
      'exercises', p_exercises
    )::text, 'UTF8'
  ));

  -- CRITICAL: same-token replay precedes stale expected-revision/Name CAS.
  -- A successful first write already changed both of those expected inputs.
  if v_last_mutation = p_client_mutation_id then
    if v_last_hash is distinct from v_hash
        or v_name is distinct from
          coalesce(p_name, p_expected_name) then
      raise exception 'routine_update_mutation_conflict' using errcode = 'P0001';
    end if;

    -- Delegate persisted Exercise/Set equality to the original, reviewed
    -- 4-arg RPC, whose exact-token branch precedes its revision check.
    if p_exercises is not null then
      perform public.save_user_workout_routine_composition(
        p_routine_id, p_expected_revision, p_client_mutation_id, p_exercises
      );
    end if;
    return v_revision;
  end if;

  if v_revision <> p_expected_revision
      or v_name is distinct from p_expected_name then
    raise exception 'routine_update_revision_conflict' using errcode = 'P0001';
  end if;

  if p_exercises is not null then
    -- Reuse ALL existing owner/custom archive/type/legacy rich-Set checks;
    -- calling inside the SAME transaction makes subsequent metadata failure
    -- roll the child replacement back as well. Never clone that 500-line RPC.
    v_new_revision := public.save_user_workout_routine_composition(
      p_routine_id, p_expected_revision, p_client_mutation_id, p_exercises
    );
    if v_new_revision <> v_revision + 1 then
      raise exception 'routine_update_revision_conflict' using errcode = 'P0001';
    end if;

    -- The 4-arg writer has already advanced the revision exactly once.
    -- Distinct hash marks the authorized second parent update to the trigger.
    update public.user_workout_routines
    set name = coalesce(p_name, v_name),
        last_routine_update_request_hash = v_hash
    where id = p_routine_id and user_id = v_user_id;
  else
    -- Name-only does not touch Exercise/Set IDs or even read child rows.
    update public.user_workout_routines
    set name = p_name,
        composition_revision = v_revision + 1,
        last_composition_mutation_id = p_client_mutation_id,
        last_routine_update_request_hash = v_hash
    where id = p_routine_id and user_id = v_user_id;
  end if;

  return v_revision + 1;
end;
$$;

revoke all on function public.update_user_workout_routine_with_composition(
  uuid, uuid, bigint, text, uuid, text, jsonb
) from public, anon, authenticated, service_role;
grant execute on function public.update_user_workout_routine_with_composition(
  uuid, uuid, bigint, text, uuid, text, jsonb
) to authenticated;

-- Do not grant authenticated direct UPDATE of aggregate revision/token/hash.
-- Retain existing authenticated UPDATE(name) and the old 4-arg RPC for older
-- mobile clients until a separately authorized minimum-version sunset gate.
