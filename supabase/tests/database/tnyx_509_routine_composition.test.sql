\set ON_ERROR_STOP on

-- GitHub #509 / TNYX-78: transaction-scoped Routine composition security tests.
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
  p_sql text, p_state text, p_message text
)
returns void language plpgsql as $$
declare v_state text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_state then
      return;
    end if;
    raise exception 'assertion failed: % expected %, got %', p_message, p_state, v_state;
  end;
  raise exception 'assertion failed: % (operation succeeded)', p_message;
end;
$$;

select pg_temp.assert_true(
  to_regclass('public.user_workout_routine_exercises') is not null
  and to_regclass('public.user_workout_routine_sets') is not null,
  'ordered composition tables must exist'
);

select pg_temp.assert_true(
  (select bool_and(c.relrowsecurity) from pg_class c
   where c.oid in (
     'public.user_workout_routine_exercises'::regclass,
     'public.user_workout_routine_sets'::regclass
   )),
  'composition child RLS must be enabled'
);

select pg_temp.assert_true(
  has_table_privilege('authenticated', 'public.user_workout_routine_exercises', 'SELECT')
  and has_table_privilege('authenticated', 'public.user_workout_routine_sets', 'SELECT')
  and not has_table_privilege('authenticated', 'public.user_workout_routine_exercises', 'INSERT')
  and not has_table_privilege('authenticated', 'public.user_workout_routine_exercises', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.user_workout_routine_exercises', 'DELETE')
  and not has_table_privilege('authenticated', 'public.user_workout_routine_sets', 'INSERT')
  and not has_table_privilege('authenticated', 'public.user_workout_routine_sets', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.user_workout_routine_sets', 'DELETE'),
  'client may read but not directly mutate composition children'
);

select pg_temp.assert_true(
  not has_column_privilege('authenticated','public.user_workout_routines','composition_revision','UPDATE')
  and not has_column_privilege('authenticated','public.user_workout_routines','last_composition_mutation_id','UPDATE')
  and has_column_privilege('authenticated','public.user_workout_routines','name','UPDATE'),
  'revision and token are RPC-only; rename remains available'
);

select pg_temp.assert_true(
  has_function_privilege(
    'authenticated',
    'public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)',
    'EXECUTE'
  ) and not has_function_privilege(
    'anon',
    'public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)',
    'EXECUTE'
  ),
  'only authenticated callers may execute atomic composition save'
);

insert into auth.users (id, email) values
  ('a5090000-0000-4000-8000-000000000001','issue509-a@example.test'),
  ('a5090000-0000-4000-8000-000000000002','issue509-b@example.test');

insert into public.user_workout_programs (id,user_id,name) values
  ('a5090000-0000-4000-8000-000000000011','a5090000-0000-4000-8000-000000000001','Program A'),
  ('a5090000-0000-4000-8000-000000000012','a5090000-0000-4000-8000-000000000002','Program B');

insert into public.user_workout_routines (id,user_id,program_id,name) values
  ('a5090000-0000-4000-8000-000000000021','a5090000-0000-4000-8000-000000000001','a5090000-0000-4000-8000-000000000011','Routine A'),
  ('a5090000-0000-4000-8000-000000000022','a5090000-0000-4000-8000-000000000002','a5090000-0000-4000-8000-000000000012','Routine B');

insert into public.user_workout_exercises (id,user_id,display_name) values
  ('a5090000-0000-4000-8000-000000000031','a5090000-0000-4000-8000-000000000001','Owner A custom'),
  ('a5090000-0000-4000-8000-000000000032','a5090000-0000-4000-8000-000000000002','Owner B custom');

-- The existing metadata-only rows have empty composition revision 0.
select pg_temp.assert_true(
  (select composition_revision=0 and last_composition_mutation_id is null
   from public.user_workout_routines
   where id='a5090000-0000-4000-8000-000000000021'),
  'old Routine rows must have compatible zero/default revision'
);

set local role authenticated;
select set_config('request.jwt.claim.sub','a5090000-0000-4000-8000-000000000001',true);

select pg_temp.assert_raises(
  $$insert into public.user_workout_routine_exercises
    (id,user_id,routine_id,position,catalog_exercise_id) values
    ('a5090000-0000-4000-8000-000000000041',
     'a5090000-0000-4000-8000-000000000001',
     'a5090000-0000-4000-8000-000000000021',0,'ex_squat')$$,
  '42501', 'direct child write must be forbidden'
);

select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5090000-0000-4000-8000-000000000021',0,
    'a5090000-0000-4000-8000-000000000091',
    '[
      {"id":"a5090000-0000-4000-8000-000000000041","exercise_ref":"ex_squat","sets":[
        {"id":"a5090000-0000-4000-8000-000000000051","reps":10,"load_kg":0,"rest_seconds":0},
        {"id":"a5090000-0000-4000-8000-000000000052","reps":8}]},
      {"id":"a5090000-0000-4000-8000-000000000042","exercise_ref":"ex_squat","sets":[]},
      {"id":"a5090000-0000-4000-8000-000000000043","exercise_ref":"a5090000-0000-4000-8000-000000000031","sets":[]}
    ]'::jsonb
  )=1,
  'first atomic save must return revision 1'
);

