\set ON_ERROR_STOP on
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap SCHEMA extensions;
SELECT no_plan();

INSERT INTO auth.users (id,email) VALUES
  ('11111111-1111-1111-1111-111111111111','w8c_owner@tio.test'),
  ('22222222-2222-2222-2222-222222222222','w8c_other@tio.test')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.users (id,email) VALUES
  ('11111111-1111-1111-1111-111111111111','w8c_owner@tio.test'),
  ('22222222-2222-2222-2222-222222222222','w8c_other@tio.test')
ON CONFLICT (id) DO NOTHING;

CREATE TEMP TABLE w8c_fixture (save_payload jsonb, edit_payload jsonb, session_id uuid);
INSERT INTO w8c_fixture (save_payload) VALUES ($payload$
{
  "started_at_utc":"2026-11-11T20:00:00Z",
  "completed_at_utc":"2026-11-11T21:00:00Z",
  "accumulated_paused_microseconds":0,
  "workout_title":"Original Workout",
  "workout_at_utc":"2026-11-11T20:30:00Z",
  "workout_utc_offset_minutes":330,
  "description":"Initial description",
  "activity_type":"Weight Training",
  "gym_name":"Initial Gym",
  "overall_rpe":7,
  "selected_duration_seconds":3600,
  "routine_snapshot":{
    "schema_version":2,"origin":"ad_hoc",
    "captured_at_utc":"2026-11-11T20:00:00Z",
    "exercises":[{
      "exercise_ref":"ex_barbell_bench_press",
      "display_name":"Bench Press","exercise_type":"weight_reps",
      "occurrence_index":0,
      "prescribed_sets":[{"set_type":"normal"}]
    }]
  },
  "performed_sets":[{
    "exercise_ref":"ex_barbell_bench_press",
    "exercise_index":0,"set_index":0,
    "reps":8,"load_kg":50,
    "completed_at_utc":"2026-11-11T20:40:00Z",
    "is_skipped":false
  }]
}
$payload$::jsonb);
GRANT SELECT, UPDATE ON w8c_fixture TO authenticated;

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

CREATE TEMP TABLE w8c_legacy_fixture (session_id uuid, edit_payload jsonb);
INSERT INTO w8c_legacy_fixture VALUES (null,null);
GRANT SELECT, UPDATE ON w8c_legacy_fixture TO authenticated;

SELECT is(has_function_privilege('authenticated',
  'public.rpc_update_completed_workout_v1(uuid,integer,jsonb)','EXECUTE'),
  true,'authenticated can invoke the scoped Update RPC');
SELECT is(has_function_privilege('anon',
  'public.rpc_update_completed_workout_v1(uuid,integer,jsonb)','EXECUTE'),
  false,'anon cannot invoke Update');
SELECT is(has_table_privilege('authenticated','public.user_workout_sessions','UPDATE'),
  false,'no direct session UPDATE grant');
SELECT is(has_table_privilege('authenticated','public.user_workout_performed_sets','DELETE'),
  false,'no direct set DELETE grant');
SELECT is((select p.proconfig @> ARRAY['search_path=""']::text[]
           from pg_proc p
           where p.oid='public.rpc_update_completed_workout_v1(uuid,integer,jsonb)'::regprocedure),
  true,'Update pins an empty search_path');

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
SELECT lives_ok($save$
  SELECT public.rpc_save_workout_session_v1(
    'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',null,null,
    (SELECT save_payload FROM pg_temp.w8c_fixture))
$save$,'fixture Save commits one completed workout');
UPDATE w8c_fixture SET session_id = (
  SELECT id FROM public.user_workout_sessions
  WHERE save_request_id = 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa');

UPDATE w8c_fixture f SET edit_payload = (
  SELECT jsonb_build_object(
    'workout_title','Updated Workout',
    'description','Edited description',
    'workout_at_utc','2026-11-11T20:45:00Z',
    'workout_utc_offset_minutes',330,
    'selected_duration_seconds',3000,
    'gym_name','Edited Gym',
    'activity_type','Weight Training',
    'overall_rpe',8,
    'routine_snapshot',jsonb_set(s.routine_snapshot,'{exercises}',
      (s.routine_snapshot->'exercises') || $new_ex$
      [{"exercise_ref":"ex_spinning","display_name":"Spinning",
        "exercise_type":"duration","occurrence_index":1,
        "prescribed_sets":[{"set_type":"normal"}]}]
      $new_ex$::jsonb),
    'performed_sets',jsonb_build_array(
      jsonb_build_object(
        'id',p.id,'exercise_ref',p.exercise_ref,'exercise_index',0,
        'set_index',0,'reps',10,'load_kg',50,
        'completed_at_utc','2026-11-11T20:40:00Z','is_skipped',false),
      jsonb_build_object(
        'exercise_ref','ex_spinning','exercise_index',1,'set_index',0,
        'duration_seconds',120,
        'completed_at_utc','2026-11-11T20:50:00Z','is_skipped',false)))
  FROM public.user_workout_sessions s
  JOIN public.user_workout_performed_sets p ON p.session_id=s.id
  WHERE s.id=f.session_id);

SELECT lives_ok($edit$
  SELECT public.rpc_update_completed_workout_v1(
    (SELECT session_id FROM pg_temp.w8c_fixture),2,
    (SELECT edit_payload FROM pg_temp.w8c_fixture))
$edit$,'owner can atomically edit metadata, actual reps and add an exercise');
SELECT is((SELECT revision FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_fixture)),
  3,'Update increments the canonical revision exactly once');
