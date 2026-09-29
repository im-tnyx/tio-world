-- ============================================================================
-- Migration: harden_user_workout_program_privileges
--
-- Align authenticated Data API privileges with the existing ProgramRepository
-- contract: list/create/rename only. Program delete/archive lifecycle semantics
-- remain intentionally deferred.
-- ============================================================================

revoke delete on table public.user_workout_programs from authenticated;
revoke update on table public.user_workout_programs from authenticated;
grant update (name) on table public.user_workout_programs to authenticated;

drop policy if exists user_workout_programs_delete_own
on public.user_workout_programs;
