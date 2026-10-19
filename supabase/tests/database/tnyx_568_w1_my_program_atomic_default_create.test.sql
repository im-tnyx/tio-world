\set ON_ERROR_STOP on

-- #568 / TNYX-78 W1: My Program Identity and Atomic First Routine Create.
-- DISPOSABLE CI ONLY. Transaction rolls back all test fixtures and temporary grants.
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

-- 1. Migration ledger verification
select pg_temp.assert_true(
  (select count(*) = 1
   from supabase_migrations.schema_migrations
   where version = '20261019162535'),
  'W1 atomic default migration must be recorded exactly once'
);

-- 2. Schema and partial unique index assertions
select pg_temp.assert_true(
  exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_workout_programs'
      and column_name = 'is_default'
      and data_type = 'boolean'
      and is_nullable = 'NO'
      and column_default = 'false'
  ),
  'user_workout_programs must have column is_default boolean NOT NULL DEFAULT false'
);

select pg_temp.assert_true(
  exists (
    select 1
    from pg_indexes
    where schemaname = 'public'
      and tablename = 'user_workout_programs'
      and indexname = 'idx_user_workout_programs_owner_default'
      and indexdef like '%UNIQUE INDEX%user_id%WHERE is_default%'
  ),
  'partial unique index on (user_id) WHERE is_default must exist'
);

-- 3. Privilege narrowing assertions
select pg_temp.assert_true(
  has_table_privilege('authenticated', 'public.user_workout_programs', 'SELECT')
  and not has_table_privilege('authenticated', 'public.user_workout_programs', 'INSERT')
  and has_column_privilege('authenticated', 'public.user_workout_programs', 'id', 'INSERT')
  and has_column_privilege('authenticated', 'public.user_workout_programs', 'user_id', 'INSERT')
  and has_column_privilege('authenticated', 'public.user_workout_programs', 'name', 'INSERT')
  and not has_column_privilege('authenticated', 'public.user_workout_programs', 'is_default', 'INSERT')
  and not has_column_privilege('authenticated', 'public.user_workout_programs', 'created_at', 'INSERT')
  and not has_column_privilege('authenticated', 'public.user_workout_programs', 'updated_at', 'INSERT'),
  'authenticated must have SELECT and only id, user_id, name INSERT on user_workout_programs'
);

select pg_temp.assert_true(
  not has_table_privilege('authenticated', 'public.user_workout_programs', 'UPDATE')
  and has_column_privilege('authenticated', 'public.user_workout_programs', 'name', 'UPDATE')
  and not has_column_privilege('authenticated', 'public.user_workout_programs', 'is_default', 'UPDATE')
  and not has_column_privilege('authenticated', 'public.user_workout_programs', 'id', 'UPDATE')
  and not has_column_privilege('authenticated', 'public.user_workout_programs', 'user_id', 'UPDATE'),
  'authenticated must retain only name UPDATE and cannot mutate is_default'
);

select pg_temp.assert_true(
  not has_table_privilege('authenticated', 'public.user_workout_programs', 'DELETE'),
  'authenticated must not have DELETE on user_workout_programs'
);

