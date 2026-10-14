\set ON_ERROR_STOP on
-- GitHub #538/#539: disposable migration/replay/ownership/legacy compatibility.
begin;

create function pg_temp.assert_true(ok boolean, message text)
returns void language plpgsql as $$
begin
  if ok is not true then raise exception 'assertion failed: %', message; end if;
end;
$$;
create function pg_temp.assert_raises(sql text, state text, message text)
returns void language plpgsql as $$
declare received text;
begin
  begin
    execute sql;
  exception when others then
    get stacked diagnostics received = returned_sqlstate;
    if received = state then return; end if;
    raise exception 'assertion failed: %; expected %, got %', message, state, received;
  end;
  raise exception 'assertion failed: %; write unexpectedly succeeded', message;
end;
$$;

select pg_temp.assert_true(
  exists (select 1 from information_schema.columns
          where table_schema='public' and table_name='user_workout_routine_sets'
            and column_name='set_type' and column_default like '%normal%')
  and exists (select 1 from information_schema.columns
          where table_schema='public' and table_name='user_workout_routine_sets'
            and column_name='reps_max' and is_nullable='YES')
  and has_table_privilege('authenticated','public.user_workout_routine_sets','SELECT')
  and not has_table_privilege('authenticated','public.user_workout_routine_sets','INSERT')
  and not has_table_privilege('authenticated','public.user_workout_routine_sets','UPDATE')
  and not has_table_privilege('authenticated','public.user_workout_routine_sets','DELETE'),
  'schema defaults + owner read-only child grants'
);

insert into auth.users(id,email) values
 ('a5380000-0000-4000-8000-000000000001','issue538-a@example.test'),
 ('a5380000-0000-4000-8000-000000000002','issue538-b@example.test');
insert into public.user_workout_programs(id,user_id,name) values
 ('a5380000-0000-4000-8000-000000000011','a5380000-0000-4000-8000-000000000001','Program A'),
 ('a5380000-0000-4000-8000-000000000012','a5380000-0000-4000-8000-000000000002','Program B');
insert into public.user_workout_routines(id,user_id,program_id,name) values
 ('a5380000-0000-4000-8000-000000000021','a5380000-0000-4000-8000-000000000001','a5380000-0000-4000-8000-000000000011','Routine A'),
 ('a5380000-0000-4000-8000-000000000022','a5380000-0000-4000-8000-000000000002','a5380000-0000-4000-8000-000000000012','Routine B');

set local role authenticated;
select set_config('request.jwt.claim.sub','a5380000-0000-4000-8000-000000000001',true);

-- Existing clients can still create fixed/Normal Routines without new keys.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000021',0,
   'a5380000-0000-4000-8000-000000000091',
   '[{"id":"a5380000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_bench_press","sets":[
      {"id":"a5380000-0000-4000-8000-000000000051",
       "reps":10,"load_kg":20,"rest_seconds":30}]}]'::jsonb
  ) = 1, 'legacy fixed Reps Save'
);
select pg_temp.assert_true(
  (select set_type='normal' and reps=10 and reps_max is null
   from public.user_workout_routine_sets where id='a5380000-0000-4000-8000-000000000051'),
  'legacy write uses Normal/default/no range'
);
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000021',0,
   'a5380000-0000-4000-8000-000000000091',
   '[{"id":"a5380000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_bench_press","sets":[
      {"id":"a5380000-0000-4000-8000-000000000051",
       "reps":10,"load_kg":20,"rest_seconds":30}]}]'::jsonb
  ) = 1, 'legacy same-token idempotency remains stable'
);

