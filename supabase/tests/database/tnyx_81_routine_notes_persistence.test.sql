\set ON_ERROR_STOP on

begin;

create function pg_temp.assert_true(p_ok boolean, p_message text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

create function pg_temp.assert_raises(
  p_sql text,
  p_state text,
  p_message text
)
returns void language plpgsql as $$
declare
  v_state text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_state then return; end if;
    raise exception 'assertion failed: % expected %, got %',
      p_message, p_state, v_state;
  end;
  raise exception 'assertion failed: % (succeeded)', p_message;
end;
$$;

create function pg_temp.assert_raises_exact(
  p_sql text,
  p_state text,
  p_error text,
  p_message text
)
returns void language plpgsql as $$
declare
  v_state text;
  v_error text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics
      v_state = returned_sqlstate,
      v_error = message_text;
    if v_state = p_state and v_error = p_error then return; end if;
    raise exception 'assertion failed: % expected %/% got %/%',
      p_message, p_state, p_error, v_state, v_error;
  end;
  raise exception 'assertion failed: % (succeeded)', p_message;
end;
$$;

create function pg_temp.assert_jsonb_equal(
  p_expected jsonb,
  p_actual jsonb,
  p_message text
)
returns void language plpgsql as $$
begin
  if p_expected is distinct from p_actual then
    raise exception 'assertion failed: % expected %, got %',
      p_message, p_expected, p_actual;
  end if;
end;
$$;

create temporary table routine_note_test_results (
  mutation_id uuid primary key,
  result jsonb not null
);
grant insert, select on routine_note_test_results to authenticated;

select pg_temp.assert_true(
  to_regclass('public.user_workout_routine_notes') is not null
  and to_regclass('private.user_workout_routine_note_mutations') is not null
  and (select count(*) = 1
       from information_schema.columns
       where table_schema = 'private'
         and table_name = 'user_workout_routine_note_mutations'
         and column_name = 'result_snapshot')
  and (select count(*) = 1
       from supabase_migrations.schema_migrations
       where version = '20261030065649')
  and (select count(*) = 1
       from supabase_migrations.schema_migrations
       where version = '20261030074635')
  and (select count(*) = 1
       from supabase_migrations.schema_migrations
       where version = '20261030081321')
  and (select count(*) = 1
       from supabase_migrations.schema_migrations
       where version = '20261031100000')
  and (select count(*) = 1
       from supabase_migrations.schema_migrations
       where version = '20261031110000')
  and (select count(*) = 1
       from supabase_migrations.schema_migrations
       where version = '20261031142025')
  and (select pg_catalog.pg_get_constraintdef(constraint_row.oid)
         = 'PRIMARY KEY (user_id, id)'
       from pg_catalog.pg_constraint as constraint_row
       where constraint_row.conrelid =
         'public.user_workout_routine_notes'::regclass
         and constraint_row.conname = 'user_workout_routine_notes_pkey')
  and not exists (
    select 1
    from pg_catalog.pg_index as index_catalog
    where index_catalog.indrelid =
        'public.user_workout_routine_notes'::regclass
      and index_catalog.indisunique
      and index_catalog.indpred is null
      and pg_catalog.pg_get_indexdef(index_catalog.indexrelid, 1, true) = 'id'
  )
  and not exists (
    select 1
    from private.user_workout_routine_note_mutations
    where result_snapshot is null
  )
  and has_table_privilege(
    'authenticated', 'public.user_workout_routine_notes', 'SELECT'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_routine_notes', 'INSERT'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_routine_notes', 'UPDATE'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_routine_notes', 'DELETE'
  )
  and not has_table_privilege(
    'authenticated', 'private.user_workout_routine_note_mutations', 'SELECT'
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
    'private.expire_user_workout_routine_note_receipt(uuid,uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'service_role',
    'private.expire_user_workout_routine_note_receipt(uuid,uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'anon',
    'public.mutate_user_workout_routine_note(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  ),
  'Notes tables, receipts, legacy snapshot gate and approved migration versions are present'
);

select pg_temp.assert_true(
  (select index_catalog.indisvalid
      and index_catalog.indisready
      and index_catalog.indpred is null
      and access_method.amname = 'btree'
      and pg_catalog.pg_get_indexdef(index_catalog.indexrelid, 1, true)
        = 'user_id'
   from pg_catalog.pg_index as index_catalog
   join pg_catalog.pg_class as index_relation
     on index_relation.oid = index_catalog.indexrelid
   join pg_catalog.pg_am as access_method
     on access_method.oid = index_relation.relam
   where index_relation.oid =
     'public.idx_user_workout_routine_notes_user_id'::regclass
     and index_catalog.indrelid =
       'public.user_workout_routine_notes'::regclass),
  'user-wide quota index is valid, ready, non-partial B-tree beginning with user_id'
);

select pg_temp.assert_true(
  has_function_privilege(
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
    'anon',
    'public.mutate_user_workout_routine_note(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'anon',
    'public.reconcile_user_workout_routine_note_mutation(uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'service_role',
    'public.mutate_user_workout_routine_note(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'service_role',
    'public.reconcile_user_workout_routine_note_mutation(uuid)',
    'EXECUTE'
  ),
  'public Notes RPCs have authenticated-only effective EXECUTE privileges'
);

select pg_temp.assert_true(
  (select procedure.prosecdef
          and procedure.proconfig @> array['search_path=""']
   from pg_catalog.pg_proc as procedure
   where procedure.oid =
     'private.expire_user_workout_routine_note_receipt(uuid,uuid)'::regprocedure),
  'private receipt expiry helper is SECURITY DEFINER with empty search_path'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from pg_catalog.pg_proc as function_catalog
    cross join lateral pg_catalog.aclexplode(
      coalesce(
        function_catalog.proacl,
        pg_catalog.acldefault('f'::"char", function_catalog.proowner)
      )
    ) as privilege
    where function_catalog.oid in (
      'public.mutate_user_workout_routine_note(text,uuid,uuid,text,text,text,bigint,uuid)'::regprocedure,
      'public.reconcile_user_workout_routine_note_mutation(uuid)'::regprocedure
    )
    and privilege.grantee = 0
    and privilege.privilege_type = 'EXECUTE'
  ),
  'public pseudo-role has no effective EXECUTE grant on Notes RPCs'
);

select pg_temp.assert_true(
  not has_function_privilege(
    'anon',
    'public.mutate_user_workout_routine_note_legacy(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'authenticated',
    'public.mutate_user_workout_routine_note_legacy(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  )
  and not has_function_privilege(
    'service_role',
    'public.mutate_user_workout_routine_note_legacy(text,uuid,uuid,text,text,text,bigint,uuid)',
    'EXECUTE'
  )
  and not exists (
    select 1
    from pg_catalog.pg_proc as function_catalog
    cross join lateral pg_catalog.aclexplode(
      coalesce(
        function_catalog.proacl,
        pg_catalog.acldefault('f'::"char", function_catalog.proowner)
      )
    ) as privilege
    where function_catalog.oid =
      'public.mutate_user_workout_routine_note_legacy(text,uuid,uuid,text,text,text,bigint,uuid)'::regprocedure
      and privilege.grantee = 0
      and privilege.privilege_type = 'EXECUTE'
  ),
  'legacy Notes RPC is not executable by client roles or PUBLIC'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from unnest(array[
      'private.user_workout_routine_note_payload(uuid,uuid)'::regprocedure,
      'private.user_workout_routine_note_receipt_snapshot()'::regprocedure,
      'private.normalize_user_workout_routine_note_body(text)'::regprocedure,
      'private.normalize_user_workout_routine_note_body_trigger()'::regprocedure,
      'private.enforce_user_workout_routine_note_total_quota()'::regprocedure
    ]) as helper(function_oid)
    where has_function_privilege('anon', helper.function_oid, 'EXECUTE')
       or has_function_privilege('authenticated', helper.function_oid, 'EXECUTE')
       or has_function_privilege('service_role', helper.function_oid, 'EXECUTE')
       or exists (
         select 1
         from pg_catalog.aclexplode(
           coalesce(
             (select p.proacl from pg_catalog.pg_proc as p
              where p.oid = helper.function_oid),
             pg_catalog.acldefault(
               'f'::"char",
               (select p.proowner from pg_catalog.pg_proc as p
                where p.oid = helper.function_oid)
             )
           )
         ) as privilege
         where privilege.grantee = 0
           and privilege.privilege_type = 'EXECUTE'
       )
  ),
  'Notes-specific private helpers have no effective client or PUBLIC EXECUTE'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from pg_catalog.pg_proc as function_catalog
    where function_catalog.oid in (
      'public.mutate_user_workout_routine_note(text,uuid,uuid,text,text,text,bigint,uuid)'::regprocedure,
      'public.reconcile_user_workout_routine_note_mutation(uuid)'::regprocedure,
      'public.mutate_user_workout_routine_note_legacy(text,uuid,uuid,text,text,text,bigint,uuid)'::regprocedure,
      'private.user_workout_routine_note_payload(uuid,uuid)'::regprocedure,
      'private.user_workout_routine_note_receipt_snapshot()'::regprocedure
    )
    and (
      not function_catalog.prosecdef
      or not exists (
        select 1
        from unnest(coalesce(function_catalog.proconfig, array[]::text[])) as setting(value)
        where setting.value = 'search_path=""'
      )
    )
  ),
  'Notes SECURITY DEFINER functions use an empty search_path'
);
select pg_temp.assert_true(
  not exists (
    select 1
    from pg_catalog.pg_proc as function_catalog
    where function_catalog.oid in (
      'private.normalize_user_workout_routine_note_body(text)'::regprocedure,
      'private.normalize_user_workout_routine_note_body_trigger()'::regprocedure,
      'private.enforce_user_workout_routine_note_total_quota()'::regprocedure
    )
    and function_catalog.prosecdef
  ),
  'Notes trigger helpers remain SECURITY INVOKER'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from pg_catalog.pg_proc as function_catalog
    where function_catalog.oid in (
      'public.mutate_user_workout_routine_note(text,uuid,uuid,text,text,text,bigint,uuid)'::regprocedure,
      'public.reconcile_user_workout_routine_note_mutation(uuid)'::regprocedure,
      'public.mutate_user_workout_routine_note_legacy(text,uuid,uuid,text,text,text,bigint,uuid)'::regprocedure,
      'private.user_workout_routine_note_payload(uuid,uuid)'::regprocedure,
      'private.user_workout_routine_note_receipt_snapshot()'::regprocedure,
      'private.normalize_user_workout_routine_note_body(text)'::regprocedure,
      'private.normalize_user_workout_routine_note_body_trigger()'::regprocedure,
      'private.enforce_user_workout_routine_note_total_quota()'::regprocedure
    )
    and pg_catalog.pg_get_userbyid(function_catalog.proowner)
      in ('anon', 'authenticated', 'service_role')
  ),
  'Notes functions are not owned by client roles'
);

