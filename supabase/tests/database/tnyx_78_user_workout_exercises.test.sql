\set ON_ERROR_STOP on

begin;

create function pg_temp.assert_true(p_condition boolean, p_message text)
returns void language plpgsql as $$
begin
  if p_condition is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

create function pg_temp.assert_raises(
  p_sql text,
  p_expected_sqlstate text,
  p_message text
)
returns void language plpgsql as $$
declare
  v_sqlstate text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_sqlstate = returned_sqlstate;
    if v_sqlstate = p_expected_sqlstate then
      return;
    end if;
    raise exception
      'assertion failed: % (expected SQLSTATE %, got %)',
      p_message,
      p_expected_sqlstate,
      v_sqlstate;
  end;

  raise exception 'assertion failed: % (statement unexpectedly succeeded)', p_message;
end;
$$;

select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20260929181247'),
  'User Exercise persistence migration must be present exactly once'
);

select pg_temp.assert_true(
  to_regclass('public.user_workout_exercises') is not null,
  'public.user_workout_exercises must exist'
);

select pg_temp.assert_true(
  (select relrowsecurity
   from pg_class
   where oid = 'public.user_workout_exercises'::regclass),
  'user_workout_exercises must have RLS enabled'
);

select pg_temp.assert_true(
  has_table_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'SELECT'
  ),
  'authenticated must have user Exercise SELECT'
);

select pg_temp.assert_true(
  not has_table_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'UPDATE'
  )
  and not has_table_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'DELETE'
  ),
  'authenticated must not have table-wide UPDATE or DELETE'
);

select pg_temp.assert_true(
  has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'id',
    'INSERT'
  )
  and has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'user_id',
    'INSERT'
  )
  and has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'display_name',
    'INSERT'
  )
  and has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'based_on_catalog_exercise_id',
    'INSERT'
  ),
  'authenticated must insert only the client-owned create columns'
);

select pg_temp.assert_true(
  not has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'status',
    'INSERT'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'created_at',
    'INSERT'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'updated_at',
    'INSERT'
  ),
  'authenticated must not insert lifecycle or server-owned timestamp columns'
);

select pg_temp.assert_true(
  has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'display_name',
    'UPDATE'
  )
  and has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'status',
    'UPDATE'
  ),
  'authenticated must be able to rename and archive user Exercises'
);

select pg_temp.assert_true(
  not has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'id',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'user_id',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'based_on_catalog_exercise_id',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'created_at',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_exercises',
    'updated_at',
    'UPDATE'
  ),
  'authenticated must not rewrite Exercise identity, owner, lineage or timestamps'
);

select pg_temp.assert_true(
  not has_table_privilege(
    'anon',
    'public.user_workout_exercises',
    'SELECT'
  )
  and not has_table_privilege(
    'anon',
    'public.user_workout_exercises',
    'INSERT'
  )
  and not has_table_privilege(
    'anon',
    'public.user_workout_exercises',
    'UPDATE'
  )
  and not has_table_privilege(
    'anon',
    'public.user_workout_exercises',
    'DELETE'
  ),
  'anon must have no user Exercise privileges'
);

select pg_temp.assert_true(
  has_table_privilege(
    'service_role',
    'public.user_workout_exercises',
    'SELECT'
  )
  and has_table_privilege(
    'service_role',
    'public.user_workout_exercises',
    'INSERT'
  )
  and has_table_privilege(
    'service_role',
    'public.user_workout_exercises',
    'UPDATE'
  )
  and has_table_privilege(
    'service_role',
    'public.user_workout_exercises',
    'DELETE'
  ),
  'service_role must retain full user Exercise CRUD'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_constraint
    where conrelid = 'public.user_workout_exercises'::regclass
      and conname = 'user_workout_exercises_id_user_id_key'
      and contype = 'u'
  ),
  'user Exercise owner-safe composite key must exist'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_workout_exercises'
      and policyname = 'user_workout_exercises_select_own'
      and cmd = 'SELECT'
  )
  and exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_workout_exercises'
      and policyname = 'user_workout_exercises_insert_own'
      and cmd = 'INSERT'
  )
  and exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_workout_exercises'
      and policyname = 'user_workout_exercises_update_own'
      and cmd = 'UPDATE'
  )
  and not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_workout_exercises'
      and cmd = 'DELETE'
  ),
  'user Exercise policies must allow owner SELECT/INSERT/UPDATE and no DELETE'
);

insert into auth.users (id, email)
values
  ('a3030000-0000-4000-8000-000000001001', 'exercise-owner-a@example.test'),
  ('a3030000-0000-4000-8000-000000001002', 'exercise-owner-b@example.test');

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a3030000-0000-4000-8000-000000001001',
  true
);

insert into public.user_workout_exercises (
  id,
  user_id,
  display_name,
  based_on_catalog_exercise_id
)
values (
  'a3030000-0000-4000-8000-000000002001',
  'a3030000-0000-4000-8000-000000001001',
  'Paused Bench Press',
  'ex_barbell_bench_press'
);