-- New client sends explicit per-Set type and reps_max; all Sets in one
-- Exercise have same fixed-vs-range mode even with different Set types.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000021',1,
   'a5380000-0000-4000-8000-000000000092',
   '[{"id":"a5380000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_bench_press","sets":[
      {"id":"a5380000-0000-4000-8000-000000000051",
       "reps":8,"reps_max":12,"set_type":"warm_up","load_kg":20,"rest_seconds":30},
      {"id":"a5380000-0000-4000-8000-000000000052",
       "reps":6,"reps_max":10,"set_type":"failure","load_kg":null,"rest_seconds":null},
      {"id":"a5380000-0000-4000-8000-000000000053",
       "reps":4,"reps_max":6,"set_type":"drop","load_kg":0,"rest_seconds":0}
      ]}]'::jsonb
  ) = 2, 'durable warm-up/failure/drop and range Save'
);
select pg_temp.assert_true(
  (select count(*)=3 from public.user_workout_routine_sets
   where user_id='a5380000-0000-4000-8000-000000000001')
  and (select set_type='warm_up' and reps=8 and reps_max=12
       and load_kg=20 and rest_seconds=30
       from public.user_workout_routine_sets
       where id='a5380000-0000-4000-8000-000000000051')
  and (select set_type='failure' and reps=6 and reps_max=10
       from public.user_workout_routine_sets
       where id='a5380000-0000-4000-8000-000000000052')
  and (select set_type='drop' and reps=4 and reps_max=6
       from public.user_workout_routine_sets
       where id='a5380000-0000-4000-8000-000000000053'),
  'all rich types and ranges persisted without changing Set UUIDs'
);

select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000021',1,
   'a5380000-0000-4000-8000-000000000092',
   '[{"id":"a5380000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_bench_press","sets":[
      {"id":"a5380000-0000-4000-8000-000000000051",
       "reps":8,"reps_max":12,"set_type":"warm_up","load_kg":20,"rest_seconds":30},
      {"id":"a5380000-0000-4000-8000-000000000052",
       "reps":6,"reps_max":10,"set_type":"failure","load_kg":null,"rest_seconds":null},
      {"id":"a5380000-0000-4000-8000-000000000053",
       "reps":4,"reps_max":6,"set_type":"drop","load_kg":0,"rest_seconds":0}
      ]}]'::jsonb
  ) = 2, 'rich same-token retry does not advance revision'
);
select pg_temp.assert_raises($sql$
 select public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000021',1,
   'a5380000-0000-4000-8000-000000000092',
   '[{"id":"a5380000-0000-4000-8000-000000000041",
   "exercise_ref":"ex_bench_press","sets":[
   {"id":"a5380000-0000-4000-8000-000000000051","reps":8,
   "reps_max":13,"set_type":"warm_up"}]}]'::jsonb)
$sql$,'P0001','same mutation with changed rich payload must conflict');

-- Old full-snapshot clients cannot erase rich type/range data.
select pg_temp.assert_raises($sql$
 select public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000021',2,
   'a5380000-0000-4000-8000-000000000093',
   '[{"id":"a5380000-0000-4000-8000-000000000041",
   "exercise_ref":"ex_bench_press","sets":[
   {"id":"a5380000-0000-4000-8000-000000000051","reps":10}]}]'::jsonb)
$sql$,'P0001','old client cannot overwrite rich Routine');
select pg_temp.assert_raises($sql$
 select public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000021',2,
   'a5380000-0000-4000-8000-000000000093','[]'::jsonb)
$sql$,'P0001','unversioned clear of rich Routine fails closed');

-- Strict validation and uniform Exercise-level mode.
select pg_temp.assert_raises($sql$
 select public.save_user_workout_routine_composition(
  'a5380000-0000-4000-8000-000000000021',2,
  'a5380000-0000-4000-8000-000000000093',
  '[{"id":"a5380000-0000-4000-8000-000000000041",
   "exercise_ref":"ex_bench_press","sets":[
   {"id":"a5380000-0000-4000-8000-000000000051",
    "reps":10,"reps_max":9,"set_type":"normal"}]}]'::jsonb)