select pg_temp.assert_true(
  (select count(*) = 2
   from pg_catalog.pg_namespace as namespace_catalog
   where namespace_catalog.nspname in ('public', 'private')
     and pg_catalog.pg_get_userbyid(namespace_catalog.nspowner)
       not in ('anon', 'authenticated', 'service_role'))
  and not has_schema_privilege('anon', 'public', 'CREATE')
  and not has_schema_privilege('authenticated', 'public', 'CREATE')
  and not has_schema_privilege('service_role', 'public', 'CREATE')
  and not has_schema_privilege('anon', 'private', 'CREATE')
  and not has_schema_privilege('authenticated', 'private', 'CREATE')
  and not has_schema_privilege('service_role', 'private', 'CREATE'),
  'public/private schema owners and CREATE privileges preserve the security boundary'
);

select nspname as schema_name,
       pg_catalog.pg_get_userbyid(nspowner) as schema_owner,
       has_schema_privilege('anon', nspname, 'USAGE') as anon_usage,
       has_schema_privilege('authenticated', nspname, 'USAGE') as authenticated_usage,
       has_schema_privilege('service_role', nspname, 'USAGE') as service_role_usage
from pg_catalog.pg_namespace
where nspname in ('public', 'private')
order by nspname;

select pg_temp.assert_true(
  (select not prosecdef
      and pg_catalog.pg_get_userbyid(proowner)
        not in ('anon', 'authenticated', 'service_role')
      and coalesce(array_to_string(proconfig, ','), '')
        like '%search_path=public, pg_temp%'
      and pg_catalog.pg_get_functiondef(oid) like '%timezone%'
   from pg_catalog.pg_proc
   where oid = 'public.set_row_updated_at()'::regprocedure),
  'shared set_row_updated_at remains SECURITY INVOKER with its reviewed search_path and body'
);
select oid::regprocedure as function_name,
       pg_catalog.pg_get_userbyid(proowner) as function_owner,
       proacl as function_acl,
       proconfig as function_config,
       prosecdef as security_definer,
       pg_catalog.pg_get_functiondef(oid) as function_definition
