\set ON_ERROR_STOP on
BEGIN;
SET LOCAL TIME ZONE 'America/Los_Angeles';
CREATE EXTENSION IF NOT EXISTS pgtap SCHEMA extensions;
SELECT plan(41);

INSERT INTO auth.users (id,email) VALUES
  ('11111111-1111-1111-1111-111111111111','save_owner@tio.test'),
  ('22222222-2222-2222-2222-222222222222','save_other@tio.test')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.users (id,email) VALUES
  ('11111111-1111-1111-1111-111111111111','save_owner@tio.test'),
  ('22222222-2222-2222-2222-222222222222','save_other@tio.test')
ON CONFLICT (id) DO NOTHING;

CREATE TEMP TABLE w7c_save_fixture (payload jsonb);
INSERT INTO w7c_save_fixture VALUES ($payload$
{
  "started_at_utc":"2026-11-07T21:00:00Z",
  "completed_at_utc":"2026-11-07T22:00:00Z",
  "accumulated_paused_microseconds":60000000,
  "workout_title":"Night Workout",
  "workout_at_utc":"2026-11-07T21:30:00Z",
  "workout_utc_offset_minutes":330,
  "description":"  Good effort  ",
  "activity_type":"Weight Training",
  "gym_name":"Test Gym",
  "overall_rpe":7.5,
  "selected_duration_seconds":3600,
  "routine_snapshot":{
    "schema_version":2,
    "origin":"ad_hoc",
    "captured_at_utc":"2026-11-07T21:00:00Z",
    "exercises":[{
      "exercise_ref":"ex_barbell_bench_press",
      "display_name":"Bench Press",
      "exercise_type":"weight_reps",
      "occurrence_index":0,
      "prescribed_sets":[{"set_type":"normal","performed_rpe":7.5}]
    }]
  },
  "performed_sets":[{
    "exercise_ref":"ex_barbell_bench_press",
    "exercise_index":0,
    "set_index":0,
    "reps":8,
    "load_kg":50.0,
    "completed_at_utc":"2026-11-07T21:40:00Z",
    "is_skipped":false
  }]
}
$payload$::jsonb);
GRANT SELECT ON w7c_save_fixture TO authenticated;

SELECT is(has_function_privilege('authenticated',
  'public.rpc_save_workout_session_v1(uuid,uuid,integer,jsonb)','EXECUTE'),
  true, 'only authenticated clients receive Save execution');
SELECT is(has_function_privilege('anon',
  'public.rpc_save_workout_session_v1(uuid,uuid,integer,jsonb)','EXECUTE'),
  false, 'anonymous clients cannot execute Save');
SELECT is(has_table_privilege('authenticated','public.user_workout_sessions','INSERT'),
  false, 'clients cannot insert a session outside Save RPC');
