-- GitHub #568 / Linear TNYX-78: first-Routine RPC least-privilege grant.
-- Activation is two-stage: this migration grants ONLY authenticated EXECUTE.
-- Flutter myProgramRoutineCreateReleaseEnabledProvider remains hard OFF.
-- Apply to hosted Tio-world only after independently reviewed deployment approval
-- and rollback readiness. This repository commit does not deploy or activate.
--
-- Existing 20261019162535 established canonical default marker, owner lock,
-- and atomic composition writer. This CREATE OR REPLACE preserves the whole
-- original function contract/body except one fail-closed permanent-account
-- admission guard before any Program/Routine writes. It preserves signature,
-- owner, SECURITY DEFINER, empty search_path and existing other grants.
-- Preserve all unrelated Program/Routine/Move permissions and old client APIs.

-- Replace only this existing API function to reject anonymous signed-in Auth
-- accounts. The original 20261019 migration remains immutable and replayable.
create or replace function public.create_user_workout_routine_in_my_program(
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

  -- Anonymous Supabase Auth sign-ins ALSO have SQL role authenticated.
  -- Only a permanent signed-in identity can create its own first Routine.
  -- Read the Auth-owned server row; never trust caller-controlled metadata
  -- or a non-null auth.uid() as proof of permanent account admission.
  if not exists (
    select 1
    from auth.users as auth_identity
    where auth_identity.id = v_user_id
      and auth_identity.is_anonymous is false
  ) then
    raise exception 'routine_create_registered_account_required'
      using errcode = '28000';
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

revoke all on function public.create_user_workout_routine_in_my_program(
  uuid, text, uuid, jsonb
) from public, anon, service_role;

grant execute on function public.create_user_workout_routine_in_my_program(
  uuid, text, uuid, jsonb
) to authenticated;

comment on function public.create_user_workout_routine_in_my_program(
  uuid, text, uuid, jsonb
) is 'Permanent signed-in owner-only atomic first-Routine My Program creation (auth.users.is_anonymous=false). Authenticated EXECUTE granted by reviewed #568 W1 privilege slice; client release flag remains OFF pending device QA and owner activation approval.';

-- Emergency rollback: separately approved, explicitly executed SQL only;
-- do NOT check a rollback as a second forward migration, drop the function,
-- or modify the already-applied original migration.
-- revoke execute on function public.create_user_workout_routine_in_my_program(
--   uuid, text, uuid, jsonb
-- ) from authenticated;
