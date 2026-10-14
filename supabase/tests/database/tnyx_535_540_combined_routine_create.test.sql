\set ON_ERROR_STOP on

-- W4 integration: #536 atomic Create after #540 nullable Set migration.
-- Disposable only; this test must never touch the hosted Supabase database.
begin;

create function pg_temp.assert_true(ok boolean, message text)
returns void language plpgsql as $$
begin
  if ok is not true then
    raise exception 'assertion failed: %', message;
  end if;
end;
$$;

create function pg_temp.assert_raises(sql text, state text, message text)
returns void language plpgsql as $$
declare actual text;
begin
  begin
    execute sql;
  exception when others then
    get stacked diagnostics actual = returned_sqlstate;
    if actual = state then return; end if;
    raise exception 'assertion failed: %; expected %, got %',
      message, state, actual;
  end;
  raise exception 'assertion failed: %; unexpectedly succeeded', message;
end;
$$;

-- Prove BOTH migrations are present, not merely either individual branch.
select pg_temp.assert_true(
  to_regprocedure(
    'public.create_user_workout_routine_with_composition(uuid,uuid,text,uuid,jsonb)'
  ) is not null
  and exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_workout_routine_sets'
      and column_name = 'reps' and is_nullable = 'YES'
  )
  and exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_workout_routine_sets'
      and column_name = 'distance_meters' and is_nullable = 'YES'
  )
  and exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_workout_routine_sets'
      and column_name = 'duration_seconds' and is_nullable = 'YES'
  ),
  'atomic Create and nullable metric schema must both be installed'
);

insert into auth.users (id, email) values
  ('a5400000-0000-4000-8000-000000000001',
   'combined-w4-owner@example.test');
insert into public.user_workout_programs (id, user_id, name) values
  ('a5400000-0000-4000-8000-000000000011',
   'a5400000-0000-4000-8000-000000000001',
   'Combined W4 Program');

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a5400000-0000-4000-8000-000000000001',
  true
);

-- A reusable template needs Exercise + Set but need not invent Reps/Weight.
-- Treadmill holds canonical meters/seconds; plank holds seconds alone.
select pg_temp.assert_true(
  public.create_user_workout_routine_with_composition(
    'a5400000-0000-4000-8000-000000000021',
    'a5400000-0000-4000-8000-000000000011',
    'Optional targets',
    'a5400000-0000-4000-8000-000000000091',
    '[
      {"id":"a5400000-0000-4000-8000-000000000041",
       "exercise_ref":"ex_bench_press","sets":[
        {"id":"a5400000-0000-4000-8000-000000000051",
         "reps":null,"reps_max":null,"set_type":"normal",
         "load_kg":null,"distance_meters":null,
         "duration_seconds":null,"rest_seconds":null}]},
      {"id":"a5400000-0000-4000-8000-000000000042",
       "exercise_ref":"ex_walking_on_treadmill","sets":[
        {"id":"a5400000-0000-4000-8000-000000000052",
         "reps":null,"reps_max":null,"set_type":"normal",
         "load_kg":null,"distance_meters":2500.5,
         "duration_seconds":905,"rest_seconds":60}]},
      {"id":"a5400000-0000-4000-8000-000000000043",
       "exercise_ref":"ex_front_plank","sets":[
        {"id":"a5400000-0000-4000-8000-000000000053",
         "reps":null,"reps_max":null,"set_type":"normal",
         "load_kg":null,"distance_meters":null,
         "duration_seconds":65,"rest_seconds":null}]}
    ]'::jsonb
  ) = 1,
  'atomic Create must accept targetless Reps and typed metric Sets'
);

select pg_temp.assert_true(
  (select count(*) = 3
   from public.user_workout_routine_sets
   where user_id = 'a5400000-0000-4000-8000-000000000001')
  and (select reps is null and load_kg is null and
              distance_meters is null and duration_seconds is null
       from public.user_workout_routine_sets
       where id = 'a5400000-0000-4000-8000-000000000051')
  and (select reps is null and distance_meters = 2500.5 and
              duration_seconds = 905 and rest_seconds = 60
       from public.user_workout_routine_sets
       where id = 'a5400000-0000-4000-8000-000000000052')
  and (select reps is null and distance_meters is null and
              duration_seconds = 65
       from public.user_workout_routine_sets
       where id = 'a5400000-0000-4000-8000-000000000053'),
  'three Sets must retain nullable targets and exact canonical metrics'
);

-- The old Create migration delegates to the post-#540 Save RPC;
-- no Exercise can be created without at least one Set after the upgrade.
select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5400000-0000-4000-8000-000000000022',
    'a5400000-0000-4000-8000-000000000011',
    'No Set',
    'a5400000-0000-4000-8000-000000000092',
    '[{"id":"a5400000-0000-4000-8000-000000000044",
       "exercise_ref":"ex_bench_press","sets":[]}]'::jsonb
  )
