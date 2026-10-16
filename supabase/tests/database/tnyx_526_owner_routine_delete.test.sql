\set ON_ERROR_STOP on
-- #526: Local/disposable owner-safe Routine Delete SQL matrix. Never hosted.
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
    'public.delete_user_workout_routine(uuid,uuid,bigint)','EXECUTE')
  and not has_function_privilege('anon',
    'public.delete_user_workout_routine(uuid,uuid,bigint)','EXECUTE')
  and not has_function_privilege('PUBLIC',
    'public.delete_user_workout_routine(uuid,uuid,bigint)','EXECUTE')
  and not has_table_privilege('authenticated',
    'public.user_workout_routines','DELETE')
  and not has_table_privilege('authenticated',
    'public.user_workout_routine_exercises','DELETE')
  and not has_table_privilege('authenticated',
    'public.user_workout_routine_sets','DELETE')
  and has_function_privilege('authenticated',
    'public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)','EXECUTE')
  and has_function_privilege('authenticated',
    'public.update_user_workout_routine_with_composition(uuid,uuid,bigint,text,uuid,text,jsonb)','EXECUTE'),
  'authenticated RPC only; old RPCs work and direct client Delete remains denied'
);

insert into auth.users (id,email) values
 ('d5260000-0000-4000-8000-000000000001','routine-delete-a@example.test'),
 ('d5260000-0000-4000-8000-000000000002','routine-delete-b@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('d5260000-0000-4000-8000-000000000011','d5260000-0000-4000-8000-000000000001','A First'),
 ('d5260000-0000-4000-8000-000000000012','d5260000-0000-4000-8000-000000000001','A Second'),
 ('d5260000-0000-4000-8000-000000000013','d5260000-0000-4000-8000-000000000002','B First');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('d5260000-0000-4000-8000-000000000021',
  'd5260000-0000-4000-8000-000000000001',
  'd5260000-0000-4000-8000-000000000011','To Delete'),
 ('d5260000-0000-4000-8000-000000000022',
  'd5260000-0000-4000-8000-000000000001',
  'd5260000-0000-4000-8000-000000000011','Keep A'),
 ('d5260000-0000-4000-8000-000000000023',
  'd5260000-0000-4000-8000-000000000001',
  'd5260000-0000-4000-8000-000000000012','Keep A Second'),
 ('d5260000-0000-4000-8000-000000000024',
  'd5260000-0000-4000-8000-000000000002',
  'd5260000-0000-4000-8000-000000000013','Keep B');

set local role authenticated;
select set_config('request.jwt.claim.sub',
  'd5260000-0000-4000-8000-000000000001', true);

select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'd5260000-0000-4000-8000-000000000021', 0,
    'd5260000-0000-4000-8000-000000000091',
    '[{"id":"d5260000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_squat","sets":[
       {"id":"d5260000-0000-4000-8000-000000000051",
        "reps":10,"set_type":"normal","reps_max":null,
        "load_kg":20,"distance_meters":null,
        "duration_seconds":null,"rest_seconds":60}]}]'::jsonb)=1,
  'precondition: existing Save composes one Routine before Delete'
);
select pg_temp.assert_true(
  (select count(*)=1 from public.user_workout_routine_exercises
   where id='d5260000-0000-4000-8000-000000000041')
  and (select count(*)=1 from public.user_workout_routine_sets
   where id='d5260000-0000-4000-8000-000000000051'),
  'precondition: composed child Exercise + Set are present'
);

select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    null,'d5260000-0000-4000-8000-000000000011',1)$$,
  '22023','missing RoutineId is invalid'
);
select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000021',
    'd5260000-0000-4000-8000-000000000011',-1)$$,
  '22023','negative revision is invalid'
);
select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000021',
    'd5260000-0000-4000-8000-000000000011',null)$$,
  '22023','null revision is invalid'
);
select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000021',
    'd5260000-0000-4000-8000-000000000012',1)$$,
  'P0002','wrong own Program is opaque not-found'
);
select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000024',
    'd5260000-0000-4000-8000-000000000013',0)$$,
  'P0002','other Account Routine is opaque not-found'
);
select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000021',
    'd5260000-0000-4000-8000-000000000011',0)$$,
  'P0001','stale composition revision cannot cascade children'
);
select pg_temp.expect_state(
  $$delete from public.user_workout_routines
    where id='d5260000-0000-4000-8000-000000000021'$$,
  '42501','authenticated direct Routine table DELETE remains denied'
);

