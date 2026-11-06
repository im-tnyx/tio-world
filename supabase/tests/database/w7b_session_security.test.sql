\set ON_ERROR_STOP on
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap;
SELECT plan(46);

-- ============================================================================
-- Fixtures Setup (Two distinct authenticated users with programs & routines)
-- ============================================================================

INSERT INTO auth.users (id, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'owner_a@tio.test'),
  ('22222222-2222-2222-2222-222222222222', 'owner_b@tio.test')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.users (id, email) VALUES
  ('11111111-1111-1111-1111-111111111111', 'owner_a@tio.test'),
  ('22222222-2222-2222-2222-222222222222', 'owner_b@tio.test')
ON CONFLICT (id) DO NOTHING;

-- Programs
INSERT INTO public.user_workout_programs (id, user_id, name) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Program A'),
  ('bbbbbbbb-2222-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'Program B')
ON CONFLICT (id) DO NOTHING;

-- Routines
INSERT INTO public.user_workout_routines (id, user_id, program_id, name) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000001', 'Routine A'),
  ('bbbbbbbb-2222-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-2222-0000-0000-000000000002', 'Routine B'),
  ('aaaaaaaa-1111-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000001', 'Routine C')
ON CONFLICT (id) DO NOTHING;

-- Routine Exercises
INSERT INTO public.user_workout_routine_exercises (id, user_id, routine_id, position, catalog_exercise_id) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000002', 0, 'ex_barbell_bench_press'),
  ('bbbbbbbb-2222-0000-0000-000000000004', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-2222-0000-0000-000000000003', 0, 'ex_barbell_bench_press'),
  ('aaaaaaaa-1111-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000005', 0, 'ex_barbell_bench_press')
ON CONFLICT (id) DO NOTHING;

-- Routine Sets
INSERT INTO public.user_workout_routine_sets (id, user_id, routine_exercise_id, position, set_type, reps, load_kg, rest_seconds) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000003', 0, 'normal', 10, 100.0, 90),
  ('bbbbbbbb-2222-0000-0000-000000000005', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-2222-0000-0000-000000000004', 0, 'normal', 8, 80.0, 60),
  ('aaaaaaaa-1111-0000-0000-000000000007', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000006', 0, 'normal', 5, 50.0, 45)
ON CONFLICT (id) DO NOTHING;

-- Snapshots
\set valid_snapshot '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000002","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"Routine A","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90}]}]}'
\set valid_snapshot_b '{"schema_version":1,"routine_id":"bbbbbbbb-2222-0000-0000-000000000003","program_id":"bbbbbbbb-2222-0000-0000-000000000002","routine_name":"Routine B","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":8,"load_kg":80.0,"rest_seconds":60}]}]}'
\set valid_snapshot_c '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000005","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"Routine C","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":5,"load_kg":50.0,"rest_seconds":45}]}]}'

-- ============================================================================
-- 1-4. Direct Authenticated DML Denial Tests
-- ============================================================================
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';

SELECT throws_ok(
  $$
  INSERT INTO public.user_workout_sessions (
    user_id, program_id, routine_id, started_at_utc, last_transition_at_utc, local_date, routine_snapshot
  ) VALUES (
    '11111111-1111-1111-1111-111111111111', gen_random_uuid(), gen_random_uuid(), now(), now(), CURRENT_DATE, '{}'::jsonb
  )
  $$,
  '42501',
  'permission denied for table user_workout_sessions',
  'Direct INSERT on user_workout_sessions must be denied to authenticated users'
);

SELECT throws_ok(
  $$
  INSERT INTO public.user_workout_performed_sets (
    session_id, user_id, exercise_ref, session_exercise_index, set_index
  ) VALUES (
    gen_random_uuid(), '11111111-1111-1111-1111-111111111111', 'ex_squat', 0, 0
  )
  $$,
  '42501',
  'permission denied for table user_workout_performed_sets',
  'Direct INSERT on user_workout_performed_sets must be denied to authenticated users'
);

SELECT throws_ok(
  $$
  UPDATE public.user_workout_sessions SET notes = 'tampered'
  $$,
  '42501',
  'permission denied for table user_workout_sessions',
  'Direct UPDATE on user_workout_sessions must be denied to authenticated users'
);

SELECT throws_ok(
  $$
  DELETE FROM public.user_workout_sessions
  $$,
  '42501',
  'permission denied for table user_workout_sessions',
  'Direct DELETE on user_workout_sessions must be denied to authenticated users'
);

RESET ROLE;

-- ============================================================================
-- 5-8. Finding 2 (P2 - 4490473103) Three-Valued Logic & Snapshot Integrity
-- ============================================================================
SELECT is(
  private.is_valid_workout_session_snapshot_v1('{}'::jsonb),
  false,
  'Snapshot validator rejects empty JSONB object'
);

SELECT is(
  private.is_valid_workout_session_snapshot_v1('{"schema_version": 1}'::jsonb),
  false,
  'Snapshot validator rejects snapshot missing required fields'
);

SELECT is(
  private.is_valid_workout_session_snapshot_v1('{"schema_version": 1, "routine_id": "aaaaaaaa-1111-0000-0000-000000000002", "routine_name": "R", "captured_at_utc": "invalid-ts", "exercises": []}'::jsonb),
  false,
  'Snapshot validator rejects invalid captured_at_utc timestamp'
);

SELECT is(
  private.is_valid_workout_session_snapshot_v1('{"schema_version": 2}'::jsonb),
  false,
  'Snapshot validator rejects unsupported schema version'
);

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';

-- ============================================================================
-- 9-12. Routine Authorization & Prescription Integrity (Finding 4 - 4490473113)
-- ============================================================================
-- 9. Forged Source Routine/Program Failure: Owner A passes Owner B routine ID in both params and snapshot
SELECT throws_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      gen_random_uuid(),
      'bbbbbbbb-2222-0000-0000-000000000002'::uuid,
      'bbbbbbbb-2222-0000-0000-000000000003'::uuid,
      '2026-11-06 10:00:00+00'::timestamptz,
      '2026-11-06'::date,
      %L::jsonb
    )
    $$,
    :'valid_snapshot_b'
  ),
  '42501',
  'invalid_routine_or_unauthorized',
  'Owner A cannot start workout using Owner B routine'
);

-- 10. Snapshot Identity Mismatch (params routine_id != snapshot routine_id)
SELECT throws_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      gen_random_uuid(),
      'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000002'::uuid,
      '2026-11-06 10:00:00+00'::timestamptz,
      '2026-11-06'::date,
      %L::jsonb
    )
    $$,
    :'valid_snapshot_b'
  ),
  '22023',
  'snapshot_identity_mismatch',
  'Snapshot routine_id mismatching parameter routine_id is rejected'
);