$sql$, '22023', 'combined atomic Create rejects zero-Set Exercises');

select pg_temp.assert_true(
  not exists (
    select 1 from public.user_workout_routines
    where id = 'a5400000-0000-4000-8000-000000000022'
  ),
  'rejected Create must not leave orphan Routine metadata'
);


-- The limit must be enforced in PostgreSQL, not only by Flutter button state.
-- NOT VALID preserves historical over-limit rows until the user edits them.
select pg_temp.assert_true(
  exists(
    select 1 from pg_catalog.pg_constraint
    where conrelid = 'public.user_workout_routine_sets'::regclass
      and conname = 'user_workout_routine_sets_max_eight_position'
      and convalidated = false
  ),
  '8-Set per Exercise DB guard installed without historical rewrite'
);

-- Use a separate freshly created Routine for the cardinality test.
-- The prior Routine contains rich treadmill/plank measurements: the legacy
-- full-snapshot overwrite guard must continue protecting those values.
select pg_temp.assert_true(
  public.create_user_workout_routine_with_composition(
    'a5400000-0000-4000-8000-000000000024',
    'a5400000-0000-4000-8000-000000000011',
    'Eight Set Cap Fixture',
    'a5400000-0000-4000-8000-000000000096',
    '[{"id":"a5400000-0000-4000-8000-000000000047",
       "exercise_ref":"ex_bench_press","sets":[
       {"id":"a5400000-0000-4000-8000-000000000054",
        "reps":8,"set_type":"normal"}]}]'::jsonb
  ) = 1, 'isolated ordinary Routine starts at revision one'
);

-- Existing owner can save exactly eight Sets in a single Exercise.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5400000-0000-4000-8000-000000000024', 1,
    'a5400000-0000-4000-8000-000000000093',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'id', 'a5400000-0000-4000-8000-000000000047',
      'exercise_ref', 'ex_bench_press',
      'sets', (
        select pg_catalog.jsonb_agg(
          pg_catalog.jsonb_build_object(
            'id', 'a5400000-0000-4000-8000-' ||
                  pg_catalog.lpad(i::text, 12, '0'),
            'reps', 8
          ) order by i
        ) from pg_catalog.generate_series(1,8) as i
      )
    ))
  ) = 2,
  'eight Sets are valid in Save'
);
select pg_temp.assert_true(
  (select count(*) = 8 from public.user_workout_routine_sets
   where routine_exercise_id = 'a5400000-0000-4000-8000-000000000047'),
  'eight Set rows persist'
);

-- A ninth Set is rejected even if an outdated client bypasses Add Set UI.
select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5400000-0000-4000-8000-000000000024', 2,
    'a5400000-0000-4000-8000-000000000094',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'id', 'a5400000-0000-4000-8000-000000000047',
      'exercise_ref', 'ex_bench_press',
      'sets', (
        select pg_catalog.jsonb_agg(
          pg_catalog.jsonb_build_object(
            'id', 'a5400000-0000-4000-8000-' ||
                  pg_catalog.lpad(i::text, 12, '0'),
            'reps', 8
          ) order by i
        ) from pg_catalog.generate_series(1,9) as i
      )
    ))
  )
$sql$, '23514', 'Save must reject ninth Set under CHECK constraint');

select pg_temp.assert_true(
  (select composition_revision = 2
   from public.user_workout_routines
   where id = 'a5400000-0000-4000-8000-000000000024')
  and (select count(*) = 8 from public.user_workout_routine_sets
       where routine_exercise_id = 'a5400000-0000-4000-8000-000000000047'),
  'rejected ninth Set leaves existing Save atomic and unchanged'
);

select pg_temp.assert_raises($sql$
  select public.create_user_workout_routine_with_composition(
    'a5400000-0000-4000-8000-000000000023',
    'a5400000-0000-4000-8000-000000000011',
    'Too many Sets',
    'a5400000-0000-4000-8000-000000000095',
    pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'id', 'a5400000-0000-4000-8000-000000000046',
      'exercise_ref', 'ex_bench_press',
      'sets', (
        select pg_catalog.jsonb_agg(
          pg_catalog.jsonb_build_object(
            'id', 'a5400000-0000-4000-8000-' ||
                  pg_catalog.lpad((i+100)::text, 12, '0'),
            'reps', 8
          ) order by i
        ) from pg_catalog.generate_series(1,9) as i
      )
    ))
  )
$sql$, '23514', 'Atomic Create rejects ninth Set');

select pg_temp.assert_true(
  not exists(
    select 1 from public.user_workout_routines
    where id = 'a5400000-0000-4000-8000-000000000023'
  ),
  'rejected over-limit Create leaves no partial Routine'
);

rollback;