-- 4. RPC must start dormant (no EXECUTE for anyone)
select pg_temp.assert_true(
  not has_function_privilege('authenticated',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE')
  and not has_function_privilege('anon',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE')
  and not has_function_privilege('service_role',
    'public.create_user_workout_routine_in_my_program(uuid,text,uuid,jsonb)', 'EXECUTE'),
  'create_user_workout_routine_in_my_program must be dormant with no EXECUTE'
);

-- 5. Test fixture users
insert into auth.users (id, email)
values
  ('c5680000-0000-4000-8000-000000000001', 'w1-owner-a@example.test'),
  ('c5680000-0000-4000-8000-000000000002', 'w1-owner-b@example.test');

-- 6. Direct malicious client attempts under authenticated role
set local role authenticated;
select set_config('request.jwt.claim.sub', 'c5680000-0000-4000-8000-000000000001', true);

select pg_temp.assert_raises(
  $$insert into public.user_workout_programs (id, user_id, name, is_default)
    values (
      'c5680000-0000-4000-8000-000000001001',
      'c5680000-0000-4000-8000-000000000001',
      'Spoofed Default Program',
      true
    )$$,
  '42501',
  'authenticated client cannot insert is_default directly'
);

select pg_temp.assert_raises(
  $$insert into public.user_workout_programs (id, user_id, name, created_at)
    values (
      'c5680000-0000-4000-8000-000000001002',
      'c5680000-0000-4000-8000-000000000001',
      'Spoofed Timestamp Program',
      now()
    )$$,
  '42501',
  'authenticated client cannot insert created_at directly'
);

-- 7. Legacy client compatibility under authenticated role
-- Legacy client inserts only (id, user_id, name)
insert into public.user_workout_programs (id, user_id, name)
values (
  'c5680000-0000-4000-8000-000000001010',
  'c5680000-0000-4000-8000-000000000001',
  'Legacy Program 1'
);

select pg_temp.assert_true(
  (select is_default = false and created_at is not null and updated_at is not null
   from public.user_workout_programs
   where id = 'c5680000-0000-4000-8000-000000001010'),
  'legacy insert must default is_default to false and auto-populate timestamps'
);

-- Direct client rename works
update public.user_workout_programs
set name = 'Renamed Legacy Program'
where id = 'c5680000-0000-4000-8000-000000001010';

select pg_temp.assert_true(
  (select name = 'Renamed Legacy Program'
   from public.user_workout_programs
   where id = 'c5680000-0000-4000-8000-000000001010'),
  'legacy client can update name'
);

-- Direct client cannot update is_default on existing row
select pg_temp.assert_raises(
  $$update public.user_workout_programs
    set is_default = true
    where id = 'c5680000-0000-4000-8000-000000001010'$$,
  '42501',
  'authenticated client cannot update is_default on existing row'
);

-- User can create multiple non-default programs, even named 'My Program'
insert into public.user_workout_programs (id, user_id, name)
values (
  'c5680000-0000-4000-8000-000000001011',
  'c5680000-0000-4000-8000-000000000001',
  'My Program'
);

select pg_temp.assert_true(
  (select count(*) = 2 and count(*) filter (where is_default) = 0
   from public.user_workout_programs
   where user_id = 'c5680000-0000-4000-8000-000000000001'),
  'user can have multiple non-default programs, including one named My Program'
);

reset role;

-- 8. Partial unique index enforcement (server-side direct insert)
insert into public.user_workout_programs (id, user_id, name, is_default)
values (
  'c5680000-0000-4000-8000-000000001020',
  'c5680000-0000-4000-8000-000000000001',
  'Canonical Default',
  true
);

-- Attempting a second default for same user must violate partial unique index
select pg_temp.assert_raises(
  $$insert into public.user_workout_programs (id, user_id, name, is_default)
    values (
      'c5680000-0000-4000-8000-000000001021',
      'c5680000-0000-4000-8000-000000000001',
      'Second Default Attempt',
      true
    )$$,
  '23505',
  'partial unique index must reject second is_default = true for same user'
);

-- Another user can have their own default program
insert into public.user_workout_programs (id, user_id, name, is_default)
values (
  'c5680000-0000-4000-8000-000000001022',
  'c5680000-0000-4000-8000-000000000002',
  'User B Default',
  true
);

select pg_temp.assert_true(
  (select count(*) = 2
   from public.user_workout_programs
   where is_default = true),
  'different users can each have one default program'
);

-- Clean up manual defaults for RPC testing
delete from public.user_workout_programs
where id in ('c5680000-0000-4000-8000-000000001020', 'c5680000-0000-4000-8000-000000001022');

-- 9. Server-authoritative RPC testing with test-local grant
grant execute on function public.create_user_workout_routine_in_my_program(uuid, text, uuid, jsonb)
to authenticated;

-- Test-fixture user C with NO programs initially
insert into auth.users (id, email)
values ('c5680000-0000-4000-8000-000000000003', 'w1-owner-c@example.test');

-- Canonical test exercise payload with 1 set
create function pg_temp.valid_exercises()
returns jsonb language sql as $$
  select '[{"exercise_ref": "bench_press", "exercise_type": "standard", "sets": [{"position": 0, "reps": 10, "set_type": "regular"}]}]'::jsonb;
$$;

-- 9a. Input validation
set local role authenticated;
select set_config('request.jwt.claim.sub', 'c5680000-0000-4000-8000-000000000003', true);

select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      null, 'Routine 1', 'c5680000-0000-4000-8000-000000000101', pg_temp.valid_exercises()
    )$$,
  '22023',
  'RPC rejects null routine_id'
);

