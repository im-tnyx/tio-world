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
   where version = '20260929133232'),
  'Program privilege hardening migration must be present exactly once'
);

select pg_temp.assert_true(
  has_table_privilege(
    'authenticated',
    'public.user_workout_programs',
    'SELECT'
  )
  and has_table_privilege(
    'authenticated',
    'public.user_workout_programs',
    'INSERT'
  ),
  'authenticated must retain Program SELECT and INSERT'
);

select pg_temp.assert_true(
  not has_table_privilege(
    'authenticated',
    'public.user_workout_programs',
    'UPDATE'
  ),
  'authenticated must not retain table-wide Program UPDATE'
);

select pg_temp.assert_true(
  not has_table_privilege(
    'authenticated',
    'public.user_workout_programs',
    'DELETE'
  ),
  'authenticated must not have Program DELETE'
);

select pg_temp.assert_true(
  has_column_privilege(
    'authenticated',
    'public.user_workout_programs',
    'name',
    'UPDATE'
  ),
  'authenticated must be able to update Program name'
);

select pg_temp.assert_true(
  not has_column_privilege(
    'authenticated',
    'public.user_workout_programs',
    'id',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_programs',
    'user_id',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_programs',
    'created_at',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_programs',
    'updated_at',
    'UPDATE'
  ),
  'authenticated must not update Program identity, owner, or timestamps'
);

select pg_temp.assert_true(
  not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_workout_programs'
      and policyname = 'user_workout_programs_delete_own'
  ),
  'Program DELETE policy must be removed while lifecycle semantics are deferred'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'user_workout_programs'
      and policyname = 'user_workout_programs_update_own'
      and cmd = 'UPDATE'
  ),
  'Program owner UPDATE policy must remain for rename'
);

insert into auth.users (id, email)
values
  ('a3020000-0000-4000-8000-000000001001', 'program-owner-a@example.test'),
  ('a3020000-0000-4000-8000-000000001002', 'program-owner-b@example.test');

insert into public.user_workout_programs (id, user_id, name)
values
  (
    'a3020000-0000-4000-8000-000000002001',
    'a3020000-0000-4000-8000-000000001001',
    'Program A'
  ),
  (
    'a3020000-0000-4000-8000-000000002002',
    'a3020000-0000-4000-8000-000000001002',
    'Program B'
  );

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a3020000-0000-4000-8000-000000001001',
  true
);

select pg_temp.assert_true(
  (select count(*) = 1 from public.user_workout_programs),
  'owner RLS must expose only the authenticated user Program rows'
);

update public.user_workout_programs
set name = 'Renamed Program A'
where id = 'a3020000-0000-4000-8000-000000002001';

select pg_temp.assert_true(
  (select name = 'Renamed Program A'
   from public.user_workout_programs
   where id = 'a3020000-0000-4000-8000-000000002001'),
  'authenticated owner must be able to rename their Program'
);

select pg_temp.assert_raises(
  $$update public.user_workout_programs
    set id = 'a3020000-0000-4000-8000-000000009001'
    where id = 'a3020000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not update Program id'
);

select pg_temp.assert_raises(
  $$update public.user_workout_programs
    set user_id = 'a3020000-0000-4000-8000-000000001002'
    where id = 'a3020000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not update Program user_id'
);

select pg_temp.assert_raises(
  $$update public.user_workout_programs
    set created_at = timezone('utc'::text, now())
    where id = 'a3020000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not update Program created_at'
);

select pg_temp.assert_raises(
  $$update public.user_workout_programs
    set updated_at = timezone('utc'::text, now())
    where id = 'a3020000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not update Program updated_at'
);

select pg_temp.assert_raises(
  $$delete from public.user_workout_programs
    where id = 'a3020000-0000-4000-8000-000000002001'$$,
  '42501',
  'authenticated must not delete Program rows before lifecycle semantics are locked'
);

update public.user_workout_programs
set name = 'Should not change'
where id = 'a3020000-0000-4000-8000-000000002002';

reset role;

select pg_temp.assert_true(
  (select name = 'Program B'
   from public.user_workout_programs
   where id = 'a3020000-0000-4000-8000-000000002002'),
  'owner RLS must prevent renaming another user Program'
);

rollback;
