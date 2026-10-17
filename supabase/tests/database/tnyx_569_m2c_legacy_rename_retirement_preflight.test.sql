\set ON_ERROR_STOP on
-- #569 / TNYX-81 M2C: simulate legacy direct Rename retirement.
-- DISPOSABLE CI ONLY. The outer transaction ROLLBACK restores the exact
-- previous grants; this file is NOT a migration or a hosted cutover.
begin;

create function pg_temp.assert_true(p_ok boolean, p_message text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

create function pg_temp.expect_state(
  p_sql text, p_expected text, p_message text
) returns void language plpgsql as $$
declare v_state text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_expected then return; end if;
    raise exception 'assertion failed: % expected %, got %',
      p_message, p_expected, v_state;
  end;
  raise exception 'assertion failed: % (succeeded)', p_message;
end;
$$;

-- Simulate the future owner-approved GRANT retirement, without committing.
-- This MUST NOT enable public Move EXECUTE or remove server-side RPC grants.
revoke update (name) on table public.user_workout_routines
  from authenticated;

select pg_temp.assert_true(
  not has_table_privilege('authenticated',
    'public.user_workout_routines', 'UPDATE')
  and not has_column_privilege('authenticated',
    'public.user_workout_routines', 'name', 'UPDATE')
  and not has_column_privilege('authenticated',
    'public.user_workout_routines', 'program_id', 'UPDATE')
  and has_table_privilege('authenticated',
    'public.user_workout_routines', 'SELECT')
  and has_column_privilege('authenticated',
    'public.user_workout_routines', 'name', 'INSERT')
  and has_function_privilege('authenticated',
    'public.update_user_workout_routine_with_composition(uuid,uuid,bigint,text,uuid,text,jsonb)',
    'EXECUTE')
  and has_function_privilege('authenticated',
    'public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)',
    'EXECUTE')
  and not has_function_privilege('authenticated',
    'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)',
    'EXECUTE'),
  'client direct writes denied, Create/Read and protected RPCs remain, Move dormant'
);

insert into auth.users (id, email) values
 ('b5690000-0000-4000-8000-000000000001', 'm2c-owner-a@example.test'),
 ('b5690000-0000-4000-8000-000000000002', 'm2c-owner-b@example.test');
insert into public.user_workout_programs (id,user_id,name) values
 ('b5690000-0000-4000-8000-000000000011',
  'b5690000-0000-4000-8000-000000000001','M2C Program A'),
 ('b5690000-0000-4000-8000-000000000012',
  'b5690000-0000-4000-8000-000000000002','M2C Program B');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'b5690000-0000-4000-8000-000000000001', true);

-- Existing authenticated metadata Create must still work after the revoke.
insert into public.user_workout_routines(id,user_id,program_id,name)
values (
 'b5690000-0000-4000-8000-000000000021',
 'b5690000-0000-4000-8000-000000000001',
 'b5690000-0000-4000-8000-000000000011',
 'M2C Original A'
);
select pg_temp.assert_true(
 (select name='M2C Original A' and composition_revision=0
  from public.user_workout_routines
  where id='b5690000-0000-4000-8000-000000000021'),
 'existing owner-scoped direct Create and SELECT are preserved'
);

-- The old installed-client request could omit source Program and revision.
-- After the cutoff, it MUST fail even for a valid owner, not silently mutate
-- a Routine that may already have been moved.
select pg_temp.expect_state(
 $$update public.user_workout_routines
   set name='Unsafe old-client Rename'
   where user_id='b5690000-0000-4000-8000-000000000001'
     and id='b5690000-0000-4000-8000-000000000021'$$,
 '42501', 'old direct Rename denied for its own Routine'
);
select pg_temp.assert_true(
 (select name='M2C Original A' and composition_revision=0
  from public.user_workout_routines
  where id='b5690000-0000-4000-8000-000000000021'),
 'rejected old Rename has no data or revision side effect'
);
select pg_temp.expect_state(
 $$update public.user_workout_routines
   set program_id='b5690000-0000-4000-8000-000000000012'
   where id='b5690000-0000-4000-8000-000000000021'$$,
 '42501', 'direct client Move remains forbidden'
);