SELECT is(has_table_privilege('authenticated','public.user_workout_performed_sets','INSERT'),
  false, 'clients cannot insert performed sets outside Save RPC');

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
SELECT lives_ok($save$
  SELECT public.rpc_save_workout_session_v1(
    'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa', null, null,
    (SELECT payload FROM pg_temp.w7c_save_fixture))
$save$, 'one atomic Save creates a completed ad-hoc workout');
SELECT is((SELECT status FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  'completed','canonical session is terminal');
SELECT is((SELECT revision FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  2,'completion writes one revision');
SELECT is((SELECT local_date FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  '2026-11-08'::date,'selected +330 local date is timezone-independent');
SELECT is((SELECT workout_title FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  'Night Workout','resolved title is readable');
SELECT is((SELECT workout_duration_seconds FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  3600,'selected duration is distinct from canonical elapsed time');
SELECT is((SELECT notes FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  'Good effort','Save description is persisted');
SELECT is((SELECT routine_snapshot #>> '{exercises,0,prescribed_sets,0,set_type}'
           FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  'normal','Set Type remains in canonical snapshot readback');
SELECT is((SELECT (routine_snapshot #>> '{exercises,0,prescribed_sets,0,performed_rpe}')::numeric
           FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  7.5::numeric,'Set RPE remains in canonical snapshot readback');
SELECT is((SELECT count(*)::integer FROM public.user_workout_performed_sets p
           JOIN public.user_workout_sessions s ON s.id=p.session_id
           WHERE s.save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'
             AND p.reps=8 AND p.load_kg=50 AND p.notes IS NULL),
  1,'performed measurements persist without per-exercise notes');
SELECT lives_ok($retry$
  SELECT public.rpc_save_workout_session_v1(
    'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa', null, null,
    (SELECT payload FROM pg_temp.w7c_save_fixture))
$retry$, 'identical Save retry returns the completed session');
SELECT is((SELECT count(*)::integer FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  1,'identical retry does not duplicate history');
SELECT throws_ok($conflict$
  SELECT public.rpc_save_workout_session_v1(
    'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa', null, null,
    (SELECT jsonb_set(payload,'{workout_title}','"Changed"'::jsonb)
     FROM pg_temp.w7c_save_fixture))
$conflict$,'23505','save_request_payload_conflict',
  'same request key with changed title is rejected');
SELECT throws_ok($invalid$
  SELECT public.rpc_save_workout_session_v1(
    'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb', null, null,
    (SELECT jsonb_set(payload,'{performed_sets,0,reps}','1000'::jsonb)
     FROM pg_temp.w7c_save_fixture))
$invalid$,'22023','invalid_performed_set','invalid actual reps cannot commit');
SELECT is((SELECT count(*)::integer FROM public.user_workout_sessions
           WHERE save_request_id='bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb'),
  0,'failed Save leaves no session row');
SELECT throws_ok($invalid_snapshot$
  SELECT public.rpc_save_workout_session_v1(
    'dddddddd-dddd-4ddd-dddd-dddddddddddd', null, null,
    (SELECT jsonb_set(payload,'{routine_snapshot}',
      payload->'routine_snapshot' || '{"unexpected":true}'::jsonb)
     FROM pg_temp.w7c_save_fixture))
$invalid_snapshot$,'22023','invalid_new_workout_payload',
  'unknown snapshot fields are rejected');
SELECT throws_ok($foreign_exercise$
  SELECT public.rpc_save_workout_session_v1(
    'eeeeeeee-eeee-4eee-eeee-eeeeeeeeeeee', null, null,
    (SELECT jsonb_set(
      jsonb_set(payload,'{routine_snapshot,exercises,0,exercise_ref}',
        '"ffffffff-ffff-4fff-ffff-ffffffffffff"'::jsonb),
      '{performed_sets,0,exercise_ref}',
        '"ffffffff-ffff-4fff-ffff-ffffffffffff"'::jsonb)
     FROM pg_temp.w7c_save_fixture))
$foreign_exercise$,'42501','exercise_not_owned',
  'unowned custom Exercise cannot be saved');
SELECT is((SELECT count(*)::integer FROM public.user_workout_sessions
           WHERE save_request_id in (
             'dddddddd-dddd-4ddd-dddd-dddddddddddd',
             'eeeeeeee-eeee-4eee-eeee-eeeeeeeeeeee')),
  0,'rejected snapshots and Exercises leave no canonical row');

RESET ROLE;
UPDATE w7c_save_fixture SET payload = jsonb_set(
  jsonb_set(
    jsonb_set(
      jsonb_set(
        jsonb_set(payload,'{started_at_utc}',
          '"2026-11-08T02:00:00Z"'::jsonb),
        '{completed_at_utc}', '"2026-11-08T03:00:00Z"'::jsonb),
      '{workout_at_utc}', '"2026-11-08T02:30:00Z"'::jsonb),
    '{performed_sets,0,completed_at_utc}',
      '"2026-11-08T02:40:00Z"'::jsonb),
  '{workout_utc_offset_minutes}', '-420'::jsonb);
UPDATE w7c_save_fixture SET payload = jsonb_set(
  payload,'{selected_duration_seconds}','21600'::jsonb);
SET LOCAL ROLE authenticated;
SELECT lives_ok($negative$
  SELECT public.rpc_save_workout_session_v1(
    '99999999-9999-4999-9999-999999999999', null, null,
    (SELECT payload FROM pg_temp.w7c_save_fixture))
$negative$, 'negative-offset Save commits under Los Angeles database timezone');
SELECT is((SELECT local_date FROM public.user_workout_sessions
           WHERE save_request_id='99999999-9999-4999-9999-999999999999'),
  '2026-11-07'::date,'negative offset crosses to the previous local day');
SELECT is((SELECT workout_duration_seconds FROM public.user_workout_sessions
           WHERE save_request_id='99999999-9999-4999-9999-999999999999'),
  21600,'selected duration above picker maximum is not silently truncated');
SELECT is((SELECT count(*)::integer FROM public.user_workout_performed_sets p
           JOIN public.user_workout_sessions s ON s.id=p.session_id
           WHERE s.save_request_id='99999999-9999-4999-9999-999999999999'),
  1,'negative-offset Save retains the actual performed set');

SELECT throws_ok($duplicate_slot$
  SELECT public.rpc_save_workout_session_v1(
    'abababab-abab-4aba-abab-abababababab', null, null,
    (SELECT jsonb_set(payload,'{performed_sets}',
      (payload->'performed_sets') || (payload->'performed_sets'))
     FROM pg_temp.w7c_save_fixture))
$duplicate_slot$,'22023','invalid_save_payload',
  'duplicate performed slots are rejected before any write');
SELECT is((SELECT count(*)::integer FROM public.user_workout_sessions
           WHERE save_request_id='abababab-abab-4aba-abab-abababababab'),
  0,'duplicate-set failure leaves no partial session');
SELECT lives_ok($optional_activity$
  SELECT public.rpc_save_workout_session_v1(
    'acacacac-acac-4aca-acac-acacacacacac', null, null,
    (SELECT jsonb_set(payload,'{activity_type}','null'::jsonb)
     FROM pg_temp.w7c_save_fixture))
$optional_activity$, 'activity type remains optional on Save');
SELECT is((SELECT workout_activity_type FROM public.user_workout_sessions
           WHERE save_request_id='acacacac-acac-4aca-acac-acacacacacac'),
  null, 'missing activity type stores as null');
SELECT lives_ok($steps_type$
  SELECT public.rpc_save_workout_session_v1(
    'adadadad-adad-4ada-adad-adadadadadad', null, null,
    (SELECT jsonb_set(
      jsonb_set(
        jsonb_set(
          jsonb_set(payload,'{routine_snapshot,exercises,0,exercise_type}',
            '"steps_duration"'::jsonb),
          '{routine_snapshot,exercises,0,prescribed_sets,0}',
          '{"set_type":"normal","duration_seconds":60}'::jsonb),
        '{performed_sets,0}',
        jsonb_build_object(
          'exercise_ref', payload#>>'{performed_sets,0,exercise_ref}',
          'exercise_index', 0,
          'set_index', 0,
          'duration_seconds', 60,
          'completed_at_utc', payload#>>'{performed_sets,0,completed_at_utc}',
          'is_skipped', false)),
      '{activity_type}', '"Cardio"'::jsonb)
     FROM pg_temp.w7c_save_fixture))
$steps_type$, 'ad-hoc snapshot accepts steps_duration exercise type');

RESET ROLE;
INSERT INTO public.user_workout_programs (id,user_id,name) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000001',
   '11111111-1111-1111-1111-111111111111','Legacy Program')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_routines (id,user_id,program_id,name) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000002',
   '11111111-1111-1111-1111-111111111111',
   'aaaaaaaa-1111-0000-0000-000000000001','Legacy Routine')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_routine_exercises
  (id,user_id,routine_id,position,catalog_exercise_id) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000003',
   '11111111-1111-1111-1111-111111111111',
   'aaaaaaaa-1111-0000-0000-000000000002',0,'ex_barbell_bench_press')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_routine_sets
  (id,user_id,routine_exercise_id,position,set_type,reps,load_kg) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000004',
   '11111111-1111-1111-1111-111111111111',
   'aaaaaaaa-1111-0000-0000-000000000003',0,'normal',10,100)
ON CONFLICT (id) DO NOTHING;
SET LOCAL ROLE authenticated;
SELECT lives_ok($legacy_start$
  SELECT public.rpc_start_workout_session(
    '66666666-6666-4666-8666-666666666666',
    'aaaaaaaa-1111-0000-0000-000000000001',
    'aaaaaaaa-1111-0000-0000-000000000002',
    '2026-11-07 10:00:00+00','2026-11-07',
    '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000002","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"Legacy Routine","captured_at_utc":"2026-11-07T10:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0}]}]}'::jsonb)
$legacy_start$,'legacy W7B routine start still accepts v1 snapshot');
SELECT lives_ok($legacy_log$
  SELECT public.rpc_log_workout_performed_set(
    '77777777-7777-4777-8777-777777777777',
    '66666666-6666-4666-8666-666666666666',1,
    'ex_barbell_bench_press',0,0,p_reps=>10,p_load_kg=>100,
    p_completed_at_utc=>'2026-11-07 10:30:00+00')
$legacy_log$,'legacy session can have a performed set before Save');

RESET ROLE;
CREATE TEMP TABLE w7c_legacy_payload AS
  SELECT jsonb_build_object(
    'started_at_utc','2026-11-07T10:00:00Z',
    'completed_at_utc','2026-11-07T11:00:00Z',
    'workout_title','Morning Workout',
    'workout_at_utc','2026-11-07T10:00:00Z',
    'workout_utc_offset_minutes',330,
    'description','Legacy saved',
    'activity_type','Weight Training',
    'gym_name',null,
    'overall_rpe',8,
    'selected_duration_seconds',3600,
    'routine_snapshot',routine_snapshot,
    'performed_sets',jsonb_build_array(jsonb_build_object(
      'exercise_ref','ex_barbell_bench_press',
      'exercise_index',0,'set_index',0,'reps',8,'load_kg',90,
      'completed_at_utc','2026-11-07T10:40:00Z','is_skipped',false))) AS payload
  FROM public.user_workout_sessions
  WHERE id='66666666-6666-4666-8666-666666666666';
GRANT SELECT ON w7c_legacy_payload TO authenticated;
SET LOCAL ROLE authenticated;
SELECT lives_ok($legacy_save$
  SELECT public.rpc_save_workout_session_v1(
    '88888888-8888-4888-8888-888888888888',
    '66666666-6666-4666-8666-666666666666',2,
    (SELECT payload FROM pg_temp.w7c_legacy_payload))
$legacy_save$,'Save atomically replaces legacy performed sets and completes');
SELECT is((SELECT revision FROM public.user_workout_sessions
           WHERE id='66666666-6666-4666-8666-666666666666'),
  3,'legacy completion advances revision once after Save');
SELECT is((SELECT count(*)::integer FROM public.user_workout_performed_sets
           WHERE session_id='66666666-6666-4666-8666-666666666666'
             AND reps=8 AND load_kg=90),
  1,'legacy Save reads the replacement actual measurement');
SELECT is((SELECT count(*)::integer FROM public.user_workout_performed_sets
           WHERE id='77777777-7777-4777-8777-777777777777'),
  0,'legacy pre-Save performed row is replaced');
SELECT lives_ok($legacy_retry$
  SELECT public.rpc_save_workout_session_v1(
    '88888888-8888-4888-8888-888888888888',
    '66666666-6666-4666-8666-666666666666',2,
    (SELECT payload FROM pg_temp.w7c_legacy_payload))
$legacy_retry$,'legacy identical retry is idempotent');
SELECT is((SELECT revision FROM public.user_workout_sessions
           WHERE id='66666666-6666-4666-8666-666666666666'),
  3,'legacy retry does not duplicate completion');

RESET ROLE;
CREATE TEMP TABLE w7c_saved_id AS
  SELECT id FROM public.user_workout_sessions
  WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa';
GRANT SELECT ON w7c_saved_id TO authenticated;
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '22222222-2222-2222-2222-222222222222';
SELECT is((SELECT count(*)::integer FROM public.user_workout_sessions
           WHERE save_request_id='aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
  0,'another account cannot read completed workout');
SELECT throws_ok($other$
  SELECT public.rpc_save_workout_session_v1(
    'cccccccc-cccc-4ccc-cccc-cccccccccccc',
    (SELECT id FROM pg_temp.w7c_saved_id),
    1,(SELECT payload - 'accumulated_paused_microseconds'
       FROM pg_temp.w7c_save_fixture))
$other$,'P0002','session_not_found',
  'a different account cannot take over a completed draft');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