from pg_catalog.pg_proc
where oid = 'public.set_row_updated_at()'::regprocedure;

select pg_temp.assert_true(
  has_table_privilege('authenticated', 'public.user_workout_routine_notes', 'SELECT')
  and not has_table_privilege('anon', 'public.user_workout_routine_notes', 'SELECT')
  and not has_table_privilege('service_role', 'public.user_workout_routine_notes', 'SELECT')
  and not has_table_privilege('anon', 'public.user_workout_routine_notes', 'INSERT')
  and not has_table_privilege('anon', 'public.user_workout_routine_notes', 'UPDATE')
  and not has_table_privilege('anon', 'public.user_workout_routine_notes', 'DELETE')
  and not has_table_privilege('authenticated', 'public.user_workout_routine_notes', 'INSERT')
  and not has_table_privilege('authenticated', 'public.user_workout_routine_notes', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.user_workout_routine_notes', 'DELETE')
  and not has_table_privilege('service_role', 'public.user_workout_routine_notes', 'INSERT')
  and not has_table_privilege('service_role', 'public.user_workout_routine_notes', 'UPDATE')
  and not has_table_privilege('service_role', 'public.user_workout_routine_notes', 'DELETE')
  and not has_table_privilege('anon', 'private.user_workout_routine_note_mutations', 'SELECT')
  and not has_table_privilege('anon', 'private.user_workout_routine_note_mutations', 'INSERT')
  and not has_table_privilege('authenticated', 'private.user_workout_routine_note_mutations', 'SELECT')
  and not has_table_privilege('authenticated', 'private.user_workout_routine_note_mutations', 'INSERT')
  and not has_table_privilege('service_role', 'private.user_workout_routine_note_mutations', 'SELECT')
  and not has_table_privilege('service_role', 'private.user_workout_routine_note_mutations', 'INSERT'),
  'Notes and receipt table ACLs deny direct ordinary-client writes and receipt access'
);

select pg_temp.assert_true(
  (select relrowsecurity
   from pg_class where oid = 'public.user_workout_routine_notes'::regclass)
  and (select relrowsecurity
   from pg_class
   where oid = 'private.user_workout_routine_note_mutations'::regclass),
  'Notes and receipt tables have RLS enabled'
);

insert into auth.users (id, email) values
  ('a8100000-0000-4000-8000-000000000001', 'notes-a@example.test'),
  ('a8100000-0000-4000-8000-000000000002', 'notes-b@example.test');
insert into public.user_workout_programs (id, user_id, name) values
  ('a8100000-0000-4000-8000-000000000011',
   'a8100000-0000-4000-8000-000000000001', 'Program A'),
  ('a8100000-0000-4000-8000-000000000012',
   'a8100000-0000-4000-8000-000000000002', 'Program B');
insert into public.user_workout_routines (id, user_id, program_id, name) values
  ('a8100000-0000-4000-8000-000000000021',
   'a8100000-0000-4000-8000-000000000001',
   'a8100000-0000-4000-8000-000000000011', 'Routine A'),
  ('a8100000-0000-4000-8000-000000000022',
   'a8100000-0000-4000-8000-000000000002',
   'a8100000-0000-4000-8000-000000000012', 'Routine B'),
  ('a8100000-0000-4000-8000-000000000023',
   'a8100000-0000-4000-8000-000000000001',
   'a8100000-0000-4000-8000-000000000011', 'Routine Delete'),
  ('a8100000-0000-4000-8000-000000000024',
   'a8100000-0000-4000-8000-000000000001',
   'a8100000-0000-4000-8000-000000000011', 'Routine Snapshot Tests');
insert into public.user_workout_routines (id, user_id, program_id, name) values
  ('a8100000-0000-4000-8000-000000000025',
   'a8100000-0000-4000-8000-000000000001',
   'a8100000-0000-4000-8000-000000000011', 'Routine Contract Tests');
insert into public.user_workout_routines (id, user_id, program_id, name) values
  ('a8100000-0000-4000-8000-000000000026',
   'a8100000-0000-4000-8000-000000000001',
   'a8100000-0000-4000-8000-000000000011', 'Routine UUID Isolation Test');
insert into public.user_workout_exercises (
  id, user_id, display_name
) values (
  'a8100000-0000-4000-8000-000000000031',
  'a8100000-0000-4000-8000-000000000001',
  'Custom Notes Exercise'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);

savepoint total_note_quota_test;
do $$
declare
  i integer;
  j integer;
  routine_id uuid;
  note_id uuid;
  mutation_id uuid;
  result jsonb;
begin
  for i in 1..10 loop
    routine_id := (
      'a8100000-0000-4000-8000-' || lpad((1000 + i)::text, 12, '0')
    )::uuid;
    insert into public.user_workout_routines (id, user_id, program_id, name)
    values (
      routine_id,
      'a8100000-0000-4000-8000-000000000001',
      'a8100000-0000-4000-8000-000000000011',
      format('Total Quota Routine %s', i)
    );
    for j in 1..5 loop
      note_id := (
        'a8100000-0000-4000-8000-' || lpad((2000 + (i * 10) + j)::text, 12, '0')
      )::uuid;
      mutation_id := (
        'a8100000-0000-4000-8000-' || lpad((3000 + (i * 10) + j)::text, 12, '0')
      )::uuid;
      result := public.mutate_user_workout_routine_note(
        'create', note_id, routine_id, null, 'pinned_routine',
        format('Total quota %s/%s', i, j), null, mutation_id
      );
      if result->>'status' <> 'applied' then
        raise exception 'assertion failed: total quota setup mutation was not applied';
      end if;
    end loop;
  end loop;
end;
$$;
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000040000001',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    'the 51st active Note is rejected across distinct scopes', null,
    'a8100000-0000-4000-8000-000040000002'
  )$$,
  'P0001', 'the user-wide active Notes quota is authoritative across scopes'
);
rollback to savepoint total_note_quota_test;

