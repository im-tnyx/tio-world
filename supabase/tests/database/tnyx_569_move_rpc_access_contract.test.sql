\set ON_ERROR_STOP on
-- #569 R2 current-state ACL gate. Keep this single assertion aligned with the
-- latest reviewed migration. A future grant PR must explicitly change the
-- authenticated expectation for all three signatures in the same commit.
-- Read-only in disposable database CI; no temporary grants or fixtures.

do $$
declare
  v_signature text;
  v_function oid;
begin
  for v_signature in
    select signature from (values
      ('public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)'),
      ('public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)'),
      ('public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)')
    ) as move_rpc(signature)
  loop
    v_function := pg_catalog.to_regprocedure(v_signature);
    if v_function is null then
      raise exception 'missing Move RPC: %', v_signature;
    end if;

    if not exists (
      select 1 from pg_catalog.pg_proc as p
      where p.oid = v_function
        and p.proowner = 'postgres'::regrole
        and p.prosecdef
        and p.proconfig @> array['search_path=""']::text[]
    ) then
      raise exception 'Move RPC owner/security/search_path mismatch: %', v_signature;
    end if;

    if pg_catalog.has_function_privilege('authenticated', v_function, 'EXECUTE')
        or pg_catalog.has_function_privilege('anon', v_function, 'EXECUTE')
        or pg_catalog.has_function_privilege('service_role', v_function, 'EXECUTE')
        or exists (
          select 1 from pg_catalog.pg_proc as p,
            pg_catalog.aclexplode(coalesce(
              p.proacl, pg_catalog.acldefault('f', p.proowner)
            )) as acl
          where p.oid = v_function
            and acl.grantee = 0
            and acl.privilege_type = 'EXECUTE'
        ) then
      raise exception 'Move RPC durable client EXECUTE must remain denied: %', v_signature;
    end if;
  end loop;

  if pg_catalog.has_column_privilege(
      'authenticated', 'public.user_workout_routines', 'program_id', 'UPDATE'
    ) or pg_catalog.has_table_privilege(
      'authenticated', 'public.user_workout_programs', 'DELETE'
    ) then
    raise exception 'direct Move or Program DELETE client privilege detected';
  end if;
end;
$$;