-- Existing legacy authenticated Data API UPDATE(name) advances the routine
-- aggregate revision. A stale Delete from an earlier UI snapshot must fail.
update public.user_workout_routines set name='Updated Before Delete'
where id='d5260000-0000-4000-8000-000000000021';
select pg_temp.assert_true(
  (select composition_revision=2 from public.user_workout_routines
   where id='d5260000-0000-4000-8000-000000000021'),
  'concurrent legacy Rename invalidates earlier Delete revision'
);
select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000021',
    'd5260000-0000-4000-8000-000000000011',1)$$,
  'P0001','stale after legacy name revision conflict'
);
select pg_temp.assert_true(
  (select count(*)=1 from public.user_workout_routines
   where id='d5260000-0000-4000-8000-000000000021')
  and (select count(*)=1 from public.user_workout_routine_sets
   where id='d5260000-0000-4000-8000-000000000051'),
  'rejected attempts preserve Routine and composed child Set'
);

select pg_temp.assert_true(
  public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000021',
    'd5260000-0000-4000-8000-000000000011',2),
  'one confirmed owner-scoped Delete removes exactly one parent'
);
select pg_temp.assert_true(
  (select count(*)=0 from public.user_workout_routines
   where id='d5260000-0000-4000-8000-000000000021')
  and (select count(*)=0 from public.user_workout_routine_exercises
   where id='d5260000-0000-4000-8000-000000000041')
  and (select count(*)=0 from public.user_workout_routine_sets
   where id='d5260000-0000-4000-8000-000000000051'),
  'confirmed permanent Delete atomically cascades only saved composition'
);
select pg_temp.assert_true(
  (select count(*)=3 from public.user_workout_programs
   where id in ('d5260000-0000-4000-8000-000000000011',
                'd5260000-0000-4000-8000-000000000012',
                'd5260000-0000-4000-8000-000000000013'))
  and (select count(*)=3 from public.user_workout_routines
   where id in ('d5260000-0000-4000-8000-000000000022',
                'd5260000-0000-4000-8000-000000000023',
                'd5260000-0000-4000-8000-000000000024')),
  'delete preserves every Program and unrelated own/other-user Routines'
);
select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000021',
    'd5260000-0000-4000-8000-000000000011',2)$$,
  'P0002','repeat Delete after success is harmless and opaque'
);
select pg_temp.expect_state(
  $$select public.save_user_workout_routine_composition(
    'd5260000-0000-4000-8000-000000000021',2,
    'd5260000-0000-4000-8000-000000000092','[]'::jsonb)$$,
  'P0002','old 4-arg Save cannot recreate deleted Routine'
);
select pg_temp.expect_state(
  $$select public.update_user_workout_routine_with_composition(
    'd5260000-0000-4000-8000-000000000021',
    'd5260000-0000-4000-8000-000000000011',2,
    'Updated Before Delete',
    'd5260000-0000-4000-8000-000000000093','Resurrect',null)$$,
  'P0002','new 7-arg Name+Sets Update cannot recreate deleted Routine'
);

-- Existing unrelated Routine can still be deleted with initial revision zero.
select pg_temp.assert_true(
  public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000023',
    'd5260000-0000-4000-8000-000000000012',0),
  'empty Routine with initial aggregate revision is deletable independently'
);

select set_config('request.jwt.claim.sub','',true);
select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000022',
    'd5260000-0000-4000-8000-000000000011',0)$$,
  '28000','signed-out authenticated role does not delete anything'
);
reset role;
set local role anon;
select pg_temp.expect_state(
  $$select public.delete_user_workout_routine(
    'd5260000-0000-4000-8000-000000000022',
    'd5260000-0000-4000-8000-000000000011',0)$$,
  '42501','anonymous EXECUTE denied before function'
);
rollback;