select pg_temp.assert_raises(
  $$insert into public.user_workout_routine_notes (
      id, user_id, routine_id, note_type, body
    ) values (
      'a8100000-0000-4000-8000-000000000101',
      'a8100000-0000-4000-8000-000000000001',
      'a8100000-0000-4000-8000-000000000021',
      'pinned_routine', 'direct write'
    )$$,
  '42501', 'authenticated cannot write Notes directly'
);
select pg_temp.assert_raises(
  $$select * from private.user_workout_routine_note_mutations$$,
  '42501', 'authenticated cannot read mutation receipts directly'
);

insert into routine_note_test_results (mutation_id, result)
values (
  'a8100000-0000-4000-8000-000000000201',
  public.mutate_user_workout_routine_note(
    'create',
    'a8100000-0000-4000-8000-000000000101',
    'a8100000-0000-4000-8000-000000000021',
    null, null, '  Routine note  ', null,
    'a8100000-0000-4000-8000-000000000201'
  )
);
select pg_temp.assert_true(
  (select result->>'status' = 'applied'
   from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000201'),
  'create defaults to a Routine Note and normalizes body text'
);
select pg_temp.assert_true(
  (select note_type = 'pinned_routine'
      and body = 'Routine note' and revision = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000101'),
  'created Routine Note has stable identity and initial revision'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000130',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    U&'\00A0\0009Unicode \+01F600\2028', null,
    'a8100000-0000-4000-8000-000000000230'
  )->'note'->>'body') = 'Unicode 😀',
  'SQL body normalization trims the Dart Unicode White_Space set'
);
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000131',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    U&'\000A\0009\00A0', null, 'a8100000-0000-4000-8000-000000000231'
  )$$,
  '22023', 'SQL rejects Unicode whitespace-only bodies'
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000132',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    repeat('😀', 500), null, 'a8100000-0000-4000-8000-000000000232'
  )->>'status') = 'applied',
  'SQL accepts 500 Unicode scalar values'
);
do $$
declare
  v_body text := repeat('😀', 500);
  v_first jsonb;
  v_replay jsonb;
begin
  v_first := public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000134',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    U&'\00A0' || v_body || U&'\00A0', null,
    'a8100000-0000-4000-8000-000000000234'
  );
  v_replay := public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000134',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    v_body, null, 'a8100000-0000-4000-8000-000000000234'
  );

  perform pg_temp.assert_true(
    v_first->>'status' = 'applied'
    and v_first = v_replay
    and v_first->'note'->>'body' = v_body
    and pg_catalog.char_length(v_first->'note'->>'body') = 500
    and position(U&'\00A0' in v_first->'note'->>'body') = 0,
    'NBSP-wrapped 500-code-point RPC normalizes before validation and hashes the normalized request for exact replay'
  );
  perform pg_temp.assert_true(
    (select body = v_body
     from public.user_workout_routine_notes
     where id = 'a8100000-0000-4000-8000-000000000134'),
    'NBSP-wrapped 500-code-point request persists exactly the normalized body'
  );
end;
$$;
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000133',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    repeat('😀', 501), null, 'a8100000-0000-4000-8000-000000000233'
  )$$,
  '22023', 'SQL rejects 501 Unicode scalar values'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create',
    'a8100000-0000-4000-8000-000000000102',
    null,
    'a8100000-0000-4000-8000-000000000031',
    'pinned_exercise', 'Custom exercise note', null,
    'a8100000-0000-4000-8000-000000000202'
  )->>'status') = 'applied',
  'active owner-bound Custom Exercise accepts an Exercise Note'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create',
    'a8100000-0000-4000-8000-000000000103',
    null, 'ex_barbell_bench_press', 'pinned_exercise',
    'Catalog exercise note', null,
    'a8100000-0000-4000-8000-000000000203'
  )->>'status') = 'applied',
  'catalog ExerciseRef remains a catalog identity and is not mirrored'
);

insert into routine_note_test_results (mutation_id, result)
values (
  'a8100000-0000-4000-8000-000000000204',
  public.mutate_user_workout_routine_note(
    'update',
    'a8100000-0000-4000-8000-000000000101',
    null, null, null, 'Updated note', 0,
    'a8100000-0000-4000-8000-000000000204'
  )
);
select pg_temp.assert_true(
  ((select result->>'revision'
    from routine_note_test_results
    where mutation_id = 'a8100000-0000-4000-8000-000000000204')::bigint = 1),
  'body update advances revision exactly once'
);
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'update',
    'a8100000-0000-4000-8000-000000000101',
    null, null, null, 'Stale update', 0,
    'a8100000-0000-4000-8000-000000000205'
  )$$,
  'P0001', 'stale revision is rejected without changing body'
);