-- 11. Prescribed Set Mismatch: Reps altered in snapshot
SELECT throws_ok(
  $$
  SELECT public.rpc_start_workout_session(
    gen_random_uuid(),
    'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
    'aaaaaaaa-1111-0000-0000-000000000002'::uuid,
    '2026-11-06 10:00:00+00'::timestamptz,
    '2026-11-06'::date,
    '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000002","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"Routine A","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":99,"load_kg":100.0,"rest_seconds":90}]}]}'::jsonb
  )
  $$,
  '22023',
  'snapshot_prescription_mismatch',
  'Snapshot prescribed set value mismatch with routine is rejected'
);

-- 12. Prescribed Set Count Mismatch: 2 sets in snapshot, 1 in routine
SELECT throws_ok(
  $$
  SELECT public.rpc_start_workout_session(
    gen_random_uuid(),
    'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
    'aaaaaaaa-1111-0000-0000-000000000002'::uuid,
    '2026-11-06 10:00:00+00'::timestamptz,
    '2026-11-06'::date,
    '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000002","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"Routine A","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90},{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90}]}]}'::jsonb
  )
  $$,
  '22023',
  'snapshot_prescription_count_mismatch',
  'Snapshot prescribed set count mismatch with routine is rejected'
);

-- ============================================================================
-- 13. Valid Session Start via RPC
-- ============================================================================
SELECT lives_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000002'::uuid,
      '2026-11-06 10:00:00+00'::timestamptz,
      '2026-11-06'::date,
      %L::jsonb
    )
    $$,
    :'valid_snapshot'
  ),
  'Owner A successfully starts active workout session via rpc_start_workout_session'
);

