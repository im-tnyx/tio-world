\set ON_ERROR_STOP on
-- #555 source/merge correctness: type expectations and Set shapes are checked
-- by the authenticated atomic SQL writers. Disposable transaction only.
begin;

create function pg_temp.assert_true(ok boolean, context text)
returns void language plpgsql as $$
begin
  if ok is not true then raise exception 'assertion failed: %', context; end if;
end;
$$;

create function pg_temp.assert_rejected(stmt text, context text)
returns void language plpgsql as $$
declare result_state text;
begin
  begin
    execute stmt;
  exception when others then
    get stacked diagnostics result_state = returned_sqlstate;
    if result_state = '22023' then return; end if;
    raise exception 'assertion failed: %, wrong SQLSTATE %', context, result_state;
  end;
  raise exception 'assertion failed: %, unexpected write', context;
end;
$$;

insert into auth.users(id,email) values
 ('a5550000-0000-4000-8000-000000000001','type-check-owner@example.test'),
 ('a5550000-0000-4000-8000-000000000002','type-check-other@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('a5550000-0000-4000-8000-000000000011',
  'a5550000-0000-4000-8000-000000000001','Type Check Program');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('a5550000-0000-4000-8000-000000000021',
  'a5550000-0000-4000-8000-000000000001',
  'a5550000-0000-4000-8000-000000000011','Save Type Check');
insert into public.user_workout_exercises(id,user_id,display_name,status,exercise_type) values
 ('a5550000-0000-4000-8000-000000000031',
  'a5550000-0000-4000-8000-000000000001',
  'Custom Type Check','active','weight_reps');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'a5550000-0000-4000-8000-000000000001',true);

-- New client provides its preflighted type, with legitimate KG/REPS target.
select pg_temp.assert_true(
 public.save_user_workout_routine_composition(
  'a5550000-0000-4000-8000-000000000021',0,
  'a5550000-0000-4000-8000-000000000091',
  '[{"id":"a5550000-0000-4000-8000-000000000041",
     "exercise_ref":"a5550000-0000-4000-8000-000000000031",
     "expected_exercise_type":"weight_reps",
     "sets":[{"id":"a5550000-0000-4000-8000-000000000051",
              "reps":8,"load_kg":20}]}]'::jsonb
 ) = 1, 'matching type and targets save once'
);

-- Another session can retype while active. Simulate retype winning BEFORE
-- the Save's row lock; a stale client's expected type must now fail.
update public.user_workout_exercises set exercise_type='duration'
 where id='a5550000-0000-4000-8000-000000000031';
select pg_temp.assert_rejected($stmt$
 select public.save_user_workout_routine_composition(
  'a5550000-0000-4000-8000-000000000021',1,
  'a5550000-0000-4000-8000-000000000092',
  '[{"id":"a5550000-0000-4000-8000-000000000041",
     "exercise_ref":"a5550000-0000-4000-8000-000000000031",
     "expected_exercise_type":"weight_reps",
     "sets":[{"id":"a5550000-0000-4000-8000-000000000051",
              "reps":9,"load_kg":20}]}]'::jsonb)
$stmt$, 'stale expected type must reject before writing');

-- Legacy client without the hint cannot bypass wrong-unit validation.
select pg_temp.assert_rejected($stmt$
 select public.save_user_workout_routine_composition(
  'a5550000-0000-4000-8000-000000000021',1,
  'a5550000-0000-4000-8000-000000000093',
  '[{"id":"a5550000-0000-4000-8000-000000000041",
     "exercise_ref":"a5550000-0000-4000-8000-000000000031",
     "sets":[{"id":"a5550000-0000-4000-8000-000000000051",
              "reps":9}]}]'::jsonb)
$stmt$, 'unhinted legacy KG/REPS cannot write under duration');
select pg_temp.assert_true(
 (select composition_revision=1 from public.user_workout_routines
  where id='a5550000-0000-4000-8000-000000000021')
 and (select reps=8 from public.user_workout_routine_sets
  where id='a5550000-0000-4000-8000-000000000051'),
 'both rejections retain committed revision and Set values'
);

