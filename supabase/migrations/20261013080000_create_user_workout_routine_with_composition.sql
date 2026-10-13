-- GitHub #535: Routine Create requires at least one Exercise.
-- Adds no tables/columns and does not change the existing Edit/Save RPC.
-- Keep metadata INSERT grants for deployed old clients until a separately
-- reviewed rollout can retire the legacy name-only creation capability.
--
-- One SQL function call is one transaction: inserting the metadata row and
-- calling the existing revision/mutation guarded composition writer either
-- both commit or both roll back. Never expose a partial Routine.

create function public.create_user_workout_routine_with_composition(
  p_routine_id uuid,
  p_program_id uuid,
  p_name text,
  p_client_mutation_id uuid,
  p_exercises jsonb
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_existing record;
  v_entry jsonb;
  v_ref text;
begin
  if v_user_id is null then
    raise exception 'routine_create_not_authenticated' using errcode = '28000';
  end if;

  if p_routine_id is null or p_program_id is null
      or p_client_mutation_id is null
      or p_name is null or p_name !~ '[^[:space:]]'
      or p_exercises is null
      or pg_catalog.jsonb_typeof(p_exercises) <> 'array' then
    raise exception 'invalid_routine_create_request' using errcode = '22023';
  end if;

  if pg_catalog.jsonb_array_length(p_exercises) = 0 then
    raise exception 'routine_create_exercise_required' using errcode = '22023';
  end if;

  if pg_catalog.octet_length(p_exercises::text) > 262144 then
    raise exception 'routine_composition_payload_too_large'
      using errcode = '22023';
  end if;

  -- Match the parent-to-child account deletion cascade lock order.
  -- Holding a user key-share lock before the Program lock also prevents
  -- the Routine FK check from deadlocking with delete_user_account().
  perform 1
  from public.users as account
  where account.id = v_user_id
  for key share;

  if not found then
    raise exception 'routine_create_account_not_found' using errcode = 'P0002';
  end if;

  -- Fail closed before inserting or exposing whether another owner's UUID
  -- already exists. This also locks the Program against concurrent deletion.
  perform 1
  from public.user_workout_programs as program
  where program.id = p_program_id and program.user_id = v_user_id
  for key share;

  if not found then
    raise exception 'routine_create_program_not_found' using errcode = 'P0002';
  end if;

  -- The client owns a stable Routine UUID + mutation UUID across uncertain
  -- retries. ON CONFLICT waits for any concurrent insert of that UUID.
  -- An identical committed retry is read/verified, never inserted again.
  insert into public.user_workout_routines (
    id, user_id, program_id, name
  ) values (
    p_routine_id, v_user_id, p_program_id, p_name
  )
  on conflict (id) do nothing;

  if not found then
    -- Lock the committed row (if owner-visible), then confirm immutable
    -- create identity. Never treat a different mutation as a successful
    -- retry or overwrite an existing Routine.
    select routine.user_id, routine.program_id, routine.name,
           routine.composition_revision,
           routine.last_composition_mutation_id
      into v_existing
    from public.user_workout_routines as routine
    where routine.id = p_routine_id and routine.user_id = v_user_id
    for update;

    if not found then
      raise exception 'routine_create_not_found' using errcode = 'P0002';
    end if;

    if v_existing.program_id <> p_program_id
        or v_existing.name <> p_name
        or v_existing.composition_revision <> 1
        or v_existing.last_composition_mutation_id
          is distinct from p_client_mutation_id then
      raise exception 'routine_create_identity_conflict'
        using errcode = 'P0001';
    end if;

    -- Reuse the existing canonical normalized-payload comparison.
    -- This is a successful idempotent replay ONLY if all persisted
    -- entries/Sets and IDs match. It performs no child writes.
    -- Archive after an already committed create does not revoke a replay.
    return public.save_user_workout_routine_composition(
      p_routine_id, 0, p_client_mutation_id, p_exercises
    );
  end if;

  -- New writes must never capture an already archived/foreign Custom ref.
  -- FOR SHARE prevents an UPDATE(status='archived') on another device from
  -- overtaking validation until this entire transaction has committed.
  -- The existing composition writer still owns all other payload validation.
  for v_entry in
    select e.value from pg_catalog.jsonb_array_elements(p_exercises)
      as e(value)
  loop
    if pg_catalog.jsonb_typeof(v_entry) = 'object' then
      v_ref := v_entry ->> 'exercise_ref';
      if v_ref ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
        perform 1
        from public.user_workout_exercises as exercise
        where exercise.id = v_ref::uuid
          and exercise.user_id = v_user_id
          and exercise.status = 'active'
        for share;
        if not found then
          raise exception 'routine_create_exercise_unavailable'
            using errcode = 'P0002';
        end if;
      end if;
    end if;
  end loop;

  -- Existing writer atomically validates ordered Exercise/Set IDs and owner
  -- references, persists the snapshot, and advances revision 0 -> 1.
  -- Any exception rolls back the preceding metadata INSERT as well.
  return public.save_user_workout_routine_composition(
    p_routine_id, 0, p_client_mutation_id, p_exercises
  );
end;
$$;

revoke all on function public.create_user_workout_routine_with_composition(
  uuid, uuid, text, uuid, jsonb
) from public, anon, authenticated, service_role;

grant execute on function public.create_user_workout_routine_with_composition(
  uuid, uuid, text, uuid, jsonb
) to authenticated;