-- ============================================================================
-- 14-16. Finding 5 (P2 - 4490473120) Start Replay Recovery & Conflict
-- ============================================================================
-- 14. Exact matching start replay succeeds idempotently
SELECT lives_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000002'::uuid,
      '2026-11-06 10:00:00+00'::timestamptz,
      '2026-11-06'::date,
      %L::jsonb
    )
    $$,
    :'valid_snapshot'
  ),
  'Exact matching start replay succeeds idempotently returning existing session'
);

-- 15. Start replay with conflicting local_date throws 23505
SELECT throws_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000002'::uuid,
      '2026-11-06 10:00:00+00'::timestamptz,
      '2026-11-07'::date,
      %L::jsonb
    )
    $$,
    :'valid_snapshot'
  ),
  '23505',
  'duplicate_session_conflict',
  'Start replay with conflicting parameter throws duplicate_session_conflict'
);

-- 16. Cross-user start replay: Owner B passes Owner A session ID -> 42501
SET LOCAL "request.jwt.claim.sub" = '22222222-2222-2222-2222-222222222222';
SELECT throws_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
      'bbbbbbbb-2222-0000-0000-000000000002'::uuid,
      'bbbbbbbb-2222-0000-0000-000000000003'::uuid,
      '2026-11-06 10:00:00+00'::timestamptz,
      '2026-11-06'::date,
      %L::jsonb
    )
    $$,
    :'valid_snapshot_b'
  ),
  '42501',
  'session_ownership_mismatch',
  'Cross-user session ID reuse in start RPC is rejected with 42501'
);

-- ============================================================================
-- 17. Owner-Only SELECT via RLS
-- ============================================================================
SELECT is(
  (SELECT count(*)::integer FROM public.user_workout_sessions WHERE id = 'aaaaaaaa-aaaa-0000-0000-000000000001'),
  0,
  'Owner B cannot view Owner A session via SELECT'
);

-- ============================================================================
-- 18. Cross-User Performed-Set Foreign Key Protection
-- ============================================================================
RESET ROLE;
SELECT throws_ok(
  $$
  INSERT INTO public.user_workout_performed_sets (
    id, session_id, user_id, exercise_ref, session_exercise_index, set_index, reps, load_kg
  ) VALUES (
    gen_random_uuid(),
    'aaaaaaaa-aaaa-0000-0000-000000000001',
    '22222222-2222-2222-2222-222222222222',
    'ex_barbell_bench_press', 0, 0, 10, 100.0
  )
  $$,
  '23503',
  'insert or update on table "user_workout_performed_sets" violates foreign key constraint "fk_user_workout_performed_sets_session_composite"',
  'Composite FK prevents Owner B from linking performed set to Owner A session'
);

-- ============================================================================
-- 19. Single Active Session Invariant (Partial Unique Index)
-- ============================================================================
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';

SELECT throws_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      gen_random_uuid(),
      'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000002'::uuid,
      '2026-11-06 10:05:00+00'::timestamptz,
      '2026-11-06'::date,
      %L::jsonb
    )
    $$,
    :'valid_snapshot'
  ),
  '23505',
  'duplicate key value violates unique constraint "uq_user_workout_sessions_single_active"',
  'Partial unique index prevents starting second active session for same owner'
);

