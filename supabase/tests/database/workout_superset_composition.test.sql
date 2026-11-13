\set ON_ERROR_STOP on

-- Superset Routine persistence, old-client guard, owner isolation and snapshot
-- compatibility. This test is intended for the disposable local CI database.
begin;

create function pg_temp.assert_true(p_ok boolean, p_message text)
returns void language plpgsql as $$
begin
  if p_ok is not true then
    raise exception 'assertion failed: %', p_message;
  end if;
end;
$$;

create function pg_temp.assert_raises(p_sql text, p_state text, p_message text)
returns void language plpgsql as $$
declare v_state text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics v_state = returned_sqlstate;
    if v_state = p_state then return; end if;
    raise exception 'assertion failed: % expected %, got %', p_message, p_state, v_state;
  end;
  raise exception 'assertion failed: % (operation succeeded)', p_message;
end;
$$;

select pg_temp.assert_true(
  to_regclass('public.user_workout_routine_supersets') is not null
  and exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_workout_routine_exercises'
      and column_name = 'superset_id'
  ),
  'Superset parent table and nullable member reference exist'
);

select pg_temp.assert_true(
  (select relrowsecurity from pg_class
   where oid = 'public.user_workout_routine_supersets'::regclass)
  and has_table_privilege(
    'authenticated', 'public.user_workout_routine_supersets', 'SELECT'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_routine_supersets', 'INSERT'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_routine_supersets', 'UPDATE'
  )
  and not has_table_privilege(
    'authenticated', 'public.user_workout_routine_supersets', 'DELETE'
  ),
  'Superset rows are owner-read and RPC-write only'
);

select pg_temp.assert_true(
  has_function_privilege(
    'authenticated',
    'public.save_user_workout_routine_composition_v2(uuid,bigint,uuid,jsonb)',
    'EXECUTE'
  ) and not has_function_privilege(
    'anon',
    'public.save_user_workout_routine_composition_v2(uuid,bigint,uuid,jsonb)',
    'EXECUTE'
  ),
  'only authenticated callers can reach the v2 composition RPC'
);

insert into auth.users (id, email) values
  ('d7ca0000-0000-4000-8000-000000000001','superset-a@example.test'),
  ('d7ca0000-0000-4000-8000-000000000002','superset-b@example.test');
insert into public.user_workout_programs (id, user_id, name) values
  ('d7ca0000-0000-4000-8000-000000000011','d7ca0000-0000-4000-8000-000000000001','Superset Program A'),
  ('d7ca0000-0000-4000-8000-000000000012','d7ca0000-0000-4000-8000-000000000002','Superset Program B');
insert into public.user_workout_routines (id, user_id, program_id, name) values
  ('d7ca0000-0000-4000-8000-000000000021','d7ca0000-0000-4000-8000-000000000001','d7ca0000-0000-4000-8000-000000000011','Routine A'),
  ('d7ca0000-0000-4000-8000-000000000023','d7ca0000-0000-4000-8000-000000000001','d7ca0000-0000-4000-8000-000000000011','Routine A Three'),
  ('d7ca0000-0000-4000-8000-000000000022','d7ca0000-0000-4000-8000-000000000002','d7ca0000-0000-4000-8000-000000000012','Routine B');

set local role authenticated;
select set_config('request.jwt.claim.sub','d7ca0000-0000-4000-8000-000000000001',true);

select pg_temp.assert_true(
  public.save_user_workout_routine_composition_v2(
    'd7ca0000-0000-4000-8000-000000000021', 0,
    'd7ca0000-0000-4000-8000-000000000091',
    '{"schema_version":2,"entries":[
      {"id":"d7ca0000-0000-4000-8000-000000000041","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000071","sets":[{"id":"d7ca0000-0000-4000-8000-000000000051","reps":10}]},
      {"id":"d7ca0000-0000-4000-8000-000000000042","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000071","sets":[{"id":"d7ca0000-0000-4000-8000-000000000052","reps":8},{"id":"d7ca0000-0000-4000-8000-000000000053","reps":6}]}
    ],"supersets":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":60,"warm_up_rest_seconds":null}]}'::jsonb
  ) = 1,
  'versioned save accepts two members with unequal set counts'
);

select pg_temp.assert_true(
  (select count(*) = 1 from public.user_workout_routine_supersets
   where routine_id = 'd7ca0000-0000-4000-8000-000000000021')
  and (select count(*) = 2 from public.user_workout_routine_exercises
       where routine_id = 'd7ca0000-0000-4000-8000-000000000021'
         and superset_id = 'd7ca0000-0000-4000-8000-000000000071')
  and (select normal_rest_seconds = 60 and warm_up_rest_seconds is null
       from public.user_workout_routine_supersets
       where id = 'd7ca0000-0000-4000-8000-000000000071'),
  'group timer pair and ordered memberships persist atomically'
);

