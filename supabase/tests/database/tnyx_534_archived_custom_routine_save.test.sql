\set ON_ERROR_STOP on
-- GitHub #534. Disposable SQL/RLS matrix; every mutation rolls back.
-- Requires checked-in #536, #540, and #534 migrations in this order.
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
    raise exception 'assertion failed: %, expected %, got %',
      message, state, actual;
  end;
  raise exception 'assertion failed: % unexpectedly succeeded', message;
end;
$$;


-- Exercise the #540 nullable metric Set contract through the #534 lifecycle
-- gate: historical targetless Reps + distance/duration must remain identical.
create function pg_temp.metric_archive_payload(
  p_catalog_reps integer, p_distance double precision
) returns jsonb language sql as $$
  select pg_catalog.jsonb_build_array(
    pg_catalog.jsonb_build_object(
      'id', 'a5340000-0000-4000-8000-000000000046',
      'exercise_ref', 'a5340000-0000-4000-8000-000000000034',
      'sets', pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'id', 'a5340000-0000-4000-8000-000000000056',
        'reps', null::integer, 'reps_max', null::integer,
        'set_type', 'normal', 'load_kg', null::double precision,
        'distance_meters', p_distance, 'duration_seconds', 900,
        'rest_seconds', 60
      ))
    ),
    pg_catalog.jsonb_build_object(
      'id', 'a5340000-0000-4000-8000-000000000047',
      'exercise_ref', 'ex_bench_press',
      'sets', pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'id', 'a5340000-0000-4000-8000-000000000057',
        'reps', p_catalog_reps, 'reps_max', null::integer,
        'set_type', 'normal', 'load_kg', 30.0::double precision,
        'distance_meters', null::double precision,
        'duration_seconds', null::integer, 'rest_seconds', 90
      ))
    )
  );
$$;

select pg_temp.assert_true(
  has_function_privilege('authenticated',
    'public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)', 'EXECUTE')
  and not has_function_privilege('anon',
    'public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)', 'EXECUTE')
  and (select p.prosecdef and p.proconfig @> array['search_path=""']
    from pg_proc p where p.oid =
      'public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)'::regprocedure),
  'Save RPC retains narrow authenticated SECURITY DEFINER grant and empty search_path'
);

insert into auth.users (id, email) values
 ('a5340000-0000-4000-8000-000000000001','issue534-a@example.test'),
 ('a5340000-0000-4000-8000-000000000002','issue534-b@example.test');

insert into public.user_workout_programs (id, user_id, name) values
 ('a5340000-0000-4000-8000-000000000011','a5340000-0000-4000-8000-000000000001','Program A');

insert into public.user_workout_routines (id, user_id, program_id, name) values
 ('a5340000-0000-4000-8000-000000000021','a5340000-0000-4000-8000-000000000001','a5340000-0000-4000-8000-000000000011','Routine A'),
 ('a5340000-0000-4000-8000-000000000022','a5340000-0000-4000-8000-000000000001','a5340000-0000-4000-8000-000000000011','Nullable Metric Routine');

insert into public.user_workout_exercises (id,user_id,display_name,status) values
 ('a5340000-0000-4000-8000-000000000031','a5340000-0000-4000-8000-000000000001','Archive Later','active'),
 ('a5340000-0000-4000-8000-000000000032','a5340000-0000-4000-8000-000000000001','Still Active','active'),
 ('a5340000-0000-4000-8000-000000000033','a5340000-0000-4000-8000-000000000002','Foreign Owner','active'),
 ('a5340000-0000-4000-8000-000000000034','a5340000-0000-4000-8000-000000000001','Metric Custom','active');

set local role authenticated;
select set_config('request.jwt.claim.sub','a5340000-0000-4000-8000-000000000001',true);

-- Initial active Save; two ordered Sets preserve UUIDs, values and order.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',0,
    'a5340000-0000-4000-8000-000000000091',
    '[
      {"id":"a5340000-0000-4000-8000-000000000041",
       "exercise_ref":"a5340000-0000-4000-8000-000000000031","sets":[
         {"id":"a5340000-0000-4000-8000-000000000051","reps":8,"load_kg":12},
         {"id":"a5340000-0000-4000-8000-000000000052","reps":10,"load_kg":15}]},
      {"id":"a5340000-0000-4000-8000-000000000042",
       "exercise_ref":"ex_bench_press","sets":[
         {"id":"a5340000-0000-4000-8000-000000000053","reps":10,"load_kg":20}]}
    ]'::jsonb
  ) = 1,
  'active owner Custom + catalog entry can commit'
);

update public.user_workout_exercises
set status='archived'
where id='a5340000-0000-4000-8000-000000000031'
  and user_id='a5340000-0000-4000-8000-000000000001';

select pg_temp.assert_true(
  (select status='archived' from public.user_workout_exercises
   where id='a5340000-0000-4000-8000-000000000031'),
  'owner archive actually changed the Custom lifecycle'
);