-- ============================================================================
-- 20. Valid Set Logging
-- ============================================================================
SELECT lives_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    1,
    'ex_barbell_bench_press',
    0, 0, 10, 100.0, null, null, '2026-11-06 10:02:00+00'::timestamptz, false, 'Good set'
  )
  $$,
  'Owner A logs first performed set successfully'
);

-- ============================================================================
-- 21-24. Finding 1 (P1 - 4490473095) Cross-User / Cross-Session Set Mutation
-- ============================================================================
-- 21. Owner B starts their own session and logs a set
SET LOCAL "request.jwt.claim.sub" = '22222222-2222-2222-2222-222222222222';
SELECT lives_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'bbbbbbbb-bbbb-0000-0000-000000000001'::uuid,
      'bbbbbbbb-2222-0000-0000-000000000002'::uuid,
      'bbbbbbbb-2222-0000-0000-000000000003'::uuid,
      '2026-11-06 10:00:00+00'::timestamptz,
      '2026-11-06'::date,
      %L::jsonb
    );
    SELECT public.rpc_log_workout_performed_set(
      'dddddddd-dddd-0000-0000-000000000001'::uuid,
      'bbbbbbbb-bbbb-0000-0000-000000000001'::uuid,
      1,
      'ex_barbell_bench_press',
      0, 0, 8, 80.0, null, null, '2026-11-06 10:02:00+00'::timestamptz, false, 'Owner B set'
    );
    $$,
    :'valid_snapshot_b'
  ),
  'Owner B starts session and logs set successfully'
);

-- 22. Owner A attempts to log set using Owner B set ID -> 42501 set_ownership_mismatch
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
SELECT throws_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'dddddddd-dddd-0000-0000-000000000001'::uuid,
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    2,
    'ex_barbell_bench_press',
    0, 1, 10, 100.0, null, null, '2026-11-06 10:03:00+00'::timestamptz, false, 'Tampered set'
  )
  $$,
  '42501',
  'set_ownership_mismatch',
  'Owner A cannot overwrite Owner B set UUID in rpc_log_workout_performed_set'
);

-- 23. Owner B set remains completely unaltered
SET LOCAL "request.jwt.claim.sub" = '22222222-2222-2222-2222-222222222222';
SELECT is(
  (SELECT reps FROM public.user_workout_performed_sets WHERE id = 'dddddddd-dddd-0000-0000-000000000001'),
  8,
  'Owner B set reps remain completely unaltered after attack attempt'
);

-- 24. Valid update of Owner A own set in own session succeeds
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
SELECT lives_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    2,
    'ex_barbell_bench_press',
    0, 0, 11, 100.0, null, null, '2026-11-06 10:04:00+00'::timestamptz, false, 'Updated set'
  )
  $$,
  'Owner A updates own set in own session successfully'
);

-- ============================================================================
-- 25. Slot Collision Rejection on Active Session
-- ============================================================================
SELECT throws_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'cccccccc-cccc-0000-0000-000000000002'::uuid, -- Different set ID
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    3, -- Revision 3
    'ex_barbell_bench_press',
    0, 0, -- Same slot (0, 0)
    12, 105.0, null, null, '2026-11-06 10:05:00+00'::timestamptz, false, 'Conflicting set'
  )
  $$,
  '23505',
  'duplicate key value violates unique constraint "uq_user_workout_performed_sets_slot"',
  'Slot unique constraint rejects duplicate set slot in active session'
);

-- ============================================================================
-- 26-32. Finding 3 (P2 - 4490473109) NULL / Invalid Revision OCC Enforcement
-- ============================================================================
SELECT throws_ok(
  $$
  SELECT public.rpc_pause_workout_session('aaaaaaaa-aaaa-0000-0000-000000000001'::uuid, null, '2026-11-06 10:10:00+00'::timestamptz)
  $$,
  '22023',
  'invalid_expected_revision',
  'rpc_pause_workout_session rejects NULL expected revision'
);