insert into routine_note_test_results (mutation_id, result)
values (
  'a8100000-0000-4000-8000-000000000206',
  public.mutate_user_workout_routine_note(
    'transfer',
    'a8100000-0000-4000-8000-000000000101',
    null, 'a8100000-0000-4000-8000-000000000031',
    'pinned_exercise', null, 1,
    'a8100000-0000-4000-8000-000000000206'
  )
);
select pg_temp.assert_true(
  ((select result->'note'->>'id'
    from routine_note_test_results
    where mutation_id = 'a8100000-0000-4000-8000-000000000206') =
    'a8100000-0000-4000-8000-000000000101'),
  'type transfer preserves Note UUID and body'
);
select pg_temp.assert_true(
  (select routine_id is null
      and exercise_ref = 'a8100000-0000-4000-8000-000000000031'
      and body = 'Updated note'
      and revision = 2
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000101'),
  'type transfer changes only the approved Note scope'
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'update',
    'a8100000-0000-4000-8000-000000000101',
    null, null, null, 'Transferred note', 2,
    'a8100000-0000-4000-8000-000000000208'
  )->>'revision')::bigint = 3,
  'later update advances the transferred Note revision'
);

-- Fill the Routine scope to the approved cap.
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000111',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 1', null, 'a8100000-0000-4000-8000-000000000211');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000112',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 2', null, 'a8100000-0000-4000-8000-000000000212');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000113',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 3', null, 'a8100000-0000-4000-8000-000000000213');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000114',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 4', null, 'a8100000-0000-4000-8000-000000000214');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000115',
  'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
  'Routine 5', null, 'a8100000-0000-4000-8000-000000000215');
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000116',
    'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
    'Routine 6', null, 'a8100000-0000-4000-8000-000000000216'
  )$$,
  'P0001', 'sixth Note is rejected at the authoritative quota'
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000111',
    'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
    'Routine 1', null, 'a8100000-0000-4000-8000-000000000211'
  )->'note'->>'id') = 'a8100000-0000-4000-8000-000000000111',
  'exact create retry returns the durable receipt without a duplicate'
);
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000111',
    'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
    'Different request', null, 'a8100000-0000-4000-8000-000000000211'
  )$$,
  'P0001', 'reusing a mutation ID for a different request is rejected'
);

-- The two canonical scopes have independent caps. Fill Exercise scope, then
-- verify a full destination rejects a transfer without changing its source.
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000104',
  null, 'ex_barbell_bench_press', 'pinned_exercise',
  'Catalog exercise note 2', null, 'a8100000-0000-4000-8000-000000000314');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000105',
  null, 'ex_barbell_bench_press', 'pinned_exercise',
  'Catalog exercise note 3', null, 'a8100000-0000-4000-8000-000000000315');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000106',
  null, 'ex_barbell_bench_press', 'pinned_exercise',
  'Catalog exercise note 4', null, 'a8100000-0000-4000-8000-000000000316');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000109',
  null, 'ex_barbell_bench_press', 'pinned_exercise',
  'Catalog exercise note 5', null, 'a8100000-0000-4000-8000-000000000321');
select public.mutate_user_workout_routine_note(
  'create', 'a8100000-0000-4000-8000-000000000107',
  'a8100000-0000-4000-8000-000000000023', null, 'pinned_routine',
  'Transfer source', null, 'a8100000-0000-4000-8000-000000000217');
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'transfer', 'a8100000-0000-4000-8000-000000000107',
    null, 'ex_barbell_bench_press', 'pinned_exercise', null, 0,
    'a8100000-0000-4000-8000-000000000218'
  )$$,
  'P0001', 'full destination rejects transfer atomically'
);
select pg_temp.assert_true(
  (select note_type = 'pinned_routine'
      and routine_id = 'a8100000-0000-4000-8000-000000000023'
      and body = 'Transfer source' and revision = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000107'),
  'failed transfer retains source scope and body'
);

-- Archiving a Custom Exercise retains its existing Note and permits editing
-- that existing Note, while new Notes on the archived ref are rejected.
reset role;
update public.user_workout_exercises
set status = 'archived'
where id = 'a8100000-0000-4000-8000-000000000031';
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_true(
  (select count(*) = 1
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000102'),
  'archiving a Custom Exercise does not delete its existing Note'
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'update', 'a8100000-0000-4000-8000-000000000102',
    null, null, null, 'Archived Exercise note', 0,
    'a8100000-0000-4000-8000-000000000219'
  )->>'revision')::bigint = 1,
  'existing archived Exercise Note remains safely editable'
);
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000108',
    null, 'a8100000-0000-4000-8000-000000000031', 'pinned_exercise',
    'New archived note', null, 'a8100000-0000-4000-8000-000000000220'
  )$$,
  'P0001', 'new Notes cannot attach to an archived Custom Exercise'
);

insert into routine_note_test_results (mutation_id, result)
values (
  'a8100000-0000-4000-8000-000000000222',
  public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000110',
    'a8100000-0000-4000-8000-000000000023', null, 'pinned_routine',
    'Routine deletion note', null, 'a8100000-0000-4000-8000-000000000222'
  )
);