-- The exact acknowledged mutation, replayed after archive, must still
-- return the original revision. New lifecycle checks MUST run afterwards.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',0,
    'a5340000-0000-4000-8000-000000000091',
    '[
      {"id":"a5340000-0000-4000-8000-000000000041",
       "exercise_ref":"a5340000-0000-4000-8000-000000000031","sets":[
         {"id":"a5340000-0000-4000-8000-000000000051","reps":8,"load_kg":12},
         {"id":"a5340000-0000-4000-8000-000000000052","reps":10,"load_kg":15}]},
      {"id":"a5340000-0000-4000-8000-000000000042",
       "exercise_ref":"ex_bench_press","sets":[
         {"id":"a5340000-0000-4000-8000-000000000053","reps":10,"load_kg":20}]}
    ]'::jsonb
  ) = 1,
  'same-token replay remains idempotent even after archive'
);

select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',0,
    'a5340000-0000-4000-8000-000000000091',
    '[{"id":"a5340000-0000-4000-8000-000000000041",
       "exercise_ref":"a5340000-0000-4000-8000-000000000031",
       "sets":[{"id":"a5340000-0000-4000-8000-000000000051","reps":9}]}]'::jsonb
  )
$sql$, 'P0001', 'same mutation with changed payload must conflict before archived policy');

-- Archived entry unchanged (including both Sets), but unrelated catalog
-- Set changed and Routine entry order reversed. That must be allowed.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',1,
    'a5340000-0000-4000-8000-000000000092',
    '[
      {"id":"a5340000-0000-4000-8000-000000000042",
       "exercise_ref":"ex_bench_press","sets":[
         {"id":"a5340000-0000-4000-8000-000000000053","reps":12,"load_kg":20}]},
      {"id":"a5340000-0000-4000-8000-000000000041",
       "exercise_ref":"a5340000-0000-4000-8000-000000000031","sets":[
         {"id":"a5340000-0000-4000-8000-000000000051","reps":8,"load_kg":12},
         {"id":"a5340000-0000-4000-8000-000000000052","reps":10,"load_kg":15}]}
    ]'::jsonb
  ) = 2,
  'unchanged archived entry permits unrelated Edit and Routine reordering'
);

select pg_temp.assert_true(
  (select position = 1 from public.user_workout_routine_exercises
    where id='a5340000-0000-4000-8000-000000000041')
  and (select position=0 and reps=8 and load_kg=12
      from public.user_workout_routine_sets
      where id='a5340000-0000-4000-8000-000000000051')
  and (select position=1 and reps=10 and load_kg=15
      from public.user_workout_routine_sets
      where id='a5340000-0000-4000-8000-000000000052'),
  'archived entry UUID and ordered original Set identities/values survived'
);

-- Modified archived prescription is forbidden; cannot silently rewrite.
select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',2,
    'a5340000-0000-4000-8000-000000000093',
    '[
      {"id":"a5340000-0000-4000-8000-000000000042",
       "exercise_ref":"ex_bench_press","sets":[
         {"id":"a5340000-0000-4000-8000-000000000053","reps":13,"load_kg":20}]},
      {"id":"a5340000-0000-4000-8000-000000000041",
       "exercise_ref":"a5340000-0000-4000-8000-000000000031","sets":[
         {"id":"a5340000-0000-4000-8000-000000000051","reps":9,"load_kg":12},
         {"id":"a5340000-0000-4000-8000-000000000052","reps":10,"load_kg":15}]}
    ]'::jsonb
  )
$sql$, '22023', 'changing archived Set targets must be rejected'
);

-- Even same values with reversed archived Set order are not unchanged.
select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',2,
    'a5340000-0000-4000-8000-000000000094',
    '[
      {"id":"a5340000-0000-4000-8000-000000000042",
       "exercise_ref":"ex_bench_press","sets":[
         {"id":"a5340000-0000-4000-8000-000000000053","reps":12,"load_kg":20}]},
      {"id":"a5340000-0000-4000-8000-000000000041",
       "exercise_ref":"a5340000-0000-4000-8000-000000000031","sets":[
         {"id":"a5340000-0000-4000-8000-000000000052","reps":10,"load_kg":15},
         {"id":"a5340000-0000-4000-8000-000000000051","reps":8,"load_kg":12}]}
    ]'::jsonb
  )
$sql$, '22023', 'reordering archived Sets must fail'
);

-- New ID is a new entry even when the archived ref is identical.
select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',2,
    'a5340000-0000-4000-8000-000000000095',
    '[
      {"id":"a5340000-0000-4000-8000-000000000042",
       "exercise_ref":"ex_bench_press","sets":[
         {"id":"a5340000-0000-4000-8000-000000000053","reps":12,"load_kg":20}]},
      {"id":"a5340000-0000-4000-8000-000000000045",
       "exercise_ref":"a5340000-0000-4000-8000-000000000031","sets":[
         {"id":"a5340000-0000-4000-8000-000000000054","reps":8}]}
    ]'::jsonb
  )
$sql$, '22023', 'newly introduced archived Custom ref must fail'
);