select pg_temp.assert_true(
  public.save_user_workout_routine_composition_v2(
    'd7ca0000-0000-4000-8000-000000000021', 0,
    'd7ca0000-0000-4000-8000-000000000091',
    '{"schema_version":2,"entries":[
      {"id":"d7ca0000-0000-4000-8000-000000000041","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000071","sets":[{"id":"d7ca0000-0000-4000-8000-000000000051","reps":10}]},
      {"id":"d7ca0000-0000-4000-8000-000000000042","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000071","sets":[{"id":"d7ca0000-0000-4000-8000-000000000052","reps":8},{"id":"d7ca0000-0000-4000-8000-000000000053","reps":6}]}
    ],"supersets":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":60,"warm_up_rest_seconds":null}]}'::jsonb
  ) = 1,
  'same versioned mutation and group payload is idempotent'
);

select pg_temp.assert_true(
  public.save_user_workout_routine_composition_v2(
    'd7ca0000-0000-4000-8000-000000000023', 0,
    'd7ca0000-0000-4000-8000-000000000095',
    '{"schema_version":2,"entries":[
      {"id":"d7ca0000-0000-4000-8000-000000000061","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000072","sets":[{"id":"d7ca0000-0000-4000-8000-000000000062","reps":10}]},
      {"id":"d7ca0000-0000-4000-8000-000000000063","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000072","sets":[{"id":"d7ca0000-0000-4000-8000-000000000064","reps":8}]},
      {"id":"d7ca0000-0000-4000-8000-000000000065","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000072","sets":[{"id":"d7ca0000-0000-4000-8000-000000000066","reps":6}]}
    ],"supersets":[{"id":"d7ca0000-0000-4000-8000-000000000072","normal_rest_seconds":45,"warm_up_rest_seconds":15}]}'::jsonb
  ) = 1,
  'versioned save increments revision for a three-member Superset'
);

select pg_temp.assert_true(
  (select count(*) = 3 from public.user_workout_routine_exercises
   where routine_id = 'd7ca0000-0000-4000-8000-000000000023'
     and superset_id = 'd7ca0000-0000-4000-8000-000000000072'),
  'versioned save persists all three Superset members'
);

select pg_temp.assert_raises(
  $$select public.save_user_workout_routine_composition(
      'd7ca0000-0000-4000-8000-000000000021', 1,
      'd7ca0000-0000-4000-8000-000000000092', '[]'::jsonb)$$,
  'P0001', 'legacy Save cannot silently remove a grouped Routine'
);

select pg_temp.assert_raises(
  $$select public.update_user_workout_routine_with_composition(
      'd7ca0000-0000-4000-8000-000000000021',
      'd7ca0000-0000-4000-8000-000000000011', 1, 'Routine A',
      'd7ca0000-0000-4000-8000-000000000093', 'Routine A', '[]'::jsonb)$$,
  'P0001', 'legacy Update cannot silently remove a grouped Routine'
);

select pg_temp.assert_raises(
  $$select public.save_user_workout_routine_composition_v2(
      'd7ca0000-0000-4000-8000-000000000021', 1,
      'd7ca0000-0000-4000-8000-000000000094',
      '{"schema_version":2,"entries":[
        {"id":"d7ca0000-0000-4000-8000-000000000041","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000071","sets":[{"id":"d7ca0000-0000-4000-8000-000000000051","reps":10}]},
        {"id":"d7ca0000-0000-4000-8000-000000000042","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000071","sets":[{"id":"d7ca0000-0000-4000-8000-000000000052","reps":8}]},
        {"id":"d7ca0000-0000-4000-8000-000000000043","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000071","sets":[{"id":"d7ca0000-0000-4000-8000-000000000053","reps":6}]},
        {"id":"d7ca0000-0000-4000-8000-000000000044","exercise_ref":"ex_squat","superset_id":"d7ca0000-0000-4000-8000-000000000071","sets":[{"id":"d7ca0000-0000-4000-8000-000000000054","reps":4}]}
      ],"supersets":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":60,"warm_up_rest_seconds":null}]}'::jsonb)$$,
  '22023', 'fourth Superset member is rejected before persistence'
);

select pg_temp.assert_raises(
  $$select public.save_user_workout_routine_composition_v2(
      'd7ca0000-0000-4000-8000-000000000021', 1,
      'd7ca0000-0000-4000-8000-000000000096',
      '{"schema_version":"2","entries":[],"supersets":[]}'::jsonb)$$,
  '22023', 'versioned composition requires a numeric schema_version'
);

select pg_temp.assert_raises(
  $$insert into public.user_workout_routine_supersets
      (id,user_id,routine_id,normal_rest_seconds,warm_up_rest_seconds)
    values ('d7ca0000-0000-4000-8000-000000000099',
      'd7ca0000-0000-4000-8000-000000000001',
      'd7ca0000-0000-4000-8000-000000000021',60,null)$$,
  '42501', 'authenticated cannot directly insert Superset rows'
);

