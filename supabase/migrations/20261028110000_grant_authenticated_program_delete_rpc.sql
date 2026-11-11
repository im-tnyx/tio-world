-- GitHub #567 / Linear TNYX-81: Gate B authenticated EXECUTE grant.
-- Grants EXECUTE on delete_user_workout_program_preserving_routines to authenticated role only.
-- anon, public, and service_role remain revoked.
-- Table-level DELETE privileges on user_workout_programs and user_workout_routines remain denied.

grant execute on function public.delete_user_workout_program_preserving_routines(
  uuid, uuid[], uuid
) to authenticated;

comment on function public.delete_user_workout_program_preserving_routines(
  uuid, uuid[], uuid
) is 'Approved #567 Gate B owner-scoped atomic Program removal. EXECUTE granted to authenticated only; client table DELETE denied.';
