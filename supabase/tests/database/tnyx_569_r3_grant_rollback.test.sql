\set ON_ERROR_STOP on
-- Disposable migration replay only: model emergency EXECUTE revocation
-- without committing a denial migration or changing user workout records.
-- Current migration must have granted all three exact RPCs.
begin;

do $before$
declare sig text; fn oid;
begin
  for sig in select signature from (values
    ('public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)'),
    ('public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)'),
    ('public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)')
  ) as e(signature) loop
    fn := pg_catalog.to_regprocedure(sig);
    if fn is null or not pg_catalog.has_function_privilege(
        'authenticated',fn,'EXECUTE') then
      raise exception 'R3 expected authenticated grant absent: %',sig;
    end if;
  end loop;
end;
$before$;

-- Same exact-scope rollback to use only under a separate hosted approval.
revoke execute on function public.move_user_workout_routine(
  uuid,uuid,uuid,bigint,uuid) from authenticated;
revoke execute on function public.create_user_workout_program_and_move_routine(
  uuid,uuid,uuid,text,bigint,uuid) from authenticated;
revoke execute on function public.undo_create_user_workout_program_and_move_routine(
  uuid,uuid,uuid,uuid,bigint,uuid) from authenticated;

do $after_revoke$
declare sig text; fn oid;
begin
  for sig in select signature from (values
    ('public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)'),
    ('public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)'),
    ('public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)')
  ) as e(signature) loop
    fn := pg_catalog.to_regprocedure(sig);
    if pg_catalog.has_function_privilege('authenticated',fn,'EXECUTE')
      or pg_catalog.has_function_privilege('anon',fn,'EXECUTE')
      or pg_catalog.has_function_privilege('service_role',fn,'EXECUTE')
      or exists (
        select 1 from pg_catalog.pg_proc as p,
          pg_catalog.aclexplode(coalesce(
            p.proacl,pg_catalog.acldefault('f',p.proowner))) as a
        where p.oid=fn and a.grantee=0 and a.privilege_type='EXECUTE'
      ) then
      raise exception 'R3 rollback ACL denial failed: %',sig;
    end if;
  end loop;
  if pg_catalog.has_column_privilege(
     'authenticated','public.user_workout_routines','program_id','UPDATE')
   or pg_catalog.has_table_privilege(
     'authenticated','public.user_workout_programs','DELETE') then
    raise exception 'R3 rollback leaked direct writes';
  end if;
end;
$after_revoke$;

-- Avoid leaving the disposable CI database without the just-applied grant.
rollback;