-- The deployed, frozen owner+Program+revision+Name CAS contract remains
-- callable by the protected metadata Rename and canonical full Edit composer.
select pg_temp.assert_true(
 public.update_user_workout_routine_with_composition(
  'b5690000-0000-4000-8000-000000000021',
  'b5690000-0000-4000-8000-000000000011',
  0, 'M2C Original A', 'b5690000-0000-4000-8000-000000000101',
  'M2C Protected A', null
 ) = 1,
 'protected name-only RPC succeeds without direct client UPDATE(name)'
);
select pg_temp.assert_true(
 (select program_id='b5690000-0000-4000-8000-000000000011'
         and name='M2C Protected A' and composition_revision=1
         and last_composition_mutation_id =
           'b5690000-0000-4000-8000-000000000101'
         and pg_catalog.octet_length(last_routine_update_request_hash)=32
  from public.user_workout_routines
  where id='b5690000-0000-4000-8000-000000000021'),
 'protected RPC retains original Program and frozen mutation proof'
);
select pg_temp.assert_true(
 public.update_user_workout_routine_with_composition(
  'b5690000-0000-4000-8000-000000000021',
  'b5690000-0000-4000-8000-000000000011',
  0, 'M2C Original A', 'b5690000-0000-4000-8000-000000000101',
  'M2C Protected A', null
 ) = 1,
 'identical protected RPC retry remains idempotent'
);
select pg_temp.expect_state(
 $$select public.update_user_workout_routine_with_composition(
  'b5690000-0000-4000-8000-000000000021',
  'b5690000-0000-4000-8000-000000000011',
  0,'M2C Original A','b5690000-0000-4000-8000-000000000102',
  'Stale A',null)$$,
 'P0001','stale expected-revision/name rejected'
);
select pg_temp.expect_state(
 $$select public.update_user_workout_routine_with_composition(
  'b5690000-0000-4000-8000-000000000021',
  'b5690000-0000-4000-8000-000000000012',
  1,'M2C Protected A','b5690000-0000-4000-8000-000000000103',
  'Wrong Program',null)$$,
 'P0002','foreign or wrong Program CAS rejected'
);

-- Legacy four-argument composition Save remains supported, where intended:
-- retiring direct Name UPDATE does NOT revoke protected composition writes.
select pg_temp.assert_true(
 public.save_user_workout_routine_composition(
  'b5690000-0000-4000-8000-000000000021',1,
  'b5690000-0000-4000-8000-000000000104','[]'::jsonb
 ) = 2,
 'composition RPC remains usable and increments revision'
);
select pg_temp.assert_true(
 (select name='M2C Protected A' and composition_revision=2
  from public.user_workout_routines
  where id='b5690000-0000-4000-8000-000000000021'),
 'composition Save does not rename and does not need direct Name GRANT'
);

-- Cross-user protected Rename must not disclose or mutate another user.
reset role;
insert into public.user_workout_routines(id,user_id,program_id,name)
values (
 'b5690000-0000-4000-8000-000000000022',
 'b5690000-0000-4000-8000-000000000002',
 'b5690000-0000-4000-8000-000000000012',
 'M2C Owner B'
);
set local role authenticated;
select pg_temp.expect_state(
 $$select public.update_user_workout_routine_with_composition(
  'b5690000-0000-4000-8000-000000000022',
  'b5690000-0000-4000-8000-000000000012',
  0,'M2C Owner B','b5690000-0000-4000-8000-000000000105',
  'Cross Owner',null)$$,
 'P0002','cross-owner protected Rename is indistinguishable from missing'
);
select pg_temp.assert_true(
 (select count(*)=0 from public.user_workout_routines
  where id='b5690000-0000-4000-8000-000000000022'),
 'RLS never reveals another owner Routine'
);

-- This ROLLBACK restores the old live grant state of CI baseline: no migration
-- has been generated/applied, and no installed-client behavior is changed.
rollback;
