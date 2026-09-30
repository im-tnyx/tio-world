\set ON_ERROR_STOP on

begin;

create function pg_temp.assert_true(p_condition boolean, p_message text)
returns void language plpgsql as $$
begin
  if p_condition is not true then raise exception 'assertion failed: %', p_message; end if;
end;
$$;

create function pg_temp.assert_raises(p_sql text, p_expected_sqlstate text, p_message text)
returns void language plpgsql as $$
declare v_state text;
begin
  begin execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_expected_sqlstate then return; end if;
    raise exception 'assertion failed: % (expected %, got %)', p_message, p_expected_sqlstate, v_state;
  end;
  raise exception 'assertion failed: % (unexpected success)', p_message;
end;
$$;

select pg_temp.assert_true(
  (select count(*) = 12 from information_schema.columns
   where table_schema = 'public' and table_name = 'user_workout_exercises'),
  'exactly five columns are added to the seven-column W1B1 table'
);
select pg_temp.assert_true(
  (select count(*) = 4 from information_schema.columns
   where table_schema = 'public' and table_name = 'user_workout_exercises'
     and column_name in ('description','exercise_type','primary_muscle','primary_equipment')
     and data_type = 'text' and is_nullable = 'YES' and column_default is null),
  'all four scalars are nullable text without fabricated defaults'
);
select pg_temp.assert_true(
  (select udt_name = '_text' and is_nullable = 'NO' and column_default = '''{}''::text[]'
   from information_schema.columns where table_schema = 'public'
     and table_name = 'user_workout_exercises' and column_name = 'secondary_muscles'),
  'secondary muscles are a nonnull text array with empty default'
);
select pg_temp.assert_true(
  (select relrowsecurity from pg_class where oid = 'public.user_workout_exercises'::regclass),
  'RLS stays enabled'
);
select pg_temp.assert_true(
  (select count(*) = 3 and bool_and(
     roles = array['authenticated']::name[]
     and (cmd <> 'SELECT' or qual like '%auth.uid()%user_id%')
     and (cmd <> 'INSERT' or with_check like '%auth.uid()%user_id%')
     and (cmd <> 'UPDATE' or (qual like '%auth.uid()%user_id%' and with_check like '%auth.uid()%user_id%'))
   ) from pg_policies where schemaname = 'public' and tablename = 'user_workout_exercises'),
  'owner SELECT/INSERT/UPDATE policies stay intact without DELETE'
);
select pg_temp.assert_true(
  not has_table_privilege('authenticated','public.user_workout_exercises','INSERT')
  and not has_table_privilege('authenticated','public.user_workout_exercises','UPDATE')
  and not has_table_privilege('authenticated','public.user_workout_exercises','DELETE')
  and has_table_privilege('authenticated','public.user_workout_exercises','SELECT'),
  'authenticated table rights stay SELECT only'
);
select pg_temp.assert_true(
  not has_function_privilege('anon','private.valid_user_exercise_muscles(text,text[])','EXECUTE')
  and (select not prosecdef and provolatile = 'i' and proconfig = array['search_path=""']
       from pg_proc where oid = 'private.valid_user_exercise_muscles(text,text[])'::regprocedure),
  'validator is immutable invoker with empty search_path and no anonymous execution'
);
do $$
declare c text;
begin
  foreach c in array array['id','user_id','display_name','based_on_catalog_exercise_id',
    'description','exercise_type','primary_muscle','secondary_muscles','primary_equipment'] loop
    perform pg_temp.assert_true(has_column_privilege('authenticated','public.user_workout_exercises',c,'INSERT'), 'allowed INSERT: ' || c);
  end loop;
  foreach c in array array['display_name','status','description','exercise_type','primary_muscle','secondary_muscles','primary_equipment'] loop
    perform pg_temp.assert_true(has_column_privilege('authenticated','public.user_workout_exercises',c,'UPDATE'), 'allowed UPDATE: ' || c);
  end loop;
  foreach c in array array['id','user_id','based_on_catalog_exercise_id','created_at','updated_at'] loop
    perform pg_temp.assert_true(not has_column_privilege('authenticated','public.user_workout_exercises',c,'UPDATE'), 'immutable UPDATE: ' || c);
  end loop;
  foreach c in array array['status','created_at','updated_at'] loop
    perform pg_temp.assert_true(not has_column_privilege('authenticated','public.user_workout_exercises',c,'INSERT'), 'server-owned INSERT: ' || c);
  end loop;
end;
$$;

insert into auth.users (id,email) values
  ('a2640000-0000-4000-8000-000000001001','w3d2-owner-a@example.test'),
  ('a2640000-0000-4000-8000-000000001002','w3d2-owner-b@example.test');

set local role authenticated;
select set_config('request.jwt.claim.sub','a2640000-0000-4000-8000-000000001001',true);
insert into public.user_workout_exercises(id,user_id,display_name)
values ('a2640000-0000-4000-8000-000000002001','a2640000-0000-4000-8000-000000001001','Legacy shape');
select pg_temp.assert_true(
  (select description is null and exercise_type is null and primary_muscle is null
    and secondary_muscles = '{}'::text[] and primary_equipment is null and status = 'active'
   from public.user_workout_exercises where id = 'a2640000-0000-4000-8000-000000002001'),
  'name-only creation remains valid without fabricated definition'
);
insert into public.user_workout_exercises(
  id,user_id,display_name,based_on_catalog_exercise_id,description,exercise_type,primary_muscle,secondary_muscles,primary_equipment
) values (
  'a2640000-0000-4000-8000-000000002002','a2640000-0000-4000-8000-000000001001','Defined exercise',
  'ex_barbell_bench_press','Tempo focus','weight_reps','pectoralis_major_sternal_head',
  array['triceps_brachii','deltoid_anterior'],'barbell'
);
update public.user_workout_exercises set description = 'Updated',exercise_type = 'duration',
  primary_muscle = 'rectus_abdominis',secondary_muscles = array['obliques'],primary_equipment = 'bodyweight'
where id = 'a2640000-0000-4000-8000-000000002002';
select pg_temp.assert_true(
  (select description = 'Updated' and exercise_type = 'duration' and primary_muscle = 'rectus_abdominis'
    and secondary_muscles = array['obliques'] and primary_equipment = 'bodyweight'
    and based_on_catalog_exercise_id = 'ex_barbell_bench_press'
   from public.user_workout_exercises where id = 'a2640000-0000-4000-8000-000000002002'),
  'owner can read and replace the structured definition while preserving lineage'
);

do $$
declare field text; invalid text; immutable text;
begin
  for field,invalid in values
    ('description', quote_literal(E' \t\n ')),
    ('exercise_type', '''Weight & Reps'''),
    ('primary_muscle', '''1'''),
    ('primary_equipment', '''equipment'''),
    ('secondary_muscles', 'array[''obliques'',''obliques'']'),
    ('secondary_muscles', 'array[''rectus_abdominis'']'),
    ('secondary_muscles', 'array[''unknown'']'),
    ('secondary_muscles', 'array[null]::text[]'),
    ('secondary_muscles', 'array[[''obliques'']]'),
    ('secondary_muscles', '''[0:0]={obliques}''::text[]')
  loop
    perform pg_temp.assert_raises(format(
      'update public.user_workout_exercises set %I = %s where id = %L',
      field,invalid,'a2640000-0000-4000-8000-000000002002'), '23514', 'reject invalid ' || field || ': ' || invalid);
  end loop;
  perform pg_temp.assert_raises(
    'update public.user_workout_exercises set secondary_muscles = null', '23502', 'reject NULL secondary array');
  for field,immutable in values
    ('id','''a2640000-0000-4000-8000-000000009999'''),
    ('user_id','''a2640000-0000-4000-8000-000000001002'''),
    ('based_on_catalog_exercise_id','''ex_other'''),
    ('created_at','now()'),
    ('updated_at','now()')
  loop
    perform pg_temp.assert_raises(format('update public.user_workout_exercises set %I = %s',field,immutable),
      '42501','authenticated immutable-column denial: ' || field);
  end loop;
end;
$$;
select pg_temp.assert_raises($q$delete from public.user_workout_exercises$q$,'42501','authenticated DELETE is denied');
select pg_temp.assert_raises(
  $q$insert into public.user_workout_exercises(id,user_id,display_name,description)
     values ('a2640000-0000-4000-8000-000000002003','a2640000-0000-4000-8000-000000001002','Cross owner','Denied')$q$,
  '42501','cross-owner INSERT denied'
);

select set_config('request.jwt.claim.sub','a2640000-0000-4000-8000-000000001002',true);
select pg_temp.assert_true(
  (select count(*) = 0 from public.user_workout_exercises where user_id = 'a2640000-0000-4000-8000-000000001001'),
  'cross-owner SELECT hides definitions'
);
with changed as (
  update public.user_workout_exercises set description = 'Unauthorized'
  where id = 'a2640000-0000-4000-8000-000000002002' returning id
) select pg_temp.assert_true((select count(*) = 0 from changed),'cross-owner UPDATE affects zero rows');

reset role;
set local role service_role;
select pg_temp.assert_true(
  has_table_privilege('service_role','public.user_workout_exercises','SELECT,INSERT,UPDATE,DELETE'),
  'service role retains full CRUD'
);
select pg_temp.assert_true(
  (select description = 'Updated' from public.user_workout_exercises
   where id = 'a2640000-0000-4000-8000-000000002002'),'cross-owner update did not modify data'
);
insert into public.user_workout_exercises(id,user_id,display_name,description,exercise_type)
values ('a2640000-0000-4000-8000-000000002004','a2640000-0000-4000-8000-000000001002','Service owned','Service create','steps_duration');
update public.user_workout_exercises set description = null,exercise_type = null,primary_muscle = null,
  secondary_muscles = '{}',primary_equipment = null where id = 'a2640000-0000-4000-8000-000000002002';
delete from public.user_workout_exercises where id = 'a2640000-0000-4000-8000-000000002004';
select pg_temp.assert_true(
  (select description is null and exercise_type is null and primary_muscle is null
     and secondary_muscles = '{}' and primary_equipment is null
   from public.user_workout_exercises where id = 'a2640000-0000-4000-8000-000000002002'),
  'definition fields can be cleared without deleting identity'
);
reset role;
set local role anon;
select pg_temp.assert_raises($q$select * from public.user_workout_exercises$q$,'42501','anon cannot read user definitions');
reset role;

rollback;