-- Same original entry ID cannot be reassigned to another archived ref.
update public.user_workout_exercises
set status='archived'
where id='a5340000-0000-4000-8000-000000000032'
  and user_id='a5340000-0000-4000-8000-000000000001';

select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',2,
    'a5340000-0000-4000-8000-000000000096',
    '[
      {"id":"a5340000-0000-4000-8000-000000000042",
       "exercise_ref":"ex_bench_press","sets":[
         {"id":"a5340000-0000-4000-8000-000000000053","reps":12,"load_kg":20}]},
      {"id":"a5340000-0000-4000-8000-000000000041",
       "exercise_ref":"a5340000-0000-4000-8000-000000000032","sets":[
         {"id":"a5340000-0000-4000-8000-000000000051","reps":8,"load_kg":12},
         {"id":"a5340000-0000-4000-8000-000000000052","reps":10,"load_kg":15}]}
    ]'::jsonb
  )
$sql$, '22023', 'archived Exercise ref swapping using old entry ID fails'
);

select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',2,
    'a5340000-0000-4000-8000-000000000097',
    '[{"id":"a5340000-0000-4000-8000-000000000044",
       "exercise_ref":"a5340000-0000-4000-8000-000000000033",
       "sets":[{"id":"a5340000-0000-4000-8000-000000000055","reps":6}]}]'::jsonb
  )
$sql$, 'P0002', 'foreign Custom Exercise must fail indistinguishably from missing'
);

select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',2,
    'a5340000-0000-4000-8000-000000000098',
    '[{"id":"a5340000-0000-4000-8000-000000000044",
       "exercise_ref":"a5340000-0000-4000-8000-000000000099",
       "sets":[{"id":"a5340000-0000-4000-8000-000000000055","reps":6}]}]'::jsonb
  )
$sql$, 'P0002', 'missing Custom Exercise returns same not-found error'
);

select pg_temp.assert_true(
  (select composition_revision=2 and last_composition_mutation_id =
    'a5340000-0000-4000-8000-000000000092'
   from public.user_workout_routines
   where id='a5340000-0000-4000-8000-000000000021')
  and (select count(*)=2 from public.user_workout_routine_exercises
       where routine_id='a5340000-0000-4000-8000-000000000021'),
  'all rejected writes left revision and existing children unchanged'
);

-- Archived entry removal is allowed; no inherited custom ID is retained.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000021',2,
    'a5340000-0000-4000-8000-000000000101',
    '[{"id":"a5340000-0000-4000-8000-000000000042",
       "exercise_ref":"ex_bench_press","sets":[
         {"id":"a5340000-0000-4000-8000-000000000053","reps":12,"load_kg":20}]}]'::jsonb
  ) = 3,
  'archived entry can be removed while preserving other entries'
);

select pg_temp.assert_true(
  not exists (select 1 from public.user_workout_routine_exercises
    where id='a5340000-0000-4000-8000-000000000041')
  and (select count(*)=1 from public.user_workout_routine_exercises
      where routine_id='a5340000-0000-4000-8000-000000000021'),
  'archived entry and its Sets were removed, other composition survived'
);


-- #534 + #540: unchanged archived metric Sets with reps=NULL remain
-- retainable while an unrelated Set changes, without converting targets.
select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000022', 0,
    'a5340000-0000-4000-8000-000000000110',
    pg_temp.metric_archive_payload(10, 1500)
  ) = 1,
  'active metric Custom allows nullable Reps with distance and duration'
);

update public.user_workout_exercises set status='archived'
where id='a5340000-0000-4000-8000-000000000034'
  and user_id='a5340000-0000-4000-8000-000000000001';

select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000022', 0,
    'a5340000-0000-4000-8000-000000000110',
    pg_temp.metric_archive_payload(10, 1500)
  ) = 1,
  'same-token nullable metric replay remains valid after archive'
);

select pg_temp.assert_true(
  public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000022', 1,
    'a5340000-0000-4000-8000-000000000111',
    pg_temp.metric_archive_payload(12, 1500)
  ) = 2,
  'unchanged archived nullable Set can coexist with unrelated catalog edit'
);

select pg_temp.assert_raises($sql$
  select public.save_user_workout_routine_composition(
    'a5340000-0000-4000-8000-000000000022', 2,
    'a5340000-0000-4000-8000-000000000112',
    pg_temp.metric_archive_payload(12, 1600)
  )
$sql$, '22023', 'archived nullable metric target change must be rejected');

select pg_temp.assert_true(
  (select composition_revision = 2 from public.user_workout_routines
   where id='a5340000-0000-4000-8000-000000000022')
  and (select reps is null and distance_meters = 1500
              and duration_seconds = 900 and rest_seconds = 60
       from public.user_workout_routine_sets
       where id='a5340000-0000-4000-8000-000000000056')
  and (select reps = 12 from public.user_workout_routine_sets
       where id='a5340000-0000-4000-8000-000000000057')
  and (select count(*) = 2 from public.user_workout_routine_exercises
       where routine_id='a5340000-0000-4000-8000-000000000022'),
  'rejected archived metric edit preserves revision and both ordered entries'
);

rollback;