SELECT is((SELECT count(*)::integer FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_fixture)),
  1,'Update retains the canonical session ID');
SELECT is((SELECT workout_title FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_fixture)),
  'Updated Workout','title persists');
SELECT is((SELECT gym_name FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_fixture)),
  'Edited Gym','gym persists');
SELECT is((SELECT workout_duration_seconds FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_fixture)),
  3000,'duration persists');
SELECT is((SELECT count(*)::integer FROM public.user_workout_performed_sets
           WHERE session_id=(SELECT session_id FROM w8c_fixture)),
  2,'actual performed rows were replaced atomically');
SELECT is((SELECT reps FROM public.user_workout_performed_sets
           WHERE session_id=(SELECT session_id FROM w8c_fixture)
             AND session_exercise_index=0),
  10,'edited reps persist');
SELECT lives_ok($replay$
  SELECT public.rpc_update_completed_workout_v1(
    (SELECT session_id FROM pg_temp.w8c_fixture),2,
    (SELECT edit_payload FROM pg_temp.w8c_fixture))
$replay$,'same payload and expected revision are safe to replay');
SELECT is((SELECT revision FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_fixture)),
  3,'replay does not increment revision');
SELECT throws_ok($stale$
  SELECT public.rpc_update_completed_workout_v1(
    (SELECT session_id FROM pg_temp.w8c_fixture),2,
    (SELECT jsonb_set(edit_payload,'{workout_title}','"Conflicting"'::jsonb)
     FROM pg_temp.w8c_fixture))
$stale$,'P0003','stale_workout_edit','stale changed payload cannot overwrite');
SELECT throws_ok($invalid$
  SELECT public.rpc_update_completed_workout_v1(
    (SELECT session_id FROM pg_temp.w8c_fixture),3,
    (SELECT jsonb_set(edit_payload,'{performed_sets,0,reps}','1000'::jsonb)
     FROM pg_temp.w8c_fixture))
$invalid$,'22023','invalid_edit_set','invalid performed values reject the whole edit');
SELECT is((SELECT revision FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_fixture)),
  3,'failed edit does not mutate the header');