SELECT throws_ok(
  $$
  SELECT public.rpc_resume_workout_session('aaaaaaaa-aaaa-0000-0000-000000000001'::uuid, null, '2026-11-06 10:15:00+00'::timestamptz)
  $$,
  '22023',
  'invalid_expected_revision',
  'rpc_resume_workout_session rejects NULL expected revision'
);

SELECT throws_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'cccccccc-cccc-0000-0000-000000000003'::uuid, 'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    null, 'ex_barbell_bench_press', 0, 1, 10, 100.0, null, null, '2026-11-06 10:06:00+00'::timestamptz, false, null
  )
  $$,
  '22023',
  'invalid_expected_revision',
  'rpc_log_workout_performed_set rejects NULL expected revision'
);

SELECT throws_ok(
  $$
  SELECT public.rpc_remove_workout_performed_set('aaaaaaaa-aaaa-0000-0000-000000000001'::uuid, 'cccccccc-cccc-0000-0000-000000000001'::uuid, null)
  $$,
  '22023',
  'invalid_expected_revision',
  'rpc_remove_workout_performed_set rejects NULL expected revision'
);

SELECT throws_ok(
  $$
  SELECT public.rpc_complete_workout_session('aaaaaaaa-aaaa-0000-0000-000000000001'::uuid, null, '2026-11-06 10:30:00+00'::timestamptz, null)
  $$,
  '22023',
  'invalid_expected_revision',
  'rpc_complete_workout_session rejects NULL expected revision'
);

SELECT throws_ok(
  $$
  SELECT public.rpc_discard_workout_session('aaaaaaaa-aaaa-0000-0000-000000000001'::uuid, null, '2026-11-06 10:30:00+00'::timestamptz, null)
  $$,
  '22023',
  'invalid_expected_revision',
  'rpc_discard_workout_session rejects NULL expected revision'
);

SELECT throws_ok(
  $$
  SELECT public.rpc_pause_workout_session('aaaaaaaa-aaaa-0000-0000-000000000001'::uuid, 0, '2026-11-06 10:10:00+00'::timestamptz)
  $$,
  '22023',
  'invalid_expected_revision',
  'rpc_pause_workout_session rejects 0 expected revision'
);

-- ============================================================================
-- 33. Pause Session
-- ============================================================================
SELECT lives_ok(
  $$
  SELECT public.rpc_pause_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    3,
    '2026-11-06 10:10:00+00'::timestamptz
  )
  $$,
  'Owner A pauses session successfully'
);

-- ============================================================================
-- 34. Resume Session (adds 5 minutes = 300,000,000 microseconds)
-- ============================================================================
SELECT lives_ok(
  $$
  SELECT public.rpc_resume_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    4,
    '2026-11-06 10:15:00+00'::timestamptz
  )
  $$,
  'Owner A resumes session successfully'
);

-- ============================================================================
-- 35. WorkoutTime Reconstruction & Microsecond Pause Fidelity
-- ============================================================================
SELECT is(
  (SELECT accumulated_paused_microseconds FROM public.user_workout_sessions WHERE id = 'aaaaaaaa-aaaa-0000-0000-000000000001'),
  300000000::bigint,
  'Accumulated paused microseconds computed with exact 1:1 microsecond fidelity'
);

-- ============================================================================
-- 36. Stale Revision Conflict Protection (OCC)
-- ============================================================================
SELECT throws_ok(
  $$
  SELECT public.rpc_pause_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    2,
    '2026-11-06 10:20:00+00'::timestamptz
  )
  $$,
  'P0003',
  'stale_revision_conflict',
  'Stale revision rejected via optimistic concurrency control'
);

-- ============================================================================
-- 37. Idempotent Retry of Resume
-- ============================================================================
SELECT lives_ok(
  $$
  SELECT public.rpc_resume_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    5,
    '2026-11-06 10:15:00+00'::timestamptz
  )
  $$,
  'Duplicate resume call at matching watermark succeeds idempotently'
);