select pg_temp.assert_true(
  (select count(*)=3 from public.user_workout_routine_exercises)
  and (select count(*)=2 from public.user_workout_routine_sets)
  and (select count(*)=2 from public.user_workout_routine_exercises
      where catalog_exercise_id='ex_squat'),
  'ordered repeated catalog references and sets must persist'
);

select pg_temp.assert_true(
  (select load_kg=0 and rest_seconds=0 from public.user_workout_routine_sets
   where id='a5090000-0000-4000-8000-000000000051')
  and (select load_kg is null and rest_seconds is null
       from public.user_workout_routine_sets
       where id='a5090000-0000-4000-8000-000000000052'),
  'zero and null optional set values must remain distinct'
);

-- Exact retry is success, despite now-stale expected revision.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5090000-0000-4000-8000-000000000021',0,
    'a5090000-0000-4000-8000-000000000091',
    '[
      {"id":"a5090000-0000-4000-8000-000000000041","exercise_ref":"ex_squat","sets":[
        {"id":"a5090000-0000-4000-8000-000000000051","reps":10,"load_kg":0,"rest_seconds":0},
        {"id":"a5090000-0000-4000-8000-000000000052","reps":8}]},
      {"id":"a5090000-0000-4000-8000-000000000042","exercise_ref":"ex_squat","sets":[]},
      {"id":"a5090000-0000-4000-8000-000000000043","exercise_ref":"a5090000-0000-4000-8000-000000000031","sets":[]}
    ]'::jsonb
  )=1,
  'same mutation and same payload must be idempotent'
);

select pg_temp.assert_raises(
  $$select public.save_user_workout_routine_composition(
    'a5090000-0000-4000-8000-000000000021',0,
    'a5090000-0000-4000-8000-000000000091','[]'::jsonb
  )$$,
  'P0001', 'same mutation with different payload must conflict'
);

select pg_temp.assert_raises(
  $$select public.save_user_workout_routine_composition(
    'a5090000-0000-4000-8000-000000000021',0,
    'a5090000-0000-4000-8000-000000000092','[]'::jsonb
  )$$,
  'P0001', 'new mutation with stale revision must conflict'
);

select pg_temp.assert_raises(
  $$select public.save_user_workout_routine_composition(
    'a5090000-0000-4000-8000-000000000022',0,
    'a5090000-0000-4000-8000-000000000092','[]'::jsonb
  )$$,
  'P0002', 'cross-owner Routine must be indistinguishable from missing'
);

select pg_temp.assert_raises(
  $$select public.save_user_workout_routine_composition(
    'a5090000-0000-4000-8000-000000000021',1,
    'a5090000-0000-4000-8000-000000000092',
    '[{"id":"a5090000-0000-4000-8000-000000000044",
      "exercise_ref":"a5090000-0000-4000-8000-000000000032","sets":[]}]'::jsonb
  )$$,
  'P0002', 'cross-owner Custom Exercise reference must be rejected'
);

select pg_temp.assert_raises(
  $$select public.save_user_workout_routine_composition(
    'a5090000-0000-4000-8000-000000000021',1,
    'a5090000-0000-4000-8000-000000000092',
    '[{"id":"a5090000-0000-4000-8000-000000000044",
      "exercise_ref":"ex_squat",
      "sets":[{"id":"a5090000-0000-4000-8000-000000000055",
               "reps":0}]}]'::jsonb
  )$$,
  '22023', 'zero prescribed reps must fail before mutation'
);

select pg_temp.assert_true(
  (select composition_revision=1 from public.user_workout_routines
   where id='a5090000-0000-4000-8000-000000000021')
  and (select count(*)=3 from public.user_workout_routine_exercises),
  'all rejected writes must leave prior composition intact'
);

select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5090000-0000-4000-8000-000000000021',1,
    'a5090000-0000-4000-8000-000000000093','[]'::jsonb
  )=2,
  'empty draft composition must save atomically'
);

select pg_temp.assert_true(
  (select count(*)=0 from public.user_workout_routine_exercises)
  and (select count(*)=0 from public.user_workout_routine_sets),
  'empty draft save must clear children without orphan Sets'
);

reset role;

-- Deferrable same-owner user-exercise FK must not block full-account cascades.
-- Deferred FK still rejects arbitrary missing Custom Exercise references at
-- transaction end; the RPC already rejects them early with an owner lookup.
rollback;
