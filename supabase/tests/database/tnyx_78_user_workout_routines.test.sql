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
   where version = '20260929050000'),
  'Routine persistence migration must be present exactly once'
);

select pg_temp.assert_true(
  to_regclass('public.user_workout_routines') is not null,
  'public.user_workout_routines must exist'
);

select pg_temp.assert_true(
  (select relrowsecurity
   from pg_class
   where oid = 'public.user_workout_routines'::regclass),
  'user_workout_routines must have RLS enabled'
);

select pg_temp.assert_true(
  has_table_privilege('authenticated', 'public.user_workout_routines', 'SELECT')
  and has_table_privilege('authenticated', 'public.user_workout_routines', 'INSERT'),
  'authenticated must have Routine SELECT and INSERT'
);

select pg_temp.assert_true(
  not has_table_privilege('authenticated', 'public.user_workout_routines', 'DELETE'),
  'authenticated must not have Routine DELETE'
);

select pg_temp.assert_true(
  has_column_privilege(
    'authenticated',
    'public.user_workout_routines',
    'name',
    'UPDATE'
  ),
  'authenticated must be able to update Routine name'
);

select pg_temp.assert_true(
  not has_column_privilege(
    'authenticated',
    'public.user_workout_routines',
    'program_id',
    'UPDATE'
  )
  and not has_column_privilege(
    'authenticated',
    'public.user_workout_routines',
    'user_id',
    'UPDATE'
  ),
  'authenticated must not move a Routine or change its owner'
);

insert into auth.users (id, email)
values
  ('a3010000-0000-4000-8000-000000001001', 'routine-owner-a@example.test'),
  ('a3010000-0000-4000-8000-000000001002', 'routine-owner-b@example.test');

insert into public.user_workout_programs (id, user_id, name)
values
  (
    'a3010000-0000-4000-8000-000000002001',
    'a3010000-0000-4000-8000-000000001001',
    'Program A'
  ),
  (
    'a3010000-0000-4000-8000-000000002002',
    'a3010000-0000-4000-8000-000000001002',
    'Program B'
  );

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a3010000-0000-4000-8000-000000001001',
  true
);

insert into public.user_workout_routines (id, user_id, program_id, name)
values (
  'a3010000-0000-4000-8000-000000003001',
  'a3010000-0000-4000-8000-000000001001',
  'a3010000-0000-4000-8000-000000002001',
  'Routine A'
);

select pg_temp.assert_raises(
  $$insert into public.user_workout_routines (id, user_id, program_id, name)
    values (
      'a3010000-0000-4000-8000-000000003002',
      'a3010000-0000-4000-8000-000000001001',
      'a3010000-0000-4000-8000-000000002002',
      'Cross-owner Routine'
    )$$,
  '23503',
  'composite FK must reject attaching an owned Routine to another user Program'
);

select pg_temp.assert_true(
  (select count(*) = 1 from public.user_workout_routines),
  'owner RLS must expose only the authenticated user Routine rows'
);

update public.user_workout_routines
set name = 'Renamed Routine A'
where id = 'a3010000-0000-4000-8000-000000003001';

select pg_temp.assert_true(
  (select name = 'Renamed Routine A'
   from public.user_workout_routines
   where id = 'a3010000-0000-4000-8000-000000003001'),
  'authenticated owner must be able to rename their Routine'
);

select pg_temp.assert_raises(
  $$update public.user_workout_routines
    set program_id = 'a3010000-0000-4000-8000-000000002001'
    where id = 'a3010000-0000-4000-8000-000000003001'$$,
  '42501',
  'authenticated must not update Routine program_id directly'
);

select pg_temp.assert_raises(
  $$delete from public.user_workout_routines
    where id = 'a3010000-0000-4000-8000-000000003001'$$,
  '42501',
  'authenticated must not delete Routine rows before lifecycle semantics are locked'
);

reset role;

insert into public.user_workout_routines (id, user_id, program_id, name)
values (
  'a3010000-0000-4000-8000-000000003003',
  'a3010000-0000-4000-8000-000000001002',
  'a3010000-0000-4000-8000-000000002002',
  'Routine B'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a3010000-0000-4000-8000-000000001001',
  true
);

update public.user_workout_routines
set name = 'Should not change'
where id = 'a3010000-0000-4000-8000-000000003003';

reset role;

select pg_temp.assert_true(
  (select name = 'Routine B'
   from public.user_workout_routines
   where id = 'a3010000-0000-4000-8000-000000003003'),
  'owner RLS must prevent renaming another user Routine'
);

rollback;
