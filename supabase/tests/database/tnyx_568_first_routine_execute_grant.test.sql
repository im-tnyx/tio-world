\set ON_ERROR_STOP on
-- #568 / TNYX-78: authenticated-only first-Routine SECDEF API access.
-- DISPOSABLE CI DATABASE ONLY. All grant/revoke rehearsal stays in a
-- transaction and is rolled back; never execute this against hosted data.
begin;

create function pg_temp.assert_true(p_ok boolean, p_reason text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_reason;
  end if;
end;
$$;

create function pg_temp.assert_raises(p_sql text, p_state text, p_reason text)
returns void language plpgsql as $$
declare
  v_state text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_state then
      return;
    end if;
    raise exception 'assertion failed: % (SQLSTATE %, expected %)',
      p_reason, v_state, p_state;
  end;
  raise exception 'assertion failed: % (call succeeded)', p_reason;
end;
$$;

-- The original server-owned function has not been replaced or broadened.
select pg_temp.assert_true(
  (select count(*) = 1 from supabase_migrations.schema_migrations
   where version = '20261021120000')
  and has_function_privilege('authenticated',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE')
  and not has_function_privilege('anon',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE')
  and not has_function_privilege('service_role',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE')
  and (select p.proowner = 'postgres'::regrole and p.prosecdef
              and p.proconfig @> array['search_path=""']::text[]
         from pg_catalog.pg_proc as p
         where p.oid = 'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)'::regprocedure)
  and not has_column_privilege('authenticated', 'public.user_workout_programs',
    'is_default', 'INSERT')
  and not has_column_privilege('authenticated', 'public.user_workout_programs',
    'is_default', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.user_workout_programs', 'DELETE'),
  'grant is exact-signature and does not expose default identity writes'
);

-- A REST anon role must never execute the elevated function.
set local role anon;
select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      null, null, null, null)$$,
  '42501',
  'anon call denied by EXECUTE privilege before RPC body'
);
reset role;

-- An authenticated Postgres role without JWT owner identity must be rejected.
set local role authenticated;
select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      null, null, null, null)$$,
  '28000',
  'authenticated with missing auth.uid() is rejected by owner gate'
);
reset role;

-- A service_role connection is not a bypass route to this RPC.
set local role service_role;
select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      null, null, null, null)$$,
  '42501',
  'service role has no direct EXECUTE access'
);
reset role;

-- Exercise the emergency rollback in a transaction. It must revoke exactly
-- authenticated EXECUTE and leave other existing grants/table privileges intact.
revoke execute on function public.create_user_workout_routine_in_my_program(
  uuid, text, uuid, jsonb
) from authenticated;

select pg_temp.assert_true(
  not has_function_privilege('authenticated',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE')
  and not has_function_privilege('anon',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE')
  and not has_function_privilege('service_role',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE')
  and has_function_privilege('authenticated',
    'public.create_user_workout_routine_with_composition(uuid,uuid,text,uuid,jsonb)', 'EXECUTE')
  and has_column_privilege('authenticated','public.user_workout_programs',
    'name','UPDATE'),
  'rollback removes only the newly granted #568 permission'
);

set local role authenticated;
select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      null, null, null, null)$$,
  '42501',
  'client call denied again after exact-signature rollback'
);
reset role;

-- Rollback removes all fixture functions and restores the post-migration ACL.
rollback;