select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'delete', 'a8100000-0000-4000-8000-000000000101',
    null, null, null, null, 3,
    'a8100000-0000-4000-8000-000000000207'
  )->>'status') = 'deleted',
  'Delete removes exactly one Note'
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'delete', 'a8100000-0000-4000-8000-000000000101',
    null, null, null, null, 3,
    'a8100000-0000-4000-8000-000000000207'
  )->>'status') = 'deleted'
  and (public.mutate_user_workout_routine_note(
    'delete', 'a8100000-0000-4000-8000-000000000101',
    null, null, null, null, 3,
    'a8100000-0000-4000-8000-000000000207'
  )->>'note_id') = 'a8100000-0000-4000-8000-000000000101'
  and (public.mutate_user_workout_routine_note(
    'delete', 'a8100000-0000-4000-8000-000000000101',
    null, null, null, null, 3,
    'a8100000-0000-4000-8000-000000000207'
  )->>'revision')::bigint = 3
  and not exists (
    select 1 from public.user_workout_routine_notes
    where id = 'a8100000-0000-4000-8000-000000000101'
  ),
  'Delete replay cannot resurrect a Note'
);
select pg_temp.assert_jsonb_equal(
  (select result from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000201'),
  public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000101',
    'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
    '  Routine note  ', null,
    'a8100000-0000-4000-8000-000000000201'
  ),
  'create replay returns the complete immutable result after deletion'
);
select pg_temp.assert_jsonb_equal(
  (select result from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000206'),
  public.mutate_user_workout_routine_note(
    'transfer', 'a8100000-0000-4000-8000-000000000101',
    null, 'a8100000-0000-4000-8000-000000000031', 'pinned_exercise',
    null, 1, 'a8100000-0000-4000-8000-000000000206'
  ),
  'transfer replay returns the complete original result after deletion'
);
select pg_temp.assert_jsonb_equal(
  (select result from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000204'),
  public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000204'
  ),
  'reconciliation returns the complete immutable first update result'
);

reset role;
select pg_temp.assert_true(
  (select result_snapshot->>'status' = 'applied'
      and result_snapshot = (
        select result from routine_note_test_results
        where mutation_id = 'a8100000-0000-4000-8000-000000000204'
      )
   from private.user_workout_routine_note_mutations
   where mutation_id = 'a8100000-0000-4000-8000-000000000204'),
  'successful mutation receipts store the complete private result snapshot'
);

delete from public.user_workout_routine_notes
where id = 'a8100000-0000-4000-8000-000000000102';
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'update', 'a8100000-0000-4000-8000-000000000110',
    null, null, null, 'Routine deletion note v2', 0,
    'a8100000-0000-4000-8000-000000000223'
  )->>'revision')::bigint = 1
  and (public.mutate_user_workout_routine_note(
    'update', 'a8100000-0000-4000-8000-000000000110',
    null, null, null, 'Routine deletion note v3', 1,
    'a8100000-0000-4000-8000-000000000224'
  )->>'revision')::bigint = 2,
  'later updates advance the Routine deletion fixture revision'
);
reset role;
delete from public.user_workout_routine_notes
where id = 'a8100000-0000-4000-8000-000000000102';
delete from public.user_workout_routines
where id = 'a8100000-0000-4000-8000-000000000023';
select pg_temp.assert_true(
  not exists (
    select 1 from public.user_workout_routine_notes
    where routine_id = 'a8100000-0000-4000-8000-000000000023'
  ),
  'Routine deletion cascades only its Routine Notes'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_jsonb_equal(
  (select result from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000222'),
  public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000110',
    'a8100000-0000-4000-8000-000000000023', null, 'pinned_routine',
    'Routine deletion note', null, 'a8100000-0000-4000-8000-000000000222'
  ),
  'direct mutation replay returns the complete result after Routine cascade'
);
select pg_temp.assert_jsonb_equal(
  (select result from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000222'),
  public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000222'
  ),
  'reconciliation retains the complete result after Routine cascade'
);
reset role;
select pg_temp.assert_true(
  (select count(*) = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000110')
  and (select count(*) = 1
       from private.user_workout_routine_note_mutations
       where mutation_id = 'a8100000-0000-4000-8000-000000000222'),
  'Routine cascade replay does not create a duplicate Note or receipt'
);

-- A receipt created before the snapshot migration has no result_snapshot. The
-- replay and reconciliation paths must fail closed without reading a live Note.
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000120',
    'a8100000-0000-4000-8000-000000000024', null, 'pinned_routine',
    'Legacy receipt note', null, 'a8100000-0000-4000-8000-000000000225'
  )->>'status') = 'applied',
  'legacy receipt fixture starts as a valid completed mutation'
);
reset role;
update private.user_workout_routine_note_mutations
set result_snapshot = null
where mutation_id = 'a8100000-0000-4000-8000-000000000225';
delete from public.user_workout_routine_notes
where id = 'a8100000-0000-4000-8000-000000000120';
set local role authenticated;
select pg_temp.assert_raises_exact(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000120',
    'a8100000-0000-4000-8000-000000000024', null, 'pinned_routine',
    'Legacy receipt note', null, 'a8100000-0000-4000-8000-000000000225'
  )$$,
  'P0001', 'routine_note_mutation_snapshot_unavailable',
  'legacy mutation replay fails closed without a snapshot'
);
select pg_temp.assert_raises_exact(
  $$select public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000225'
  )$$,
  'P0001', 'routine_note_mutation_snapshot_unavailable',
  'legacy mutation reconciliation fails closed without a snapshot'
);
reset role;
select pg_temp.assert_true(
  (select count(*) = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000120')
  and (select result_snapshot is null
       from private.user_workout_routine_note_mutations
       where mutation_id = 'a8100000-0000-4000-8000-000000000225'),
  'legacy receipt remains null and never fabricates a current result'
);

-- Install a disposable AFTER trigger so the already-completed snapshot trigger
-- runs first, then force the receipt insert to fail before the RPC can commit.
create function pg_temp.routine_note_test_snapshot_failure()
returns trigger language plpgsql as $$
begin
  raise exception 'routine_note_test_snapshot_failure' using errcode = 'P0001';
end;
$$;
create trigger zzz_routine_note_test_snapshot_failure
after insert on private.user_workout_routine_note_mutations
for each row
execute function pg_temp.routine_note_test_snapshot_failure();
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_raises_exact(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000121',
    'a8100000-0000-4000-8000-000000000024', null, 'pinned_routine',
    'Rollback trigger note', null, 'a8100000-0000-4000-8000-000000000226'
  )$$,
  'P0001', 'routine_note_test_snapshot_failure',
  'snapshot failure propagates from the public mutation RPC'
);
reset role;
select pg_temp.assert_true(
  (select count(*) = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000121')
  and (select count(*) = 0
       from private.user_workout_routine_note_mutations
       where mutation_id = 'a8100000-0000-4000-8000-000000000226'),
  'snapshot failure rolls back the Note and receipt together'
);
drop trigger zzz_routine_note_test_snapshot_failure
  on private.user_workout_routine_note_mutations;
drop function pg_temp.routine_note_test_snapshot_failure();
set local role authenticated;
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000122',
    'a8100000-0000-4000-8000-000000000024', null, 'pinned_routine',
    'Post-rollback normal note', null, 'a8100000-0000-4000-8000-000000000227'
  )->>'status') = 'applied',
  'normal mutation succeeds after failure injection is removed'
);
select pg_temp.assert_true(
  (select count(*) = 1
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000122'),
  'normal mutation persists after failure injection is removed'
);

select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000002',
  true
);
select pg_temp.assert_true(
  (select count(*) = 0
   from public.user_workout_routine_notes),
  'cross-owner Note reads return no rows under RLS'
);