SELECT lives_ok($legacy_start$
  SELECT public.rpc_start_workout_session(
    '66666666-6666-4666-8666-666666666666',
    'aaaaaaaa-1111-0000-0000-000000000001',
    'aaaaaaaa-1111-0000-0000-000000000002',
    '2026-11-11 20:00:00+00','2026-11-11',
    '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000002","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"Legacy Routine","captured_at_utc":"2026-11-11T20:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0}]}]}'::jsonb)
$legacy_start$,'owner starts a legacy schema-v1 routine workout');
SELECT lives_ok($legacy_log$
  SELECT public.rpc_log_workout_performed_set(
    '77777777-7777-4777-8777-777777777777',
    '66666666-6666-4666-8666-666666666666',1,
    'ex_barbell_bench_press',0,0,p_reps=>10,p_load_kg=>100,
    p_completed_at_utc=>'2026-11-11 20:40:00+00')
$legacy_log$,'legacy v1 workout records its performed set');
SELECT lives_ok($legacy_complete$
  SELECT public.rpc_complete_workout_session_v2(
    '66666666-6666-4666-8666-666666666666',2,
    '2026-11-11 21:00:00+00','Legacy description',
    'Legacy Workout','2026-11-11 20:30:00+00',330)
$legacy_complete$,'legacy v1 workout completes before Edit');
UPDATE w8c_legacy_fixture f SET
  session_id = s.id,
  edit_payload = jsonb_build_object(
    'workout_title','Updated Legacy Workout',
    'description','Updated legacy description',
    'workout_at_utc','2026-11-11T20:35:00Z',
    'workout_utc_offset_minutes',330,
    'selected_duration_seconds',2700,
    'gym_name','Legacy Gym',
    'activity_type','Weight Training',
    'overall_rpe',8,
    'routine_snapshot',jsonb_set(
      s.routine_snapshot,
      '{exercises,0,prescribed_sets,0,performed_rpe}',
      '8.5'::jsonb,true),
    'performed_sets',jsonb_build_array(jsonb_build_object(
      'id',p.id,'exercise_ref',p.exercise_ref,
      'exercise_index',0,'set_index',0,'reps',11,'load_kg',95,
      'completed_at_utc','2026-11-11T20:40:00Z','is_skipped',false)))
FROM public.user_workout_sessions s
JOIN public.user_workout_performed_sets p ON p.session_id=s.id
WHERE s.id='66666666-6666-4666-8666-666666666666';
SELECT lives_ok($legacy_update$
  SELECT public.rpc_update_completed_workout_v1(
    (SELECT session_id FROM pg_temp.w8c_legacy_fixture),3,
    (SELECT edit_payload FROM pg_temp.w8c_legacy_fixture))
$legacy_update$,'authenticated Update accepts performed RPE on a completed v1 session');
SELECT is((SELECT routine_snapshot->>'schema_version'
           FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_legacy_fixture)),
  '1','legacy Update preserves the v1 snapshot version');
SELECT is((SELECT (routine_snapshot #>>
             '{exercises,0,prescribed_sets,0,performed_rpe}')::numeric
           FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_legacy_fixture)),
  8.5::numeric,'legacy Update persists the edited set RPE');
SELECT is((SELECT revision FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_legacy_fixture)),
  4,'legacy Update advances the existing session revision once');
SELECT lives_ok($legacy_replay$
  SELECT public.rpc_update_completed_workout_v1(
    (SELECT session_id FROM pg_temp.w8c_legacy_fixture),3,
    (SELECT edit_payload FROM pg_temp.w8c_legacy_fixture))
$legacy_replay$,'same v1 Update payload is safe to replay');
SELECT throws_ok($legacy_rpe_range$
  SELECT public.rpc_update_completed_workout_v1(
    (SELECT session_id FROM pg_temp.w8c_legacy_fixture),4,
    (SELECT jsonb_set(edit_payload,
      '{routine_snapshot,exercises,0,prescribed_sets,0,performed_rpe}',
      '10.1'::jsonb,true)
     FROM pg_temp.w8c_legacy_fixture))
$legacy_rpe_range$,'22023','invalid_edit_snapshot',
  'legacy performed RPE outside 0-10 is rejected');
SELECT is((SELECT revision FROM public.user_workout_sessions
           WHERE id=(SELECT session_id FROM w8c_legacy_fixture)),
  4,'rejected v1 RPE does not mutate the session');

SET LOCAL "request.jwt.claim.sub" = '22222222-2222-2222-2222-222222222222';
SELECT throws_ok($foreign$
  SELECT public.rpc_update_completed_workout_v1(
    (SELECT session_id FROM pg_temp.w8c_fixture),3,
    (SELECT edit_payload FROM pg_temp.w8c_fixture))
$foreign$,'P0002','session_not_found','other account cannot edit owner session');
RESET ROLE;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
SELECT throws_ok($direct$
  UPDATE public.user_workout_sessions SET workout_title='Bypass'
  WHERE id=(SELECT session_id FROM pg_temp.w8c_fixture)
$direct$,'P0001','terminal_workout_session_immutable',
  'terminal trigger still rejects an unscoped privileged update');
SELECT is((SELECT current_setting('tio_w8c.edit_session_id',true)),
  '','transaction-local edit gate was cleared');
SELECT * FROM finish();
ROLLBACK;
