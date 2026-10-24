-- GitHub #569 R3: guarded, least-privilege Move RPC exposure proposal.
-- This migration is source/review ONLY until a separate explicit hosted apply GO.
-- Once applied, every permanent signed-in account can invoke these RPCs through
-- PostgREST; the server's owner/identity/CAS guards—not Flutter—are authority.
-- Revoke in an separately approved operational rollback; do NOT place rollback
-- in the normal forward migration sequence.

do $r3_preflight$
declare
  v_signature text;
  v_function oid;
  v_body text;
begin
  for v_signature in
    select signature from (values
      ('public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)'),
      ('public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)'),
      ('public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)')
    ) as exact_move_rpc(signature)
  loop
    v_function := pg_catalog.to_regprocedure(v_signature);
    if v_function is null then
      raise exception 'R3 missing expected Move function: %', v_signature;
    end if;
    if not exists (
      select 1 from pg_catalog.pg_proc as p
      where p.oid = v_function
        and p.proowner = 'postgres'::regrole
        and p.prosecdef
        and p.proconfig @> array['search_path=""']::text[]
    ) then
      raise exception 'R3 function owner/security/search_path mismatch: %',
        v_signature;
    end if;
    v_body := pg_catalog.lower(pg_catalog.pg_get_functiondef(v_function));
    if pg_catalog.strpos(v_body, 'auth.uid()') = 0
      or pg_catalog.strpos(v_body, 'is_anonymous is false') = 0 then
      raise exception 'R3 permanent-account admission guard missing: %',
        v_signature;
    end if;
  end loop;

  if not (select c.relrowsecurity from pg_catalog.pg_class as c
          where c.oid = 'public.user_workout_programs'::regclass)
    or not (select c.relrowsecurity from pg_catalog.pg_class as c
            where c.oid = 'public.user_workout_routines'::regclass)
    or pg_catalog.has_column_privilege(
         'authenticated', 'public.user_workout_routines',
         'program_id', 'UPDATE')
    or pg_catalog.has_table_privilege(
         'authenticated', 'public.user_workout_programs', 'DELETE') then
    raise exception 'R3 RLS or direct-write privilege boundary changed';
  end if;
end;
$r3_preflight$;

revoke all on function public.move_user_workout_routine(
  uuid, uuid, uuid, bigint, uuid
) from public, anon, authenticated, service_role;
revoke all on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) from public, anon, authenticated, service_role;
revoke all on function public.undo_create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, uuid, bigint, uuid
) from public, anon, authenticated, service_role;

grant execute on function public.move_user_workout_routine(
  uuid, uuid, uuid, bigint, uuid
) to authenticated;
grant execute on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) to authenticated;
grant execute on function public.undo_create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, uuid, bigint, uuid
) to authenticated;

-- Post-apply role checks are also enforced in disposable Database CI.
do $r3_assert$
declare
  v_signature text;
  v_function oid;
begin
  for v_signature in
    select signature from (values
      ('public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)'),
      ('public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)'),
      ('public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)')
    ) as exact_move_rpc(signature)
  loop
    v_function := pg_catalog.to_regprocedure(v_signature);
    if not pg_catalog.has_function_privilege(
         'authenticated', v_function, 'EXECUTE')
       or pg_catalog.has_function_privilege('anon', v_function, 'EXECUTE')
       or pg_catalog.has_function_privilege('service_role', v_function, 'EXECUTE')
       or exists (
         select 1 from pg_catalog.pg_proc as p,
           pg_catalog.aclexplode(pg_catalog.coalesce(
             p.proacl, pg_catalog.acldefault('f', p.proowner))) as acl
         where p.oid = v_function
           and acl.grantee = 0
           and acl.privilege_type = 'EXECUTE'
       ) then
      raise exception 'R3 exact RPC ACL postcondition failed: %', v_signature;
    end if;
  end loop;
end;
$r3_assert$;