-- Replay of the FIRST mutation stays idempotent despite retyping.
select pg_temp.assert_true(
 public.save_user_workout_routine_composition(
  'a5550000-0000-4000-8000-000000000021',0,
  'a5550000-0000-4000-8000-000000000091',
  '[{"id":"a5550000-0000-4000-8000-000000000041",
     "exercise_ref":"a5550000-0000-4000-8000-000000000031",
     "expected_exercise_type":"weight_reps",
     "sets":[{"id":"a5550000-0000-4000-8000-000000000051",
              "reps":8,"load_kg":20}]}]'::jsonb) = 1,
 'already-committed token must replay before new type checks'
);

-- New current-type TIME write is allowed; server compares exact type + shape.
select pg_temp.assert_true(
 public.save_user_workout_routine_composition(
  'a5550000-0000-4000-8000-000000000021',1,
  'a5550000-0000-4000-8000-000000000094',
  '[{"id":"a5550000-0000-4000-8000-000000000041",
     "exercise_ref":"a5550000-0000-4000-8000-000000000031",
     "expected_exercise_type":"duration",
     "sets":[{"id":"a5550000-0000-4000-8000-000000000051",
              "reps":null,"duration_seconds":600}]}]'::jsonb) = 2,
 'current duration type accepts duration-only Set'
);

-- Existing Create RPC calls Save inside the same transaction and lock.
select pg_temp.assert_rejected($stmt$
 select public.create_user_workout_routine_with_composition(
  'a5550000-0000-4000-8000-000000000022',
  'a5550000-0000-4000-8000-000000000011','Bad Stale Create',
  'a5550000-0000-4000-8000-000000000095',
  '[{"id":"a5550000-0000-4000-8000-000000000042",
     "exercise_ref":"a5550000-0000-4000-8000-000000000031",
     "expected_exercise_type":"weight_reps",
     "sets":[{"id":"a5550000-0000-4000-8000-000000000052",
              "reps":10}]}]'::jsonb)
$stmt$, 'Create also rejects stale expected type and rolls back metadata');
select pg_temp.assert_true(
 not exists(select 1 from public.user_workout_routines
  where id='a5550000-0000-4000-8000-000000000022'),
 'rejected Create leaves no orphan Routine'
);
select pg_temp.assert_true(
 public.create_user_workout_routine_with_composition(
  'a5550000-0000-4000-8000-000000000022',
  'a5550000-0000-4000-8000-000000000011','Correct Type Create',
  'a5550000-0000-4000-8000-000000000096',
  '[{"id":"a5550000-0000-4000-8000-000000000042",
     "exercise_ref":"a5550000-0000-4000-8000-000000000031",
     "expected_exercise_type":"duration",
     "sets":[{"id":"a5550000-0000-4000-8000-000000000052",
              "reps":null,"duration_seconds":300}]}]'::jsonb) = 1,
 'Create accepts locked current type'
);

-- Unsupported STEPS/TIME cannot silently reinterpret step targets as Reps.
update public.user_workout_exercises set exercise_type='steps_duration'
 where id='a5550000-0000-4000-8000-000000000031';
select pg_temp.assert_rejected($stmt$
 select public.save_user_workout_routine_composition(
  'a5550000-0000-4000-8000-000000000021',2,
  'a5550000-0000-4000-8000-000000000097',
  '[{"id":"a5550000-0000-4000-8000-000000000041",
     "exercise_ref":"a5550000-0000-4000-8000-000000000031",
     "expected_exercise_type":"steps_duration",
     "sets":[{"id":"a5550000-0000-4000-8000-000000000051",
              "reps":null,"reps_max":null,"set_type":"normal",
              "load_kg":null,"distance_meters":null,
              "duration_seconds":null,"rest_seconds":null}]}]'::jsonb)
$stmt$, 'unsupported STEPS type never commits a new snapshot');

rollback;