$sql$,'22023','max must be >= min');
select pg_temp.assert_raises($sql$
 select public.save_user_workout_routine_composition(
  'a5380000-0000-4000-8000-000000000021',2,
  'a5380000-0000-4000-8000-000000000093',
  '[{"id":"a5380000-0000-4000-8000-000000000041",
   "exercise_ref":"ex_bench_press","sets":[
   {"id":"a5380000-0000-4000-8000-000000000051",
    "reps":8,"reps_max":10,"set_type":"normal"},
   {"id":"a5380000-0000-4000-8000-000000000052",
    "reps":8,"reps_max":null,"set_type":"normal"}]}]'::jsonb)
$sql$,'22023','mixed range/fixed modes rejected per Exercise');
select pg_temp.assert_raises($sql$
 select public.save_user_workout_routine_composition(
  'a5380000-0000-4000-8000-000000000021',2,
  'a5380000-0000-4000-8000-000000000093',
  '[{"id":"a5380000-0000-4000-8000-000000000041",
   "exercise_ref":"ex_bench_press","sets":[
   {"id":"a5380000-0000-4000-8000-000000000051",
    "reps":10,"reps_max":null,"set_type":"random"}]}]'::jsonb)
$sql$,'22023','invalid Set Type rejected');
select pg_temp.assert_raises($sql$
 select public.save_user_workout_routine_composition(
  'a5380000-0000-4000-8000-000000000021',2,
  'a5380000-0000-4000-8000-000000000093',
  '[{"id":"a5380000-0000-4000-8000-000000000041",
   "exercise_ref":"ex_bench_press","sets":[
   {"id":"a5380000-0000-4000-8000-000000000051",
    "reps":10,"reps_max":null,"set_type":null}]}]'::jsonb)
$sql$,'22023','explicit null Set Type must not default');

-- New rich-aware client can explicitly transition back to fixed Reps.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000021',2,
   'a5380000-0000-4000-8000-000000000094',
   '[{"id":"a5380000-0000-4000-8000-000000000041",
     "exercise_ref":"ex_bench_press","sets":[
      {"id":"a5380000-0000-4000-8000-000000000051",
       "reps":8,"reps_max":null,"set_type":"normal","load_kg":20,
       "distance_meters":null,"duration_seconds":null,"rest_seconds":30}
     ]}]'::jsonb
  ) = 3, 'new client can explicitly choose fixed Normal and delete other Sets'
);
select pg_temp.assert_true(
  (select set_type='normal' and reps_max is null
   from public.user_workout_routine_sets
   where id='a5380000-0000-4000-8000-000000000051')
  and (select count(*)=1 from public.user_workout_routine_sets
   where user_id='a5380000-0000-4000-8000-000000000001'),
  'new mode persisted, obsolete Sets removed atomically'
);

-- Three approved Routine template profiles, all without fabricated reps.
-- Stable IDs and exact canonical units survive Create/Save and retry.
create function pg_temp.metric_routine_snapshot()
returns jsonb language sql immutable as $sql$
  select '[{"id":"a5380000-0000-4000-8000-000000000041",
    "exercise_ref":"ex_bench_press","sets":[
    {"id":"a5380000-0000-4000-8000-000000000051",
     "reps":null,"reps_max":null,"set_type":"normal",
     "load_kg":null,"distance_meters":null,
     "duration_seconds":null,"rest_seconds":null}]},
    {"id":"a5380000-0000-4000-8000-000000000042",
     "exercise_ref":"ex_walking_on_treadmill","sets":[
    {"id":"a5380000-0000-4000-8000-000000000052",
     "reps":null,"reps_max":null,"set_type":"normal",
     "load_kg":null,"distance_meters":2500.5,
     "duration_seconds":905,"rest_seconds":60}]},
    {"id":"a5380000-0000-4000-8000-000000000043",
     "exercise_ref":"ex_front_plank","sets":[
    {"id":"a5380000-0000-4000-8000-000000000053",
     "reps":null,"reps_max":null,"set_type":"normal",
     "load_kg":null,"distance_meters":null,
     "duration_seconds":65,"rest_seconds":null}]}]'::jsonb
$sql$;

