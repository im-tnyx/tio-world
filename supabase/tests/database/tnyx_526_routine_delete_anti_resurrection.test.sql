\set ON_ERROR_STOP on
-- #526 P1: a confirmed permanent Delete must retire its UUID across ALL Create
-- paths. Disposable DB only; the whole test rolls back.
begin;

create function pg_temp.assert_true(p_ok boolean, p_label text)
returns void language plpgsql as $$
begin
  if p_ok is not true then raise exception 'assertion failed: %', p_label; end if;
end;
$$;

create function pg_temp.expect_state(p_sql text, p_state text, p_label text)
returns void language plpgsql as $$
declare v_state text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_state then return; end if;
    raise exception 'assertion failed: % expected %, got %',
      p_label, p_state, v_state;
  end;
  raise exception 'assertion failed: % (succeeded)', p_label;
end;
$$;

select pg_temp.assert_true(
  to_regclass('private.deleted_user_workout_routine_ids') is not null
  and not has_table_privilege('authenticated',
    'private.deleted_user_workout_routine_ids', 'SELECT')
  and not has_table_privilege('authenticated',
    'private.deleted_user_workout_routine_ids', 'INSERT')
  and not has_table_privilege('service_role',
    'private.deleted_user_workout_routine_ids', 'SELECT')
  and not has_table_privilege('anon',
    'private.deleted_user_workout_routine_ids', 'SELECT')
  and not has_function_privilege('authenticated',
    'private.lock_user_workout_routine_identity(uuid)', 'EXECUTE')
  and not has_function_privilege('authenticated',
    'private.guard_deleted_user_workout_routine_insert()', 'EXECUTE')
  and (select relrowsecurity from pg_class
       where oid='private.deleted_user_workout_routine_ids'::regclass),
  'private tombstones have RLS and no client grants'
);

insert into auth.users(id,email) values
 ('d5270000-0000-4000-8000-000000000001','anti-resurrection-owner@example.test'),
 ('d5270000-0000-4000-8000-000000000002','anti-resurrection-foreign@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('d5270000-0000-4000-8000-000000000011',
  'd5270000-0000-4000-8000-000000000001','Owner Program'),
 ('d5270000-0000-4000-8000-000000000012',
  'd5270000-0000-4000-8000-000000000002','Foreign Program');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'd5270000-0000-4000-8000-000000000001',true);

-- Same stable Create UUID + mutation UUID and JSON is a supported retry
-- *while the Routine is alive*. It must stop working only after Delete.
select pg_temp.assert_true(
  public.create_user_workout_routine_with_composition(
    'd5270000-0000-4000-8000-000000000021',
    'd5270000-0000-4000-8000-000000000011',
    'Original',
    'd5270000-0000-4000-8000-000000000091',
    '[{"id":"d5270000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_squat","sets":[
       {"id":"d5270000-0000-4000-8000-000000000051","reps":10}]}]'::jsonb
  )=1,
  'original atomic Create persists one composed Routine'
);
select pg_temp.assert_true(
  public.create_user_workout_routine_with_composition(
    'd5270000-0000-4000-8000-000000000021',
    'd5270000-0000-4000-8000-000000000011',
    'Original',
    'd5270000-0000-4000-8000-000000000091',
    '[{"id":"d5270000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_squat","sets":[
       {"id":"d5270000-0000-4000-8000-000000000051","reps":10}]}]'::jsonb
  )=1,
  'same Create idempotently replays before Delete'
);

select pg_temp.assert_true(
  public.delete_user_workout_routine(
    'd5270000-0000-4000-8000-000000000021',
    'd5270000-0000-4000-8000-000000000011',1),
  'confirmed permanent Delete succeeds'
);

select pg_temp.expect_state($cmd$
  select public.create_user_workout_routine_with_composition(
    'd5270000-0000-4000-8000-000000000021',
    'd5270000-0000-4000-8000-000000000011',
    'Original',
    'd5270000-0000-4000-8000-000000000091',
    '[{"id":"d5270000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_squat","sets":[
       {"id":"d5270000-0000-4000-8000-000000000051","reps":10}]}]'::jsonb
  )
$cmd$, 'P0001', 'old identical Create RPC cannot resurrect deleted UUID');

select pg_temp.expect_state($cmd$
  insert into public.user_workout_routines(id,user_id,program_id,name)
  values (
    'd5270000-0000-4000-8000-000000000021',
    'd5270000-0000-4000-8000-000000000001',
    'd5270000-0000-4000-8000-000000000011','legacy replay'
  )
$cmd$, 'P0001', 'old authenticated metadata INSERT cannot resurrect UUID');

select pg_temp.assert_true(
  (select count(*)=0 from public.user_workout_routines where
   id='d5270000-0000-4000-8000-000000000021')
  and (select count(*)=0 from public.user_workout_routine_exercises where
   id='d5270000-0000-4000-8000-000000000041')
  and (select count(*)=0 from public.user_workout_routine_sets where
   id='d5270000-0000-4000-8000-000000000051'),
  'failed replays leave no parent or composed children'
);

select set_config('request.jwt.claim.sub',
  'd5270000-0000-4000-8000-000000000002',true);
select pg_temp.expect_state($cmd$
  insert into public.user_workout_routines(id,user_id,program_id,name)
  values (
    'd5270000-0000-4000-8000-000000000021',
    'd5270000-0000-4000-8000-000000000002',
    'd5270000-0000-4000-8000-000000000012','cross-account reusing deleted UUID'
  )
$cmd$, 'P0001', 'retired UUID cannot be claimed by another user');

select set_config('request.jwt.claim.sub',
  'd5270000-0000-4000-8000-000000000001',true);
select pg_temp.assert_true(
  public.create_user_workout_routine_with_composition(
    'd5270000-0000-4000-8000-000000000022',
    'd5270000-0000-4000-8000-000000000011',
    'Fresh after Delete',
    'd5270000-0000-4000-8000-000000000092',
    '[{"id":"d5270000-0000-4000-8000-000000000042",
      "exercise_ref":"ex_squat","sets":[
       {"id":"d5270000-0000-4000-8000-000000000052","reps":8}]}]'::jsonb
  )=1,
  'fresh UUID Create remains enabled after retiring a different UUID'
);
insert into public.user_workout_routines(id,user_id,program_id,name)
values (
 'd5270000-0000-4000-8000-000000000023',
 'd5270000-0000-4000-8000-000000000001',
 'd5270000-0000-4000-8000-000000000011','fresh legacy'
);
select pg_temp.assert_true(
  (select count(*)=2 from public.user_workout_routines
   where user_id='d5270000-0000-4000-8000-000000000001'),
  'non-retired direct metadata and atomic Create both still work'
);

reset role;
select pg_temp.assert_true(
  (select count(*)=1 from private.deleted_user_workout_routine_ids
   where routine_id='d5270000-0000-4000-8000-000000000021'
   and user_id='d5270000-0000-4000-8000-000000000001'),
  'one private retired-ID record exists for owner'
);

-- Account deletion must remove the private tombstone as well as active
-- Programs/Routines. Nothing survives to identify a deleted account.
delete from auth.users
where id='d5270000-0000-4000-8000-000000000001';
select pg_temp.assert_true(
  (select count(*)=0 from private.deleted_user_workout_routine_ids
   where routine_id='d5270000-0000-4000-8000-000000000021')
  and (select count(*)=0 from public.user_workout_routines
   where user_id='d5270000-0000-4000-8000-000000000001')
  and (select count(*)=1 from public.users
   where id='d5270000-0000-4000-8000-000000000002'),
  'account cascade removes own tombstone and retains other account'
);
rollback;