reset role;
select pg_temp.assert_true(
  (select count(*) = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000102'),
  'deleted Note remains absent for every owner'
);

-- Verify that receipt ownership remains isolated when both users reuse the
-- same mutation UUID on the same database connection.
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000002',
  true
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000901',
    'a8100000-0000-4000-8000-000000000022', null, 'pinned_routine',
    'User B original result', null,
    'a8100000-0000-4000-8000-000000000902'
  )->'note'->>'id') = 'a8100000-0000-4000-8000-000000000901',
  'User B creates the original owner-scoped mutation receipt'
);

select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_raises_exact(
  $$select public.mutate_user_workout_routine_note(
    'update', 'a8100000-0000-4000-8000-000000000901',
    null, null, null, 'User A must not update User B', 0,
    'a8100000-0000-4000-8000-000000000904'
  )$$,
  'P0002', 'routine_note_not_found',
  'User A cannot update User B Note'
);
reset role;
select pg_temp.assert_true(
  (select body = 'User B original result' and revision = 0
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000901'
     and user_id = 'a8100000-0000-4000-8000-000000000002')
  and (select count(*) = 0
       from private.user_workout_routine_note_mutations
       where user_id = 'a8100000-0000-4000-8000-000000000001'
         and mutation_id = 'a8100000-0000-4000-8000-000000000904'),
  'cross-owner update leaves User B Note and User A receipts unchanged'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_raises_exact(
  $$select public.mutate_user_workout_routine_note(
    'delete', 'a8100000-0000-4000-8000-000000000901',
    null, null, null, null, 0,
    'a8100000-0000-4000-8000-000000000905'
  )$$,
  'P0002', 'routine_note_not_found',
  'User A cannot delete User B Note'
);
reset role;
select pg_temp.assert_true(
  (select count(*) = 1
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000901'
     and user_id = 'a8100000-0000-4000-8000-000000000002')
  and (select count(*) = 0
       from private.user_workout_routine_note_mutations
       where user_id = 'a8100000-0000-4000-8000-000000000001'
         and mutation_id = 'a8100000-0000-4000-8000-000000000905'),
  'cross-owner delete leaves User B Note and User A receipts unchanged'
);

-- A foreign owner's UUID is not a global namespace collision. The same
-- request shape succeeds for User A without revealing User B's row, and both
-- accounts retain independent payloads under the same UUID.
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000901',
    'a8100000-0000-4000-8000-000000000026', null, 'pinned_routine',
    'User A same UUID private result', null,
    'a8100000-0000-4000-8000-000000000906'
  )->'note'->>'id') = 'a8100000-0000-4000-8000-000000000901',
  'User A can create their own Note with a UUID already used by User B'
);
reset role;
select pg_temp.assert_true(
  (select count(*) = 1
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000901'
     and user_id = 'a8100000-0000-4000-8000-000000000001'
     and body = 'User A same UUID private result')
  and (select count(*) = 1
       from public.user_workout_routine_notes
       where id = 'a8100000-0000-4000-8000-000000000901'
         and user_id = 'a8100000-0000-4000-8000-000000000002'
         and body = 'User B original result'),
  'same UUID creates two independently owner-scoped Note identities'
);
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_true(
  (select count(*) = 1
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000901'
     and user_id = 'a8100000-0000-4000-8000-000000000001'
     and body = 'User A same UUID private result'),
  'RLS exposes only User A row when Note UUID is shared across owners'
);
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000002',
  true
);
select pg_temp.assert_true(
  (select count(*) = 1
   from public.user_workout_routine_notes
   where id = 'a8100000-0000-4000-8000-000000000901'
     and user_id = 'a8100000-0000-4000-8000-000000000002'
     and body = 'User B original result'),
  'RLS exposes only User B row when Note UUID is shared across owners'
);
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_raises_exact(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000901',
    'a8100000-0000-4000-8000-000000000026', null, 'pinned_routine',
    'same owner duplicate', null,
    'a8100000-0000-4000-8000-000000000907'
  )$$,
  'P0001', 'routine_note_id_conflict',
  'a duplicate Note UUID within one owner remains a client-safe conflict'
);
reset role;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
select pg_temp.assert_jsonb_equal(
  '{"status":"pending"}'::jsonb,
  public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  ),
  'User A cannot reconcile User B mutation receipt'
);
select pg_temp.assert_true(
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000903',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    'User A independent result', null,
    'a8100000-0000-4000-8000-000000000902'
  )->'note'->>'id') = 'a8100000-0000-4000-8000-000000000903',
  'User A independently applies the same mutation UUID'
);
select pg_temp.assert_true(
  (public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  )->'note'->>'id') = 'a8100000-0000-4000-8000-000000000903',
  'User A reconciliation returns only User A immutable snapshot'
);
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000002',
  true
);
select pg_temp.assert_true(
  (public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  )->'note'->>'id') = 'a8100000-0000-4000-8000-000000000901',
  'User B reconciliation still returns only User B immutable snapshot'
);
reset role;

