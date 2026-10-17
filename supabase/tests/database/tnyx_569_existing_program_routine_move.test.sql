\set ON_ERROR_STOP on
-- #569 M1. Run ONLY against local/disposable migrated DB; all fixtures roll back.
begin;

create function pg_temp.assert_true(p_ok boolean, p_label text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_label;
  end if;
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
  has_function_privilege('authenticated',
    'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('anon',
    'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  and not has_function_privilege('service_role',
    'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)', 'EXECUTE')
  and not has_column_privilege('authenticated',
    'public.user_workout_routines', 'program_id', 'UPDATE')
  and has_function_privilege('authenticated',
    'public.update_user_workout_routine_with_composition(uuid,uuid,bigint,text,uuid,text,jsonb)', 'EXECUTE')
  and has_function_privilege('authenticated',
    'public.delete_user_workout_routine(uuid,uuid,bigint)', 'EXECUTE'),
  'only authenticated can call Move; no direct program_id UPDATE; old RPCs preserved'
);

insert into auth.users (id,email) values
 ('a5690000-0000-4000-8000-000000000001','move-a@example.test'),
 ('a5690000-0000-4000-8000-000000000002','move-b@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('a5690000-0000-4000-8000-000000000011',
  'a5690000-0000-4000-8000-000000000001','Source A'),
 ('a5690000-0000-4000-8000-000000000012',
  'a5690000-0000-4000-8000-000000000001','Destination A'),
 ('a5690000-0000-4000-8000-000000000013',
  'a5690000-0000-4000-8000-000000000002','Foreign B');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('a5690000-0000-4000-8000-000000000021',
  'a5690000-0000-4000-8000-000000000001',
  'a5690000-0000-4000-8000-000000000011','Morning'),
 ('a5690000-0000-4000-8000-000000000022',
  'a5690000-0000-4000-8000-000000000002',
  'a5690000-0000-4000-8000-000000000013','Foreign');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'a5690000-0000-4000-8000-000000000001', true);

select pg_temp.assert_true(
 public.save_user_workout_routine_composition(
  'a5690000-0000-4000-8000-000000000021', 0,
  'a5690000-0000-4000-8000-000000000091',
  '[{"id":"a5690000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_squat","sets":[
      {"id":"a5690000-0000-4000-8000-000000000051",
       "reps":10,"set_type":"normal","reps_max":null,
       "load_kg":20,"distance_meters":null,
       "duration_seconds":null,"rest_seconds":60}]}]'::jsonb)=1,
 'precondition: composed Routine starts at revision 1'
);

select pg_temp.expect_state(
 $$select public.move_user_workout_routine(
   null,'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',1,
   'a5690000-0000-4000-8000-000000000101')$$,
 '22023','null routine rejected');
select pg_temp.expect_state(
 $$select public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000011',1,
   'a5690000-0000-4000-8000-000000000101')$$,
 '22023','same source/destination rejected');
select pg_temp.expect_state(
 $$select public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000013',1,
   'a5690000-0000-4000-8000-000000000101')$$,
 'P0002','foreign target opaque failure');
select pg_temp.expect_state(
 $$select public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000022',
   'a5690000-0000-4000-8000-000000000013',
   'a5690000-0000-4000-8000-000000000012',0,
   'a5690000-0000-4000-8000-000000000101')$$,
 'P0002','foreign Routine and source opaque failure');
select pg_temp.expect_state(
 $$select public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',0,
   'a5690000-0000-4000-8000-000000000101')$$,
 'P0001','stale revision cannot move');
select pg_temp.expect_state(
 $$update public.user_workout_routines
   set program_id='a5690000-0000-4000-8000-000000000012'
   where id='a5690000-0000-4000-8000-000000000021'$$,
 '42501','direct client program_id UPDATE denied');

