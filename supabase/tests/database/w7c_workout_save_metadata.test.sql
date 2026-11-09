\set ON_ERROR_STOP on
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap SCHEMA extensions;
SELECT plan(17);

INSERT INTO auth.users (id, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'owner_w7c@tio.test'),
  ('22222222-2222-2222-2222-222222222222', 'other_w7c@tio.test')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.users (id, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'owner_w7c@tio.test'),
  ('22222222-2222-2222-2222-222222222222', 'other_w7c@tio.test')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_programs (id, user_id, name) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'W7C Program')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_routines (id, user_id, program_id, name) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000001', 'W7C Routine')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_routine_exercises (id, user_id, routine_id, position, catalog_exercise_id) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000002', 0, 'ex_barbell_bench_press')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_routine_sets (id, user_id, routine_exercise_id, position, set_type, reps, load_kg, rest_seconds) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000003', 0, 'normal', 10, 100.0, 90)
ON CONFLICT (id) DO NOTHING;

SELECT is(
  has_function_privilege('authenticated', 'public.rpc_complete_workout_session_v2(uuid,integer,timestamp with time zone,text,text,timestamp with time zone,integer)', 'EXECUTE'),
  true, 'authenticated can execute V2 completion'
);
SELECT is(
  has_function_privilege('anon', 'public.rpc_complete_workout_session_v2(uuid,integer,timestamp with time zone,text,text,timestamp with time zone,integer)', 'EXECUTE'),
  false, 'anon cannot execute V2 completion'
);
SELECT is(
  has_column_privilege('authenticated', 'public.user_workout_sessions', 'workout_title', 'UPDATE'),
  false, 'authenticated cannot directly update workout metadata'
);

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
SELECT lives_ok($start$
  SELECT public.rpc_start_workout_session(
    'cccccccc-cccc-4ccc-accc-cccccccccccc',
    'aaaaaaaa-1111-0000-0000-000000000001',
    'aaaaaaaa-1111-0000-0000-000000000002',
    '2026-11-07 12:00:00+00', '2026-11-07',
    '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000002","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"W7C Routine","captured_at_utc":"2026-11-07T12:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90}]}]}'::jsonb
  )
$start$, 'routine-backed canonical session can start');

SELECT throws_ok($blank$
  SELECT public.rpc_complete_workout_session_v2(
    'cccccccc-cccc-4ccc-accc-cccccccccccc', 1, '2026-11-07 22:00:00+00', null,
    '  ', '2026-11-07 21:30:00+00', 330
  )
$blank$, '22023', 'invalid_workout_title', 'blank title is rejected by V2');
SELECT throws_ok($offset$
  SELECT public.rpc_complete_workout_session_v2(
    'cccccccc-cccc-4ccc-accc-cccccccccccc', 1, '2026-11-07 22:00:00+00', null,
    'Morning Workout', '2026-11-07 21:30:00+00', 841
  )
$offset$, '22023', 'invalid_workout_utc_offset', 'offset beyond fourteen hours is rejected');
SELECT throws_ok($future$
  SELECT public.rpc_complete_workout_session_v2(
    'cccccccc-cccc-4ccc-accc-cccccccccccc', 1, '2026-11-07 22:00:00+00', null,
    'Morning Workout', '2026-11-07 22:01:00+00', 0
  )
$future$, '22023', 'future_workout_timestamp', 'workout time cannot be after completion');

SELECT lives_ok($complete$
  SELECT public.rpc_complete_workout_session_v2(
    'cccccccc-cccc-4ccc-accc-cccccccccccc', 1, '2026-11-07 22:00:00+00', '  notes  ',
    '  Morning Workout  ', '2026-11-07 21:30:00+00', 330
  )
$complete$, 'valid completion writes title, instant, offset, notes, and terminal state');
SELECT is((SELECT workout_title FROM public.user_workout_sessions WHERE id = 'cccccccc-cccc-4ccc-accc-cccccccccccc'), 'Morning Workout', 'custom/fallback title is trimmed and readable');
SELECT is((SELECT workout_at_utc FROM public.user_workout_sessions WHERE id = 'cccccccc-cccc-4ccc-accc-cccccccccccc'), '2026-11-07 21:30:00+00'::timestamptz, 'selected timestamp persists independently');
SELECT is((SELECT workout_utc_offset_minutes FROM public.user_workout_sessions WHERE id = 'cccccccc-cccc-4ccc-accc-cccccccccccc'), 330, 'selected UTC offset persists');
SELECT is((SELECT local_date FROM public.user_workout_sessions WHERE id = 'cccccccc-cccc-4ccc-accc-cccccccccccc'), '2026-11-08'::date, 'local date derives from instant and saved offset across UTC midnight');
SELECT is((SELECT notes FROM public.user_workout_sessions WHERE id = 'cccccccc-cccc-4ccc-accc-cccccccccccc'), 'notes', 'notes retain canonical normalization');
SELECT is((SELECT revision FROM public.user_workout_sessions WHERE id = 'cccccccc-cccc-4ccc-accc-cccccccccccc'), 2, 'completion increments revision exactly once');

RESET ROLE;
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '22222222-2222-2222-2222-222222222222';
SELECT throws_ok($owner$
  SELECT public.rpc_complete_workout_session_v2(
    'cccccccc-cccc-4ccc-accc-cccccccccccc', 1, '2026-11-07 22:00:00+00', 'notes',
    'Morning Workout', '2026-11-07 21:30:00+00', 330
  )
$owner$, 'P0002', 'session_not_found', 'a different owner cannot complete the session');

RESET ROLE;
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
SELECT is((SELECT revision FROM public.rpc_complete_workout_session_v2(
  'cccccccc-cccc-4ccc-accc-cccccccccccc', 1, '2026-11-07 22:00:00+00', 'notes',
  'Morning Workout', '2026-11-07 21:30:00+00', 330
)), 2, 'identical terminal replay returns existing row without another write');
SELECT throws_ok($conflict$
  SELECT public.rpc_complete_workout_session_v2(
    'cccccccc-cccc-4ccc-accc-cccccccccccc', 1, '2026-11-07 22:00:00+00', 'notes',
    'Afternoon Workout', '2026-11-07 21:30:00+00', 330
  )
$conflict$, '23505', 'terminal_payload_conflict', 'conflicting terminal replay is rejected');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