set local role anon;
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000906',
    'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
    'anonymous must fail at the ACL boundary', null,
    'a8100000-0000-4000-8000-000000000906'
  )$$,
  '42501', 'anon mutation RPC is denied at the function permission boundary'
);
select pg_temp.assert_raises(
  $$select public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  )$$,
  '42501', 'anon reconciliation RPC is denied at the function permission boundary'
);
reset role;

set local role service_role;
select pg_temp.assert_raises(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000907',
    'a8100000-0000-4000-8000-000000000021', null, 'pinned_routine',
    'service role must fail at the ACL boundary', null,
    'a8100000-0000-4000-8000-000000000907'
  )$$,
  '42501', 'service_role mutation RPC is denied at the function permission boundary'
);
select pg_temp.assert_raises(
  $$select public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  )$$,
  '42501', 'service_role reconciliation RPC is denied at the function permission boundary'
);
reset role;

-- The same mutation UUID is independently owned by A and B. Keep B's receipt
-- just inside retention, expire A's exactly at the transaction boundary, and
-- prove repeated reconciliation/retry cannot recreate the mutation.
update private.user_workout_routine_note_mutations
set created_at = transaction_timestamp() - interval '30 days' + interval '1 second'
where user_id = 'a8100000-0000-4000-8000-000000000002'
  and mutation_id = 'a8100000-0000-4000-8000-000000000902';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000002',
  true
);
select pg_temp.assert_true(
  public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  )->>'status' = 'applied'
  and public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  )->'note'->>'body' = 'User B original result',
  'receipt remains fully reconcilable one second before the 30-day boundary'
);
reset role;

insert into routine_note_test_results (mutation_id, result)
select 'a8100000-0000-4000-8000-000000000996',
       pg_catalog.jsonb_build_object('request_hash', request_hash)
from private.user_workout_routine_note_mutations
where user_id = 'a8100000-0000-4000-8000-000000000001'
  and mutation_id = 'a8100000-0000-4000-8000-000000000902';
update private.user_workout_routine_note_mutations
set created_at = transaction_timestamp() - interval '30 days'
where user_id = 'a8100000-0000-4000-8000-000000000001'
  and mutation_id = 'a8100000-0000-4000-8000-000000000902';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000001',
  true
);
insert into routine_note_test_results (mutation_id, result)
values (
  'a8100000-0000-4000-8000-000000000997',
  public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  )
);
select pg_temp.assert_jsonb_equal(
  '{"status":"expired","mutation_id":"a8100000-0000-4000-8000-000000000902","operation":"create","result_kind":"applied","note_id":"a8100000-0000-4000-8000-000000000903","revision":0}'::jsonb,
  (select result - 'created_at'
   from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000997'),
  'receipt expires exactly at 30 days with an explicit body-free tombstone'
);
insert into routine_note_test_results (mutation_id, result)
values (
  'a8100000-0000-4000-8000-000000000998',
  public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  )
);
select pg_temp.assert_jsonb_equal(
  (select result from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000997'),
  (select result from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000998'),
  'repeated reconciliation returns the same durable expired tombstone'
);
reset role;
select pg_temp.assert_jsonb_equal(
  (select result from routine_note_test_results
   where mutation_id = 'a8100000-0000-4000-8000-000000000997'),
  (select result_snapshot
   from private.user_workout_routine_note_mutations
   where user_id = 'a8100000-0000-4000-8000-000000000001'
     and mutation_id = 'a8100000-0000-4000-8000-000000000902'),
  'reconciled result equals the owner-private durable tombstone'
);
select pg_temp.assert_true(
  (select request_hash ~ '^[0-9a-f]{64}$'
          and request_hash = (select result->>'request_hash'
                              from routine_note_test_results
                              where mutation_id = 'a8100000-0000-4000-8000-000000000996')
          and mutation_id = 'a8100000-0000-4000-8000-000000000902'
          and result_snapshot->>'status' = 'expired'
          and result_snapshot->'note' is null
   from private.user_workout_routine_note_mutations
   where user_id = 'a8100000-0000-4000-8000-000000000001'
     and mutation_id = 'a8100000-0000-4000-8000-000000000902'),
  'expiry redacts snapshot body while preserving request hash and mutation tombstone'
);
set local role authenticated;
select pg_temp.assert_jsonb_equal(
  '{"status":"expired","mutation_id":"a8100000-0000-4000-8000-000000000902","operation":"create","result_kind":"applied","note_id":"a8100000-0000-4000-8000-000000000903","revision":0}'::jsonb,
  (public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000903',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    'User A independent result', null,
    'a8100000-0000-4000-8000-000000000902'
  ) - 'created_at'),
  'same-hash duplicate retry returns expired and does not re-execute'
);
select pg_temp.assert_raises_exact(
  $$select public.mutate_user_workout_routine_note(
    'create', 'a8100000-0000-4000-8000-000000000904',
    'a8100000-0000-4000-8000-000000000025', null, 'pinned_routine',
    'different request after expiry', null,
    'a8100000-0000-4000-8000-000000000902'
  )$$,
  'P0001', 'routine_note_mutation_conflict',
  'expired mutation ID cannot execute a different request as a new mutation'
);
reset role;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a8100000-0000-4000-8000-000000000002',
  true
);
select pg_temp.assert_true(
  (public.reconcile_user_workout_routine_note_mutation(
    'a8100000-0000-4000-8000-000000000902'
  )->'note'->>'body') = 'User B original result',
  'same mutation UUID retains User B receipt and snapshot independently'
);
reset role;

rollback;