select pg_temp.assert_true(
 public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',1,
   'a5690000-0000-4000-8000-000000000101')=2,
 'A -> B committed and revision advanced once'
);
select pg_temp.assert_true(
 (select program_id='a5690000-0000-4000-8000-000000000012'
         and composition_revision=2
         and last_composition_mutation_id='a5690000-0000-4000-8000-000000000101'
         and pg_catalog.octet_length(last_routine_update_request_hash)=32
  from public.user_workout_routines
  where id='a5690000-0000-4000-8000-000000000021')
 and (select count(*)=1 from public.user_workout_routine_exercises
      where routine_id='a5690000-0000-4000-8000-000000000021'
        and id='a5690000-0000-4000-8000-000000000041'
        and position=0)
 and (select count(*)=1 from public.user_workout_routine_sets
      where routine_exercise_id='a5690000-0000-4000-8000-000000000041'
        and id='a5690000-0000-4000-8000-000000000051'
        and reps=10 and load_kg=20 and rest_seconds=60),
 'same Routine/Exercise/Set UUID, order, prescription; no child re-creation'
);
select pg_temp.assert_true(
 public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',1,
   'a5690000-0000-4000-8000-000000000101')=2,
 'exact frozen request retry returns committed revision without second update'
);
select pg_temp.expect_state(
 $$select public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',0,
   'a5690000-0000-4000-8000-000000000101')$$,
 'P0001','mutation token cannot be reused with changed revision');
select pg_temp.expect_state(
 $$select public.update_user_workout_routine_with_composition(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   1,'Morning','a5690000-0000-4000-8000-000000000102',
   'Stale Edit',null)$$,
 'P0002','pre-move source-program Editor cannot write');

select pg_temp.assert_true(
 public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000012',
   'a5690000-0000-4000-8000-000000000011',2,
   'a5690000-0000-4000-8000-000000000103')=3,
 'B -> A advances revision and preserves stable identity'
);
select pg_temp.expect_state(
 $$select public.update_user_workout_routine_with_composition(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   1,'Morning','a5690000-0000-4000-8000-000000000104',
   'ABA Stale Edit',null)$$,
 'P0001','A -> B -> A must not revive prior A editor');
select pg_temp.expect_state(
 $$select public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',1,
   'a5690000-0000-4000-8000-000000000101')$$,
 'P0001','old move replay invalid after another aggregate mutation');

select pg_temp.assert_true(
 (select program_id='a5690000-0000-4000-8000-000000000011'
    and composition_revision=3 from public.user_workout_routines
    where id='a5690000-0000-4000-8000-000000000021')
 and (select count(*)=1 from public.user_workout_routine_exercises
      where routine_id='a5690000-0000-4000-8000-000000000021')
 and (select count(*)=1 from public.user_workout_routine_sets
      where routine_exercise_id='a5690000-0000-4000-8000-000000000041'),
 'failed requests preserve owner Routine and children'
);


-- P2 review regression: an exact previously committed Move remains idempotent
-- after the now-empty source Program is removed by a privileged lifecycle.
select pg_temp.assert_true(
 public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',3,
   'a5690000-0000-4000-8000-000000000105')=4,
 'precondition: A to B committed again at revision 4'
);

-- Normal authenticated Program DELETE remains denied. This fixture uses the
-- CI-only privileged connection role to simulate later #567 source cleanup.
reset role;
delete from public.user_workout_programs
where id='a5690000-0000-4000-8000-000000000011';
set local role authenticated;

select pg_temp.assert_true(
 public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',3,
   'a5690000-0000-4000-8000-000000000105')=4,
 'same token replay succeeds even after source Program cleanup'
);
select pg_temp.assert_true(
 (select program_id='a5690000-0000-4000-8000-000000000012'
    and composition_revision=4
    and last_composition_mutation_id='a5690000-0000-4000-8000-000000000105'
  from public.user_workout_routines
  where id='a5690000-0000-4000-8000-000000000021')
 and (select count(*)=1 from public.user_workout_routine_sets
      where id='a5690000-0000-4000-8000-000000000051'),
 'replay does not bump revision or modify child composition'
);
select pg_temp.expect_state(
 $select public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',3,
   'a5690000-0000-4000-8000-000000000106')$,
 'P0002','new request cannot use a deleted source Program'
);
select pg_temp.expect_state(
 $select public.move_user_workout_routine(
   'a5690000-0000-4000-8000-000000000021',
   'a5690000-0000-4000-8000-000000000011',
   'a5690000-0000-4000-8000-000000000012',2,
   'a5690000-0000-4000-8000-000000000105')$,
 'P0001','same token with altered CAS remains a mutation conflict'
);

rollback;