-- ============================================================================
-- 38. Session Completion
-- ============================================================================
SELECT lives_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    5,
    '2026-11-06 10:30:00+00'::timestamptz,
    'Great workout'
  )
  $$,
  'Owner A completes session successfully'
);

-- ============================================================================
-- 39. Parent Terminal Immutability
-- ============================================================================
RESET ROLE;
SELECT throws_ok(
  $$
  UPDATE public.user_workout_sessions
  SET notes = 'hacked'
  WHERE id = 'aaaaaaaa-aaaa-0000-0000-000000000001'
  $$,
  'P0001',
  'terminal_workout_session_immutable',
  'Completed session cannot be updated directly or via admin'
);

-- ============================================================================
-- 40. Child Terminal Immutability
-- ============================================================================
SELECT throws_ok(
  $$
  INSERT INTO public.user_workout_performed_sets (
    id, session_id, user_id, exercise_ref, session_exercise_index, set_index, reps, load_kg
  ) VALUES (
    gen_random_uuid(),
    'aaaaaaaa-aaaa-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    'ex_barbell_bench_press', 0, 1, 10, 100.0
  )
  $$,
  'P0001',
  'terminal_session_sets_immutable',
  'Sets cannot be inserted into completed workout session'
);

-- ============================================================================
-- 41. Source Routine Deletion Preserves Workout History
-- ============================================================================
DELETE FROM public.user_workout_routines WHERE id = 'aaaaaaaa-1111-0000-0000-000000000002';
SELECT is(
  (SELECT count(*)::integer FROM public.user_workout_sessions WHERE id = 'aaaaaaaa-aaaa-0000-0000-000000000001'),
  1,
  'Workout history preserved completely after source routine deletion'
);

-- ============================================================================
-- 42. Start Replay After Routine Deletion (Finding 5)
-- ============================================================================
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';

-- Start session for Routine C
SELECT lives_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'aaaaaaaa-aaaa-0000-0000-000000000003'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000005'::uuid,
      '2026-11-06 11:00:00+00'::timestamptz,
      '2026-11-06'::date,
      %L::jsonb
    )
    $$,
    :'valid_snapshot_c'
  ),
  'Owner A starts session for Routine C'
);

-- Complete session for Routine C
SELECT lives_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000003'::uuid,
    1,
    '2026-11-06 11:30:00+00'::timestamptz,
    'Done'
  )
  $$,
  'Owner A completes session for Routine C'
);

-- Delete Routine C
RESET ROLE;
DELETE FROM public.user_workout_routines WHERE id = 'aaaaaaaa-1111-0000-0000-000000000005';

-- Replay start RPC for Routine C session after routine is deleted: succeeds idempotently!
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
SELECT lives_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'aaaaaaaa-aaaa-0000-0000-000000000003'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
      'aaaaaaaa-1111-0000-0000-000000000005'::uuid,
      '2026-11-06 11:00:00+00'::timestamptz,
      '2026-11-06'::date,
      %L::jsonb
    )
    $$,
    :'valid_snapshot_c'
  ),
  'Start replay succeeds idempotently even after source routine is deleted'
);

-- ============================================================================
-- 43-44. Legitimate User Account Deletion Cascade
-- ============================================================================
RESET ROLE;
DELETE FROM auth.users WHERE id = '11111111-1111-1111-1111-111111111111';

SELECT is(
  (SELECT count(*)::integer FROM public.user_workout_sessions WHERE user_id = '11111111-1111-1111-1111-111111111111'),
  0,
  'Account cascade deletion removes all Owner A sessions cleanly'
);

SELECT is(
  (SELECT count(*)::integer FROM public.user_workout_performed_sets WHERE user_id = '11111111-1111-1111-1111-111111111111'),
  0,
  'Account cascade deletion removes all Owner A performed sets cleanly'
);

SELECT * FROM finish();
ROLLBACK;