select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      'c5680000-0000-4000-8000-000000000201', '   ', 'c5680000-0000-4000-8000-000000000101', pg_temp.valid_exercises()
    )$$,
  '22023',
  'RPC rejects blank routine name'
);

select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      'c5680000-0000-4000-8000-000000000201', 'Routine 1', null, pg_temp.valid_exercises()
    )$$,
  '22023',
  'RPC rejects null client_mutation_id'
);

select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      'c5680000-0000-4000-8000-000000000201', 'Routine 1', 'c5680000-0000-4000-8000-000000000101', '[]'::jsonb
    )$$,
  '22023',
  'RPC rejects empty exercises array'
);

select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      'c5680000-0000-4000-8000-000000000201', 'Routine 1', 'c5680000-0000-4000-8000-000000000101',
      '[{"exercise_ref": "bench_press", "exercise_type": "standard", "sets": []}]'::jsonb
    )$$,
  '22023',
  'RPC rejects exercise with empty sets'
);

-- 9b. Failed composition rolls back transaction completely leaving NO default program
-- Call in a subtransaction (savepoint) to verify rollback
savepoint sp_fail_test;

select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      'c5680000-0000-4000-8000-000000000201', 'Routine 1', 'c5680000-0000-4000-8000-000000000101',
      '[{"exercise_ref": "00000000-0000-0000-0000-000000000000", "exercise_type": "standard", "sets": [{"position": 0, "reps": 10}]}]'::jsonb
    )$$,
  'P0002',
  'RPC fails when custom exercise reference does not exist'
);

rollback to savepoint sp_fail_test;

-- Verify NO program was left behind after the failure
select pg_temp.assert_true(
  (select count(*) = 0
   from public.user_workout_programs
   where user_id = 'c5680000-0000-4000-8000-000000000003'),
  'failed composition must leave zero programs for the user'
);

-- 9c. Successful first-time Create: lazily establishes default My Program + creates Routine
select pg_temp.assert_true(
  (
    select (res ->> 'program_id') is not null
       and (res ->> 'composition_revision')::bigint = 1
    from (
      select public.create_user_workout_routine_in_my_program(
        'c5680000-0000-4000-8000-000000000201',
        'Morning Routine',
        'c5680000-0000-4000-8000-000000000101',
        pg_temp.valid_exercises()
      ) as res
    ) sub
  ),
  'successful RPC returns valid program_id and composition_revision = 1'
);

-- Verify DB state: exactly 1 program, named "My Program", is_default = true
select pg_temp.assert_true(
  (select count(*) = 1 and count(*) filter (where is_default and name = 'My Program') = 1
   from public.user_workout_programs
   where user_id = 'c5680000-0000-4000-8000-000000000003'),
  'exactly one default My Program must exist for user C'
);

-- Verify routine state
select pg_temp.assert_true(
  (select routine.name = 'Morning Routine'
      and routine.composition_revision = 1
      and routine.last_composition_mutation_id = 'c5680000-0000-4000-8000-000000000101'::uuid
      and program.is_default = true
   from public.user_workout_routines as routine
   join public.user_workout_programs as program on routine.program_id = program.id
   where routine.id = 'c5680000-0000-4000-8000-000000000201'),
  'routine must be attached to the default program with revision 1'
);

-- 9d. Idempotent retry: identical payload and mutation ID returns same result
select pg_temp.assert_true(
  (
    select (res ->> 'composition_revision')::bigint = 1
    from (
      select public.create_user_workout_routine_in_my_program(
        'c5680000-0000-4000-8000-000000000201',
        'Morning Routine',
        'c5680000-0000-4000-8000-000000000101',
        pg_temp.valid_exercises()
      ) as res
    ) sub
  ),
  'identical retry returns revision 1 idempotently'
);

