\set ON_ERROR_STOP on

begin;

create function pg_temp.assert_true(p_ok boolean, p_message text)
returns void
language plpgsql
as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20261028120000')
  and (select count(*) = 1
       from supabase_migrations.schema_migrations
       where version = '20261029120000')
  and (select count(*) = 1
       from supabase_migrations.schema_migrations
       where version = '20261031110000'),
  'gate migration precedes and survives the eight Notes migrations'
);

select pg_temp.assert_true(
  to_regclass('private.routine_notes_data_api_gate_state') is not null
  and (select gate_state = 'disabled'
       from private.routine_notes_data_api_gate_state
       where gate_key = 'routine_notes')
  and (select relrowsecurity
       from pg_catalog.pg_class
       where oid = 'private.routine_notes_data_api_gate_state'::regclass),
  'private gate state exists, defaults disabled and has RLS enabled'
);

select pg_temp.assert_true(
  not has_table_privilege(
    'anon', 'private.routine_notes_data_api_gate_state', 'SELECT'
  )
  and not has_table_privilege(
    'authenticated', 'private.routine_notes_data_api_gate_state', 'SELECT'
  )
  and not has_table_privilege(
    'service_role', 'private.routine_notes_data_api_gate_state', 'SELECT'
  )
  and has_schema_privilege('anon', 'private', 'USAGE')
  and has_schema_privilege('authenticated', 'private', 'USAGE')
  and has_schema_privilege('service_role', 'private', 'USAGE'),
  'client roles can resolve the hook but cannot read or write gate state'
);

select pg_temp.assert_true(
  (select p.proowner = 'postgres'::regrole
          and p.prosecdef
          and p.proconfig @> array['search_path=pg_catalog']::text[]
   from pg_catalog.pg_proc as p
   where p.oid =
     'private.routine_notes_data_api_gate()'::regprocedure)
  and has_function_privilege(
    'anon', 'private.routine_notes_data_api_gate()', 'EXECUTE'
  )
  and has_function_privilege(
    'authenticated', 'private.routine_notes_data_api_gate()', 'EXECUTE'
  )
  and has_function_privilege(
    'service_role', 'private.routine_notes_data_api_gate()', 'EXECUTE'
  )
  and not exists (
    select 1
    from pg_catalog.pg_proc as p,
      pg_catalog.aclexplode(coalesce(
        p.proacl, pg_catalog.acldefault('f', p.proowner)
      )) as acl
    where p.oid = 'private.routine_notes_data_api_gate()'::regprocedure
      and acl.grantee = 0
      and acl.privilege_type = 'EXECUTE'
  ),
  'hook is SECURITY DEFINER, fixed-search-path and least-privilege executable'
);

select pg_temp.assert_true(
  (select rolconfig @> array[
      'pgrst.db_pre_request=private.routine_notes_data_api_gate'
    ]::text[]
   from pg_catalog.pg_roles
   where rolname = 'authenticator'),
  'authenticator has the validated PostgREST pre-request configuration'
);

select pg_temp.assert_true(
  (select pg_get_functiondef(p.oid) like '%''/user_workout_routine_notes''%'
          and pg_get_functiondef(p.oid) like '%''/rpc/mutate_user_workout_routine_note''%'
          and pg_get_functiondef(p.oid) like '%''/rpc/mutate_user_workout_routine_note_legacy''%'
          and pg_get_functiondef(p.oid) like '%''/rpc/reconcile_user_workout_routine_note_mutation''%'
   from pg_catalog.pg_proc as p
   where p.oid =
     'private.routine_notes_data_api_gate()'::regprocedure),
  'hook allowlist uses exact PostgREST leading-slash Notes paths'
);

select pg_temp.assert_true(
  has_table_privilege(
    'authenticated', 'public.user_workout_routine_notes', 'SELECT'
  )
  and not has_table_privilege(
    'anon', 'public.user_workout_routine_notes', 'SELECT'
  )
  and has_function_privilege(
    'authenticated',
    'public.mutate_user_workout_routine_note(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  )
  and has_function_privilege(
    'authenticated',
    'public.reconcile_user_workout_routine_note_mutation(uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'authenticated',
    'public.mutate_user_workout_routine_note_legacy(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  ),
  'final Notes grants from migrations #1 and #6 remain unchanged'
);

select pg_temp.assert_true(
  (select count(*) = 0
   from information_schema.tables
   where table_schema = 'graphql_public'
     and table_name = 'user_workout_routine_notes')
  and not exists (
    select 1
    from pg_catalog.pg_publication_tables
    where schemaname = 'public'
      and tablename = 'user_workout_routine_notes'
  ),
  'Notes are absent from GraphQL schema tables and Realtime publications'
);

do $$
declare
  v_storage_objects bigint;
begin
  if to_regclass('storage.objects') is not null then
    execute $storage$select count(*) from storage.objects where name like '%routine_note%'$storage$
      into v_storage_objects;
    if v_storage_objects <> 0 then
      raise exception 'assertion failed: Notes-like Storage objects exist';
    end if;
  end if;
end;
$$;

rollback;