select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5380000-0000-4000-8000-000000000021',3,
    'a5380000-0000-4000-8000-000000000097',
    pg_temp.metric_routine_snapshot()
  ) = 4, 'optional Reps + distance/duration Sets persist'
);
select pg_temp.assert_true(
  (select count(*) = 3 from public.user_workout_routine_sets
   where user_id='a5380000-0000-4000-8000-000000000001')
  and (select reps is null and load_kg is null and distance_meters is null
         and duration_seconds is null
       from public.user_workout_routine_sets
       where id='a5380000-0000-4000-8000-000000000051')
  and (select reps is null and distance_meters=2500.5
         and duration_seconds=905 and rest_seconds=60
       from public.user_workout_routine_sets
       where id='a5380000-0000-4000-8000-000000000052')
  and (select reps is null and distance_meters is null and duration_seconds=65
       from public.user_workout_routine_sets
       where id='a5380000-0000-4000-8000-000000000053'),
  'no target value invented; meters/seconds round trip exactly'
);
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5380000-0000-4000-8000-000000000021',3,
    'a5380000-0000-4000-8000-000000000097',
    pg_temp.metric_routine_snapshot()
  ) = 4, 'exact rich nullable same-token replay remains idempotent'
);

-- A prior Reps-only/full snapshot cannot wipe richer target values.
select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5380000-0000-4000-8000-000000000021',4,
    'a5380000-0000-4000-8000-000000000098',
    '[{"id":"a5380000-0000-4000-8000-000000000042",
      "exercise_ref":"ex_walking_on_treadmill","sets":[
       {"id":"a5380000-0000-4000-8000-000000000052",
        "reps":12,"reps_max":null,"set_type":"normal","load_kg":null}
    ]}]'::jsonb
  )
$sql$, 'P0001', 'legacy Reps-only client cannot erase new Set targets');
select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5380000-0000-4000-8000-000000000021',4,
    'a5380000-0000-4000-8000-000000000098','[]'::jsonb
  )
$sql$, 'P0001', 'legacy clear cannot erase nullable and metric Set rows');

select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5380000-0000-4000-8000-000000000021',4,
    'a5380000-0000-4000-8000-000000000098',
    '[{"id":"a5380000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_front_plank","sets":[
       {"id":"a5380000-0000-4000-8000-000000000051",
        "reps":null,"reps_max":null,"distance_meters":-0.5}]}]'::jsonb
  )
$sql$, '22023', 'negative distance rejected');
select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5380000-0000-4000-8000-000000000021',4,
    'a5380000-0000-4000-8000-000000000098',
    '[{"id":"a5380000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_front_plank","sets":[
       {"id":"a5380000-0000-4000-8000-000000000051",
        "reps":null,"reps_max":null,"duration_seconds":3.5}]}]'::jsonb
  )
$sql$, '22023', 'fractional duration rejected');
select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5380000-0000-4000-8000-000000000021',4,
    'a5380000-0000-4000-8000-000000000098',
    '[{"id":"a5380000-0000-4000-8000-000000000041",
      "exercise_ref":"ex_bench_press","sets":[
       {"id":"a5380000-0000-4000-8000-000000000051",
        "reps":null,"reps_max":12}]}]'::jsonb
  )
$sql$, '22023', 'Rep Range Max requires positive Min');

-- Account isolation still enforced on the RPC and Data API.
select set_config('request.jwt.claim.sub','a5380000-0000-4000-8000-000000000002',true);
select pg_temp.assert_true(
  (select count(*)=0 from public.user_workout_routine_sets),
  'second authenticated user cannot read first user Sets'
);
select pg_temp.assert_raises($sql$
 select public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000021',3,
   'a5380000-0000-4000-8000-000000000095','[]'::jsonb)
$sql$,'P0002','other owner cannot replace Routine');
select pg_temp.assert_true(
 public.save_user_workout_routine_composition(
   'a5380000-0000-4000-8000-000000000022',0,
   'a5380000-0000-4000-8000-000000000096','[]'::jsonb
 )=1,'second owner may still save own normal empty composition'
);
reset role;
rollback;
