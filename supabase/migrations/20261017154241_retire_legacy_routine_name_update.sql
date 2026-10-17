-- #569 / TNYX-81 M2C: retire the unversioned Data API Rename contract.
-- Protected owner/Program/revision CAS Rename is the supported write path.
-- Source-only migration; hosted deployment and Move EXECUTE are separate gates.
revoke update (name) on table public.user_workout_routines from authenticated;

-- Fail closed if any inherited/table UPDATE overrides the narrow revoke or
-- if protected Create/Read/Update/Composition privileges were accidentally lost.
do $$
begin
  if has_table_privilege('authenticated', 'public.user_workout_routines', 'UPDATE')
    or has_column_privilege('authenticated', 'public.user_workout_routines', 'name', 'UPDATE')
    or has_column_privilege('authenticated', 'public.user_workout_routines', 'program_id', 'UPDATE')
    or has_column_privilege('anon', 'public.user_workout_routines', 'name', 'UPDATE')
    or not has_table_privilege('authenticated', 'public.user_workout_routines', 'SELECT')
    or not has_column_privilege('authenticated', 'public.user_workout_routines', 'name', 'INSERT')
    or not has_function_privilege('authenticated',
      'public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)', 'EXECUTE')
    or not has_function_privilege('authenticated',
      'public.update_user_workout_routine_with_composition(uuid,uuid,bigint,text,uuid,text,jsonb)', 'EXECUTE')
    or has_function_privilege('authenticated',
      'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  then
    raise exception 'routine_legacy_rename_cutoff_privilege_invariant_failed'
      using errcode = '42501';
  end if;
end;
$$;
