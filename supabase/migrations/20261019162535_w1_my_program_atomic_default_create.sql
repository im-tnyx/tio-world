-- GitHub #568 / Linear TNYX-78: W1 My Program Identity and Atomic First Routine Create.
--
-- 1. Schema: Add is_default column to user_workout_programs with partial unique index
--    (user_id) WHERE is_default. Ensures at most one canonical default Program per owner.
-- 2. Privilege narrowing: Revoke table-level INSERT from authenticated, and grant
--    column-level INSERT(id, user_id, name) only. Restricts clients from inserting or
--    mutating is_default directly, while preserving legacy client Program creation.
-- 3. Staged dormant RPC: create_user_workout_routine_in_my_program resolves or lazily
--    creates the owner's default "My Program" and delegates to the existing atomic
--    routine composition writer in the same transaction. Replay idempotent, failure
--    rollback leaves no empty default Program. EXECUTE revoked while dormant.

-- 1. Add is_default column and partial unique index
alter table public.user_workout_programs
  add column is_default boolean not null default false;

create unique index idx_user_workout_programs_owner_default
  on public.user_workout_programs (user_id)
  where is_default;

-- 2. Narrow authenticated INSERT to legacy client-supplied columns only
revoke insert on table public.user_workout_programs from authenticated;
grant insert (id, user_id, name) on table public.user_workout_programs to authenticated;

-- 3. Dormant server-authoritative first-Routine creation RPC
create function public.create_user_workout_routine_in_my_program(
  p_routine_id uuid,
  p_name text,
  p_client_mutation_id uuid,
  p_exercises jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_program_id uuid;
  v_revision bigint;
begin
  if v_user_id is null then
    raise exception 'routine_create_not_authenticated' using errcode = '28000';
  end if;

  -- Match Dart String.trim: Unicode White_Space plus BOM (U+FEFF),
  -- identical to create_user_workout_routine_with_composition.
  if p_routine_id is null
      or p_client_mutation_id is null
      or p_name is null
      or pg_catalog.btrim(p_name,
        U&'\0009\000A\000B\000C\000D\0020\0085\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF'
      ) = ''
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

  if exists (
    select 1 from pg_catalog.jsonb_array_elements(p_exercises) as e(value)
    where pg_catalog.jsonb_typeof(e.value) is distinct from 'object'
       or pg_catalog.jsonb_typeof(e.value -> 'sets') is distinct from 'array'
       or e.value -> 'sets' = '[]'::jsonb
  ) then
    raise exception 'routine_create_set_required' using errcode = '22023';
  end if;

  if pg_catalog.current_setting('transaction_isolation') <> 'read committed' then
    raise exception 'routine_create_isolation_unsupported'
      using errcode = '25001';
  end if;

  -- Lock the user account row with FOR NO KEY UPDATE.
  -- This serializes concurrent absent-default resolutions for the same owner
  -- (self-conflicting) without deadlocking with account deletion checks or
  -- Routine foreign key validation (compatible with FOR KEY SHARE).
  perform 1
  from public.users as account
  where account.id = v_user_id
  for no key update;

  if not found then
    raise exception 'routine_create_account_not_found' using errcode = 'P0002';
  end if;

  -- Resolve existing default Program if present.
  select program.id
    into v_program_id
  from public.user_workout_programs as program
  where program.user_id = v_user_id
    and program.is_default = true
  for key share;

  -- If absent, lazily create the canonical My Program default.
  if not found then
    v_program_id := pg_catalog.gen_random_uuid();
    insert into public.user_workout_programs (
      id, user_id, name, is_default
    ) values (
      v_program_id, v_user_id, 'My Program', true
    );
  end if;

  -- Atomically delegate to the existing canonical Routine composition writer.
  -- Reuses all Exercise/Set validation, Custom Exercise active checks, and
  -- idempotent retry/replay verification under the same transaction.
  -- Any validation failure rolls back both the Routine and the newly inserted Program.
  v_revision := public.create_user_workout_routine_with_composition(
    p_routine_id, v_program_id, p_name, p_client_mutation_id, p_exercises
  );

  return pg_catalog.jsonb_build_object(
    'program_id', v_program_id,
    'composition_revision', v_revision
  );
end;
$$;

-- Additive staged contract, intentionally unreachable to Data API clients.
revoke all on function public.create_user_workout_routine_in_my_program(
  uuid, text, uuid, jsonb
) from public, anon, authenticated, service_role;

comment on function public.create_user_workout_routine_in_my_program(
  uuid, text, uuid, jsonb
) is 'Dormant #568 W1 server-authoritative lazy My Program resolver and atomic Routine composer. EXECUTE withheld until reviewed Flutter activation gate.';