-- 9e. Altered payload retry with same routine_id must fail closed
select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      'c5680000-0000-4000-8000-000000000201',
      'Altered Morning Routine',
      'c5680000-0000-4000-8000-000000000102',
      pg_temp.valid_exercises()
    )$$,
  'P0001',
  'altered payload with same routine_id raises identity conflict'
);

-- 9f. Second routine creation reuses the existing default Program (does not create second program)
select pg_temp.assert_true(
  (
    select (res ->> 'composition_revision')::bigint = 1
    from (
      select public.create_user_workout_routine_in_my_program(
        'c5680000-0000-4000-8000-000000000202',
        'Evening Routine',
        'c5680000-0000-4000-8000-000000000103',
        pg_temp.valid_exercises()
      ) as res
    ) sub
  ),
  'second routine create succeeds'
);

select pg_temp.assert_true(
  (select count(*) = 1 from public.user_workout_programs where user_id = 'c5680000-0000-4000-8000-000000000003')
  and (select count(*) = 2 from public.user_workout_routines where user_id = 'c5680000-0000-4000-8000-000000000003'),
  'user C still has exactly 1 program and now 2 routines under it'
);

-- 9g. Renamed default Program is still recognized as default (not name-dependent)
update public.user_workout_programs
set name = 'My Custom Workout Split'
where user_id = 'c5680000-0000-4000-8000-000000000003' and is_default = true;

select pg_temp.assert_true(
  (
    select (res ->> 'composition_revision')::bigint = 1
    from (
      select public.create_user_workout_routine_in_my_program(
        'c5680000-0000-4000-8000-000000000203',
        'Weekend Routine',
        'c5680000-0000-4000-8000-000000000104',
        pg_temp.valid_exercises()
      ) as res
    ) sub
  ),
  'third routine reuses renamed default program without creating another default'
);

select pg_temp.assert_true(
  (select count(*) = 1 from public.user_workout_programs where user_id = 'c5680000-0000-4000-8000-000000000003')
  and (select count(*) = 3 from public.user_workout_routines where user_id = 'c5680000-0000-4000-8000-000000000003'),
  'renamed default program correctly hosts the 3rd routine'
);

-- 9h. User with existing non-default program named "My Program"
-- User A has a program named "My Program" with is_default = false
select set_config('request.jwt.claim.sub', 'c5680000-0000-4000-8000-000000000001', true);

select pg_temp.assert_true(
  (
    select (res ->> 'program_id') is distinct from 'c5680000-0000-4000-8000-000000001011'::text
    from (
      select public.create_user_workout_routine_in_my_program(
        'c5680000-0000-4000-8000-000000000204',
        'User A Direct Routine',
        'c5680000-0000-4000-8000-000000000105',
        pg_temp.valid_exercises()
      ) as res
    ) sub
  ),
  'RPC does not adopt an existing non-default program named My Program'
);

select pg_temp.assert_true(
  (select count(*) = 1 from public.user_workout_programs
   where user_id = 'c5680000-0000-4000-8000-000000000001' and is_default = true),
  'user A now has exactly one is_default=true program distinct from legacy programs'
);

-- 9i. Cross-owner RLS and routine isolation
select set_config('request.jwt.claim.sub', 'c5680000-0000-4000-8000-000000000002', true);

select pg_temp.assert_true(
  (select count(*) = 0 from public.user_workout_programs),
  'user B sees zero of user A or user C programs under RLS'
);

-- User B calling with User C routine_id fails
select pg_temp.assert_raises(
  $$select public.create_user_workout_routine_in_my_program(
      'c5680000-0000-4000-8000-000000000201',
      'User B Hijack Attempt',
      'c5680000-0000-4000-8000-000000000106',
      pg_temp.valid_exercises()
    )$$,
  'P0002',
  'user B cannot reuse another user routine_id'
);

reset role;

-- 10. Account deletion cascades cleanly
delete from auth.users where id = 'c5680000-0000-4000-8000-000000000003';

select pg_temp.assert_true(
  (select count(*) = 0 from public.user_workout_programs where user_id = 'c5680000-0000-4000-8000-000000000003')
  and (select count(*) = 0 from public.user_workout_routines where user_id = 'c5680000-0000-4000-8000-000000000003'),
  'deleting user account cascades and removes default program and routines'
);

rollback;