select set_config('request.jwt.claim.sub','d7ca0000-0000-4000-8000-000000000002',true);
select pg_temp.assert_true(
  (select count(*) = 0 from public.user_workout_routine_supersets),
  'another authenticated owner cannot read the first owner group'
);
reset role;

select pg_temp.assert_true(
  private.is_valid_workout_session_snapshot_v2(
    '{"schema_version":2,"origin":"ad_hoc","captured_at_utc":"2026-11-13T00:00:00Z","exercises":[
      {"exercise_ref":"ex_squat","display_name":"Squat","occurrence_index":0,"superset_id":"d7ca0000-0000-4000-8000-000000000071","prescribed_sets":[{"set_type":"normal","reps":10}]},
      {"exercise_ref":"ex_squat","display_name":"Squat","occurrence_index":1,"superset_id":"d7ca0000-0000-4000-8000-000000000071","prescribed_sets":[{"set_type":"normal","reps":8}]}
    ],"superset_groups":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":60,"warm_up_rest_seconds":null}]}'::jsonb
  )
  and private.is_valid_workout_session_snapshot_v2(
    '{"schema_version":2,"origin":"ad_hoc","captured_at_utc":"2026-11-13T00:00:00Z","exercises":[{"exercise_ref":"ex_squat","display_name":"Squat","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10}]}]}'::jsonb
  ),
  'new grouped and legacy ungrouped v2 snapshots remain valid'
);

select pg_temp.assert_true(
  not private.is_valid_workout_session_snapshot_v2(
    '{"schema_version":2,"origin":"ad_hoc","captured_at_utc":"2026-11-13T00:00:00Z","exercises":[
      {"exercise_ref":"ex_squat","display_name":"Squat","occurrence_index":0,"superset_id":"d7ca0000-0000-4000-8000-000000000071","prescribed_sets":[{"set_type":"normal","reps":10}]},
      {"exercise_ref":"ex_squat","display_name":"Squat","occurrence_index":1,"prescribed_sets":[{"set_type":"normal","reps":8}]},
      {"exercise_ref":"ex_squat","display_name":"Squat","occurrence_index":2,"superset_id":"d7ca0000-0000-4000-8000-000000000071","prescribed_sets":[{"set_type":"normal","reps":6}]}
    ],"superset_groups":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":60,"warm_up_rest_seconds":null}]}'::jsonb
  )
  and not private.is_valid_workout_session_snapshot_v2(
    '{"schema_version":2,"origin":"ad_hoc","captured_at_utc":"2026-11-13T00:00:00Z","exercises":[
      {"exercise_ref":"ex_squat","display_name":"Squat","occurrence_index":0,"superset_id":"d7ca0000-0000-4000-8000-000000000071","prescribed_sets":[{"set_type":"normal","reps":10}]},
      {"exercise_ref":"ex_squat","display_name":"Squat","occurrence_index":1,"superset_id":"d7ca0000-0000-4000-8000-000000000071","prescribed_sets":[{"set_type":"normal","reps":8}]}
    ],"superset_groups":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":605,"warm_up_rest_seconds":null}]}'::jsonb
  ),
  'snapshot validation rejects non-contiguous members and unsupported rest values'
);

select pg_temp.assert_true(
  private.workout_snapshot_superset_groups_match(
    '{"superset_groups":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":60,"warm_up_rest_seconds":null}],"exercises":[{"superset_id":"d7ca0000-0000-4000-8000-000000000071"},{"superset_id":"d7ca0000-0000-4000-8000-000000000071"}]}'::jsonb,
    '{"superset_groups":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":60,"warm_up_rest_seconds":null}],"exercises":[{"superset_id":"d7ca0000-0000-4000-8000-000000000071"},{"superset_id":"d7ca0000-0000-4000-8000-000000000071"}]}'::jsonb
  )
  and private.workout_snapshot_superset_groups_match(
    '{"superset_groups":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":60,"warm_up_rest_seconds":null}],"exercises":[{"superset_id":"d7ca0000-0000-4000-8000-000000000071"},{"superset_id":"d7ca0000-0000-4000-8000-000000000071"}]}'::jsonb,
    '{"superset_groups":[],"exercises":[{},{}]}'::jsonb
  )
  and not private.workout_snapshot_superset_groups_match(
    '{"superset_groups":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":60,"warm_up_rest_seconds":null}],"exercises":[{"superset_id":"d7ca0000-0000-4000-8000-000000000071"},{"superset_id":"d7ca0000-0000-4000-8000-000000000071"}]}'::jsonb,
    '{"superset_groups":[{"id":"d7ca0000-0000-4000-8000-000000000071","normal_rest_seconds":90,"warm_up_rest_seconds":null}],"exercises":[{"superset_id":"d7ca0000-0000-4000-8000-000000000071"},{"superset_id":"d7ca0000-0000-4000-8000-000000000071"}]}'::jsonb
  ),
  'History Edit retains shared timer config and drops it only when the group dissolves'
);

rollback;