select pg_temp.assert_true(
  (select status = 'active'
   from public.user_workout_exercises
   where id = 'a3030000-0000-4000-8000-000000002001'),
  'new user Exercises must default to active'
);

select pg_temp.assert_true(
  (select based_on_catalog_exercise_id = 'ex_barbell_bench_press'
   from public.user_workout_exercises
   where id = 'a3030000-0000-4000-8000-000000002001'),
  'valid catalog fork lineage must persist'
);

select pg_temp.assert_raises(
  $$insert into public.user_workout_exercises (
      id,
      user_id,
      display_name
    )
    values (
      'a3030000-0000-4000-8000-000000002002',
      'a3030000-0000-4000-8000-000000001002',
      'Cross-owner Exercise'
    )$$,
  '42501',
  'owner RLS must reject creating a user Exercise for another user'
);

select pg_temp.assert_raises(
  $$insert into public.user_workout_exercises (
      id,
      user_id,
      display_name
    )
    values (
      'a3030000-0000-4000-8000-000000002003',
      'a3030000-0000-4000-8000-000000001001',
      '   '
    )$$,
  '23514',
  'blank user Exercise names must be rejected'
);

select pg_temp.assert_raises(
  $$insert into public.user_workout_exercises (
      id,
      user_id,
      display_name,
      based_on_catalog_exercise_id
    )
    values (
      'a3030000-0000-4000-8000-000000002004',
      'a3030000-0000-4000-8000-000000001001',
      'Invalid Lineage',
      'not_catalog_id'
    )$$,
  '23514',
  'invalid bundled catalog lineage must be rejected'
);

select pg_temp.assert_raises(
  $$insert into public.user_workout_exercises (
      id,
      user_id,
      display_name,
      status
    )
    values (
      'a3030000-0000-4000-8000-000000002005',
      'a3030000-0000-4000-8000-000000001001',
      'Client Chosen Status',
      'archived'
    )$$,
  '42501',
  'authenticated clients must not choose lifecycle status on create'
);

update public.user_workout_exercises
set display_name = 'Renamed Paused Bench'
where id = 'a3030000-0000-4000-8000-000000002001';

update public.user_workout_exercises
set status = 'archived'
where id = 'a3030000-0000-4000-8000-000000002001';

select pg_temp.assert_true(
  (select display_name = 'Renamed Paused Bench' and status = 'archived'
   from public.user_workout_exercises
   where id = 'a3030000-0000-4000-8000-000000002001'),
  'authenticated owner must be able to rename and archive their user Exercise'
);

select pg_temp.assert_raises(
  $$update public.user_workout_exercises
    set status = 'deleted'
    where id = 'a3030000-0000-4000-8000-000000002001'$$,
  '23514',
  'invalid user Exercise lifecycle status must be rejected'
);

select pg_temp.assert_raises(
  $$update public.user_workout_exercises
    set id = 'a3030000-0000-4000-8000-000000009001'
    where id = 'a3030000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not update user Exercise id'
);

select pg_temp.assert_raises(
  $$update public.user_workout_exercises
    set user_id = 'a3030000-0000-4000-8000-000000001002'
    where id = 'a3030000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not update user Exercise owner'
);

select pg_temp.assert_raises(
  $$update public.user_workout_exercises
    set based_on_catalog_exercise_id = 'ex_squat'
    where id = 'a3030000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not rewrite immutable catalog lineage'
);

select pg_temp.assert_raises(
  $$update public.user_workout_exercises
    set created_at = timezone('utc'::text, now())
    where id = 'a3030000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not update created_at'
);

select pg_temp.assert_raises(
  $$update public.user_workout_exercises
    set updated_at = timezone('utc'::text, now())
    where id = 'a3030000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not update updated_at directly'
);

select pg_temp.assert_raises(
  $$delete from public.user_workout_exercises
    where id = 'a3030000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must archive rather than hard-delete user Exercises'
);

reset role;

insert into public.user_workout_exercises (
  id,
  user_id,
  display_name
)
values (
  'a3030000-0000-4000-8000-000000003001',
  'a3030000-0000-4000-8000-000000001002',
  'Owner B Exercise'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a3030000-0000-4000-8000-000000001001',
  true
);

select pg_temp.assert_true(
  (select count(*) = 1 from public.user_workout_exercises),
  'owner RLS must expose only the authenticated user Exercise rows'
);

update public.user_workout_exercises
set display_name = 'Should not change'
where id = 'a3030000-0000-4000-8000-000000003001';

reset role;

select pg_temp.assert_true(
  (select display_name = 'Owner B Exercise'
   from public.user_workout_exercises
   where id = 'a3030000-0000-4000-8000-000000003001'),
  'owner RLS must prevent renaming another user Exercise'
);

rollback;
