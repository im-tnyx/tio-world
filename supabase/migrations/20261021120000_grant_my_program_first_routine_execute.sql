-- GitHub #568 / Linear TNYX-78: first-Routine RPC least-privilege grant.
-- Activation is two-stage: this migration grants ONLY authenticated EXECUTE.
-- Flutter myProgramRoutineCreateReleaseEnabledProvider remains hard OFF.
-- Apply to hosted Tio-world only after independently reviewed deployment approval
-- and rollback readiness. This repository commit does not deploy or activate.
--
-- Existing 20261019162535 owns the SECDEF function, canonical default marker,
-- owner lock and atomic composition writer; do not replace its implementation.
-- Preserve all unrelated Program/Routine/Move permissions and old client APIs.

revoke all on function public.create_user_workout_routine_in_my_program(
  uuid, text, uuid, jsonb
) from public, anon, service_role;

grant execute on function public.create_user_workout_routine_in_my_program(
  uuid, text, uuid, jsonb
) to authenticated;

comment on function public.create_user_workout_routine_in_my_program(
  uuid, text, uuid, jsonb
) is 'Owner-scoped atomic first-Routine My Program creation. Authenticated EXECUTE granted by reviewed #568 W1 privilege slice; client release flag remains OFF pending device QA and owner activation approval.';

-- Emergency rollback: separately approved, explicitly executed SQL only;
-- do NOT check a rollback as a second forward migration, drop the function,
-- or modify the already-applied original migration.
-- revoke execute on function public.create_user_workout_routine_in_my_program(
--   uuid, text, uuid, jsonb
-- ) from authenticated;
