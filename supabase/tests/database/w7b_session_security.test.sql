\set ON_ERROR_STOP on
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap SCHEMA extensions;
SELECT plan(82);

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

-- 13. Routine Name Integrity: Stale routine_name in snapshot is rejected (Finding 4492021721)
SELECT throws_ok(
  $$
  SELECT public.rpc_start_workout_session(
    gen_random_uuid(),
    'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
    'aaaaaaaa-1111-0000-0000-000000000002'::uuid,
    '2026-11-06 10:00:00+00'::timestamptz,
    '2026-11-06'::date,
    '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000002","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"Stale Routine Name","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90}]}]}'::jsonb
  )
  $$,
  '22023',
  'snapshot_routine_name_mismatch',
  'Snapshot stale routine_name mismatch with routine is rejected'
);

-- 14. Routine Name Integrity: Forged routine_name in snapshot is rejected (Finding 4492021721)
SELECT throws_ok(
  $$
  SELECT public.rpc_start_workout_session(
    gen_random_uuid(),
    'aaaaaaaa-1111-0000-0000-000000000001'::uuid,
    'aaaaaaaa-1111-0000-0000-000000000002'::uuid,
    '2026-11-06 10:00:00+00'::timestamptz,
    '2026-11-06'::date,
    '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000002","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"Forged Super Routine","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90}]}]}'::jsonb
  )
  $$,
  '22023',
  'snapshot_routine_name_mismatch',
  'Snapshot forged routine_name mismatch with routine is rejected'
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

-- Terminal Replay Identity: Exact complete retry with identical notes succeeds idempotently (Finding 4492021727)
SELECT lives_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    6,
    '2026-11-06 10:30:00+00'::timestamptz,
    'Great workout'
  )
  $$,
  'Exact matching complete retry with identical notes succeeds idempotently'
);

-- Terminal Replay Identity: Complete retry with whitespace-normalized notes succeeds idempotently (Finding 4492021727)
SELECT lives_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    6,
    '2026-11-06 10:30:00+00'::timestamptz,
    '   Great workout   '
  )
  $$,
  'Complete retry with whitespace-normalized notes succeeds idempotently'
);

-- Terminal Replay Identity: Complete retry with conflicting notes is rejected (Finding 4492021727)
SELECT throws_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    6,
    '2026-11-06 10:30:00+00'::timestamptz,
    'Different notes'
  )
  $$,
  '23505',
  'terminal_payload_conflict',
  'Complete retry with conflicting notes is rejected with terminal_payload_conflict'
);

-- Terminal Replay Identity: Complete retry with NULL notes when completed with notes is rejected (Finding 4492021727)
SELECT throws_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    6,
    '2026-11-06 10:30:00+00'::timestamptz,
    null
  )
  $$,
  '23505',
  'terminal_payload_conflict',
  'Complete retry with NULL notes when original had notes is rejected with terminal_payload_conflict'
);

-- Discard and Discard Replay Identity: Owner B discards session (Finding 4492021727)
SET LOCAL "request.jwt.claim.sub" = '22222222-2222-2222-2222-222222222222';
SELECT lives_ok(
  $$
  SELECT public.rpc_discard_workout_session(
    'bbbbbbbb-bbbb-0000-0000-000000000001'::uuid,
    2,
    '2026-11-06 10:10:00+00'::timestamptz,
    'Too tired to continue'
  )
  $$,
  'Owner B discards active session successfully with reason'
);

-- Discard Replay Identity: Exact matching discard retry succeeds idempotently (Finding 4492021727)
SELECT lives_ok(
  $$
  SELECT public.rpc_discard_workout_session(
    'bbbbbbbb-bbbb-0000-0000-000000000001'::uuid,
    3,
    '2026-11-06 10:10:00+00'::timestamptz,
    'Too tired to continue'
  )
  $$,
  'Exact matching discard retry succeeds idempotently'
);

-- Discard Replay Identity: Discard retry with whitespace-normalized reason succeeds idempotently (Finding 4492021727)
SELECT lives_ok(
  $$
  SELECT public.rpc_discard_workout_session(
    'bbbbbbbb-bbbb-0000-0000-000000000001'::uuid,
    3,
    '2026-11-06 10:10:00+00'::timestamptz,
    '   Too tired to continue   '
  )
  $$,
  'Discard retry with whitespace-normalized reason succeeds idempotently'
);

-- Discard Replay Identity: Discard retry with conflicting reason is rejected (Finding 4492021727)
SELECT throws_ok(
  $$
  SELECT public.rpc_discard_workout_session(
    'bbbbbbbb-bbbb-0000-0000-000000000001'::uuid,
    3,
    '2026-11-06 10:10:00+00'::timestamptz,
    'Equipment failure'
  )
  $$,
  '23505',
  'terminal_payload_conflict',
  'Discard retry with conflicting reason is rejected with terminal_payload_conflict'
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
-- 41. Source Routine Renaming & Deletion Preserves Workout History
-- ============================================================================
-- Rename Routine A to test start replay preservation after rename (Finding 4492021721)
UPDATE public.user_workout_routines SET name = 'Renamed Routine A' WHERE id = 'aaaaaaaa-1111-0000-0000-000000000002';
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';
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
  'Start replay succeeds idempotently even after source routine is renamed'
);
RESET ROLE;

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

-- Complete session for Routine C with NULL notes
SELECT lives_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000003'::uuid,
    1,
    '2026-11-06 11:30:00+00'::timestamptz,
    null
  )
  $$,
  'Owner A completes session for Routine C with NULL notes'
);

-- Terminal Replay Identity: Exact complete retry with NULL notes succeeds idempotently (Finding 4492021727)
SELECT lives_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000003'::uuid,
    2,
    '2026-11-06 11:30:00+00'::timestamptz,
    null
  )
  $$,
  'Exact matching complete retry with NULL notes succeeds idempotently'
);

-- Terminal Replay Identity: Complete retry with whitespace-only notes normalizes to NULL (Finding 4492021727)
SELECT lives_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000003'::uuid,
    2,
    '2026-11-06 11:30:00+00'::timestamptz,
    '    '
  )
  $$,
  'Complete retry with whitespace-only notes normalizes to NULL and succeeds idempotently'
);

-- Terminal Replay Identity: Complete retry with non-NULL notes when original had NULL is rejected (Finding 4492021727)
SELECT throws_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000003'::uuid,
    2,
    '2026-11-06 11:30:00+00'::timestamptz,
    'Belated notes'
  )
  $$,
  '23505',
  'terminal_payload_conflict',
  'Complete retry with non-NULL notes when original had NULL is rejected with terminal_payload_conflict'
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
-- 43. Snapshot Hardening, Mutation Recovery, Monotonic Replays, Bounds & Quota
-- ============================================================================
RESET ROLE;

-- 61. Snapshot rejects unknown root key
SELECT is(
  private.is_valid_workout_session_snapshot_v1(
    '{"schema_version":1,"routine_id":"11111111-1111-1111-1111-111111111111","program_id":"22222222-2222-2222-2222-222222222222","routine_name":"R","captured_at_utc":"2026-11-06T00:00:00Z","junk":"data","exercises":[{"exercise_ref":"ex_bench","display_name":"Bench","occurrence_index":0,"prescribed_sets":[]}]}'::jsonb
  ),
  false,
  'Snapshot validator rejects payload with unknown root keys'
);

-- 62. Snapshot rejects magic timestamp 'now'
SELECT is(
  private.is_valid_workout_session_snapshot_v1(
    '{"schema_version":1,"routine_id":"11111111-1111-1111-1111-111111111111","program_id":"22222222-2222-2222-2222-222222222222","routine_name":"R","captured_at_utc":"now","exercises":[{"exercise_ref":"ex_bench","display_name":"Bench","occurrence_index":0,"prescribed_sets":[]}]}'::jsonb
  ),
  false,
  'Snapshot validator rejects magic timestamp string now'
);

-- 63. Snapshot rejects oversized payload > 256 KiB
SELECT is(
  private.is_valid_workout_session_snapshot_v1(
    jsonb_build_object(
      'schema_version', 1,
      'routine_id', '11111111-1111-1111-1111-111111111111'::uuid,
      'program_id', '22222222-2222-2222-2222-222222222222'::uuid,
      'routine_name', repeat('R', 100),
      'captured_at_utc', '2026-11-06T00:00:00Z',
      'exercises', jsonb_build_array(
        jsonb_build_object('exercise_ref', 'ex_bench', 'display_name', repeat('E', 100), 'occurrence_index', 0, 'prescribed_sets', '[]'::jsonb)
      )
    ) || jsonb_build_object('junk', repeat('X', 300000))
  ),
  false,
  'Snapshot validator rejects oversized payload exceeding 256 KiB'
);

-- 64. Snapshot validator accepts routine_name and exercise display_name longer than 100 characters
SELECT is(
  private.is_valid_workout_session_snapshot_v1(
    jsonb_build_object(
      'schema_version', 1,
      'routine_id', '11111111-1111-1111-1111-111111111111'::uuid,
      'program_id', '22222222-2222-2222-2222-222222222222'::uuid,
      'routine_name', repeat('R', 120),
      'captured_at_utc', '2026-11-06T00:00:00Z',
      'exercises', jsonb_build_array(
        jsonb_build_object('exercise_ref', 'ex_bench', 'display_name', repeat('E', 120), 'occurrence_index', 0, 'prescribed_sets', '[]'::jsonb)
      )
    )
  ),
  true,
  'Snapshot validator accepts routine_name and display_name longer than 100 characters'
);

-- 65. Snapshot validator rejects whitespace-only blank routine_name
SELECT is(
  private.is_valid_workout_session_snapshot_v1(
    jsonb_build_object(
      'schema_version', 1,
      'routine_id', '11111111-1111-1111-1111-111111111111'::uuid,
      'program_id', '22222222-2222-2222-2222-222222222222'::uuid,
      'routine_name', '   ',
      'captured_at_utc', '2026-11-06T00:00:00Z',
      'exercises', jsonb_build_array(
        jsonb_build_object('exercise_ref', 'ex_bench', 'display_name', 'Valid Exercise', 'occurrence_index', 0, 'prescribed_sets', '[]'::jsonb)
      )
    )
  ),
  false,
  'Snapshot validator rejects whitespace-only blank routine_name'
);

-- 66. Snapshot validator rejects whitespace-only blank exercise display_name
SELECT is(
  private.is_valid_workout_session_snapshot_v1(
    jsonb_build_object(
      'schema_version', 1,
      'routine_id', '11111111-1111-1111-1111-111111111111'::uuid,
      'program_id', '22222222-2222-2222-2222-222222222222'::uuid,
      'routine_name', 'Valid Routine',
      'captured_at_utc', '2026-11-06T00:00:00Z',
      'exercises', jsonb_build_array(
        jsonb_build_object('exercise_ref', 'ex_bench', 'display_name', '   ', 'occurrence_index', 0, 'prescribed_sets', '[]'::jsonb)
      )
    )
  ),
  false,
  'Snapshot validator rejects whitespace-only blank exercise display_name'
);

-- Fixture for RPC tests
RESET ROLE;
INSERT INTO auth.users (id, email) VALUES ('33333333-3333-3333-3333-333333333333', 'owner_c@tio.test') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.users (id, email) VALUES ('33333333-3333-3333-3333-333333333333', 'owner_c@tio.test') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_programs (id, user_id, name) VALUES ('cccccccc-3333-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 'Program C') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_routines (id, user_id, program_id, name) VALUES ('cccccccc-3333-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333', 'cccccccc-3333-0000-0000-000000000001', 'Routine C') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_routine_exercises (id, user_id, routine_id, position, catalog_exercise_id) VALUES ('cccccccc-3333-0000-0000-000000000003', '33333333-3333-3333-3333-333333333333', 'cccccccc-3333-0000-0000-000000000002', 0, 'ex_bench_press') ON CONFLICT (id) DO NOTHING;

\set valid_snap_c '{"schema_version":1,"routine_id":"cccccccc-3333-0000-0000-000000000002","program_id":"cccccccc-3333-0000-0000-000000000001","routine_name":"Routine C","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_bench_press","display_name":"Bench","occurrence_index":0,"prescribed_sets":[]}]}'

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '33333333-3333-3333-3333-333333333333';

-- Start session (rev 1)
SELECT public.rpc_start_workout_session(
  'cccccccc-cccc-0000-0000-000000000001'::uuid,
  'cccccccc-3333-0000-0000-000000000001'::uuid,
  'cccccccc-3333-0000-0000-000000000002'::uuid,
  '2026-11-06 10:00:00+00'::timestamptz,
  '2026-11-06'::date,
  :'valid_snap_c'::jsonb
);

-- Log Set 1 (rev 1 -> rev 2)
SELECT public.rpc_log_workout_performed_set(
  'cccccccc-5555-0000-0000-000000000001'::uuid,
  'cccccccc-cccc-0000-0000-000000000001'::uuid,
  1,
  'ex_bench_press',
  0,
  0,
  10,
  100.0,
  null, null, null, false, 'First set'
);

-- 65. Session revision check after first set log
SELECT is(
  (
    SELECT revision FROM public.user_workout_sessions WHERE id = 'cccccccc-cccc-0000-0000-000000000001'::uuid
  ),
  2,
  'Session revision is 2 after first set log'
);

-- 66. Exact Log Set retry with original revision (1) returns existing set and leaves revision at 2
SELECT lives_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'cccccccc-5555-0000-0000-000000000001'::uuid,
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    1,
    'ex_bench_press',
    0,
    0,
    10,
    100.0,
    null, null, null, false, 'First set'
  )
  $$,
  'Identical Log Set retry with original revision succeeds idempotently'
);

-- 67. Log Set retry with same set_id but altered payload and stale revision throws P0003
SELECT throws_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'cccccccc-5555-0000-0000-000000000001'::uuid,
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    1,
    'ex_bench_press',
    0,
    0,
    12,
    100.0,
    null, null, null, false, 'First set'
  )
  $$,
  'P0003',
  'stale_revision_conflict',
  'Log Set with conflicting payload and stale revision throws stale_revision_conflict'
);

-- Pause at T1 (rev 2 -> 3)
SELECT public.rpc_pause_workout_session(
  'cccccccc-cccc-0000-0000-000000000001'::uuid,
  2,
  '2026-11-06 10:15:00+00'::timestamptz
);

-- Log Set 2 while paused (rev 3 -> 4)
SELECT public.rpc_log_workout_performed_set(
  'cccccccc-5555-0000-0000-000000000002'::uuid,
  'cccccccc-cccc-0000-0000-000000000001'::uuid,
  3,
  'ex_bench_press',
  0,
  1,
  8,
  105.0
);

-- 68. Pause replay at T1 with original expected revision 2 succeeds after intervening set mutation (rev 4)
SELECT lives_ok(
  $$
  SELECT public.rpc_pause_workout_session(
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    2,
    '2026-11-06 10:15:00+00'::timestamptz
  )
  $$,
  'Pause replay with identical timestamp succeeds idempotently after intervening set mutations'
);

-- Resume at T2 (rev 4 -> 5)
SELECT public.rpc_resume_workout_session(
  'cccccccc-cccc-0000-0000-000000000001'::uuid,
  4,
  '2026-11-06 10:20:00+00'::timestamptz
);

-- Log Set 3 while active (rev 5 -> 6)
SELECT public.rpc_log_workout_performed_set(
  'cccccccc-5555-0000-0000-000000000003'::uuid,
  'cccccccc-cccc-0000-0000-000000000001'::uuid,
  5,
  'ex_bench_press',
  0,
  2,
  6,
  110.0
);

-- 69. Resume replay at T2 with original expected revision 4 succeeds after intervening set mutation (rev 6)
SELECT lives_ok(
  $$
  SELECT public.rpc_resume_workout_session(
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    4,
    '2026-11-06 10:20:00+00'::timestamptz
  )
  $$,
  'Resume replay with identical timestamp succeeds idempotently after intervening set mutations'
);

-- 70. Valid set removal increments session revision (rev 6 -> 7)
SELECT lives_ok(
  $$
  SELECT public.rpc_remove_workout_performed_set(
    'cccccccc-5555-0000-0000-000000000003'::uuid,
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    6
  )
  $$,
  'Valid set removal succeeds and increments revision'
);

-- 71. Set removal retry on already removed set throws stale_revision_conflict or set_not_found for read-after-write
SELECT throws_ok(
  $$
  SELECT public.rpc_remove_workout_performed_set(
    'cccccccc-5555-0000-0000-000000000003'::uuid,
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    6
  )
  $$,
  'P0003',
  'stale_revision_conflict',
  'Removal retry with original revision throws stale_revision_conflict'
);

-- 72. Performed set with set_index = 1000 is rejected by check constraint
SELECT throws_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'cccccccc-5555-0000-0000-000000000004'::uuid,
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    7,
    'ex_bench_press',
    0,
    1000,
    5,
    100.0
  )
  $$,
  '22023',
  'invalid_set_index',
  'Set with set_index = 1000 is rejected by RPC validation'
);

-- 73. Notes exceeding 65,536 bytes rejected by check constraint
SELECT throws_ok(
  format(
    $$
    SELECT public.rpc_log_workout_performed_set(
      'cccccccc-5555-0000-0000-000000000005'::uuid,
      'cccccccc-cccc-0000-0000-000000000001'::uuid,
      7,
      'ex_bench_press',
      0,
      3,
      5,
      100.0,
      null, null, null, false, %L
    )
    $$,
    repeat('N', 65537)
  ),
  '23514',
  NULL,
  'Performed set with notes exceeding 65,536 bytes is rejected by check constraint'
);

-- 74. RPC parameter NULL check rejects missing session_id
SELECT throws_ok(
  $$
  SELECT public.rpc_pause_workout_session(
    NULL,
    7,
    '2026-11-06 10:30:00+00'::timestamptz
  )
  $$,
  '22023',
  'missing_session_id',
  'Pause RPC rejects NULL session_id with 22023'
);

-- 75. RPC parameter NULL check rejects missing expected_revision
SELECT throws_ok(
  $$
  SELECT public.rpc_pause_workout_session(
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    NULL,
    '2026-11-06 10:30:00+00'::timestamptz
  )
  $$,
  '22023',
  'invalid_expected_revision',
  'Pause RPC rejects NULL expected_revision with 22023'
);

-- 76. Start RPC rejects start timestamp before plausibility window (2015)
SELECT throws_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'cccccccc-cccc-0000-0000-000000000099'::uuid,
      'cccccccc-3333-0000-0000-000000000001'::uuid,
      'cccccccc-3333-0000-0000-000000000002'::uuid,
      '2015-01-01 00:00:00+00'::timestamptz,
      '2015-01-01'::date,
      %L::jsonb
    )
    $$,
    :'valid_snap_c'
  ),
  '22023',
  'invalid_timestamp_range',
  'Start RPC rejects start timestamp before plausibility window (2015)'
);

-- 77. 500-set quota check: insert up to 500 sets, then 501st set fails with session_performed_sets_limit_exceeded
RESET ROLE;
-- Session currently has 2 sets (set 1 and set 2; set 3 was deleted). Insert 498 more sets to reach 500 sets
INSERT INTO public.user_workout_performed_sets (
  id, session_id, user_id, exercise_ref, session_exercise_index, set_index, reps, load_kg
)
SELECT
  gen_random_uuid(), 'cccccccc-cccc-0000-0000-000000000001'::uuid, '33333333-3333-3333-3333-333333333333'::uuid,
  'ex_bench_press', 0, 3 + s, 10, 100.0
FROM generate_series(0, 497) s;

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '33333333-3333-3333-3333-333333333333';

SELECT throws_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'cccccccc-5555-0000-0000-000000000501'::uuid,
    'cccccccc-cccc-0000-0000-000000000001'::uuid,
    7,
    'ex_bench_press',
    0,
    501,
    10,
    100.0
  )
  $$,
  '22023',
  'session_performed_sets_limit_exceeded',
  'Attempt to log 501st set in session is rejected with session_performed_sets_limit_exceeded'
);

RESET ROLE;

-- Fixture for Owner D long-name tests (>100 characters compatibility)
RESET ROLE;
INSERT INTO auth.users (id, email) VALUES ('44444444-4444-4444-4444-444444444444', 'owner_d@tio.test') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.users (id, email) VALUES ('44444444-4444-4444-4444-444444444444', 'owner_d@tio.test') ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_workout_programs (id, user_id, name) VALUES ('dddddddd-4444-0000-0000-000000000001', '44444444-4444-4444-4444-444444444444', 'Program D') ON CONFLICT (id) DO NOTHING;

\set long_routine_name 'Super Advanced Hypertrophy & Periodization Routine With Ultra Comprehensive Name That Comfortably Exceeds One Hundred Chars'
INSERT INTO public.user_workout_routines (id, user_id, program_id, name) VALUES (
  'dddddddd-4444-0000-0000-000000000002',
  '44444444-4444-4444-4444-444444444444',
  'dddddddd-4444-0000-0000-000000000001',
  :'long_routine_name'
) ON CONFLICT (id) DO NOTHING;

\set long_exercise_name 'Incline Dumbbell Bench Press With Three Second Eccentric Pause And Full Range Of Motion At Chest Level Custom Variation'
INSERT INTO public.user_workout_exercises (id, user_id, display_name, exercise_type) VALUES (
  'dddddddd-4444-0000-0000-000000000010',
  '44444444-4444-4444-4444-444444444444',
  :'long_exercise_name',
  'dumbbell_x2_simultaneous'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_workout_routine_exercises (id, user_id, routine_id, position, user_exercise_id) VALUES (
  'dddddddd-4444-0000-0000-000000000003',
  '44444444-4444-4444-4444-444444444444',
  'dddddddd-4444-0000-0000-000000000002',
  0,
  'dddddddd-4444-0000-0000-000000000010'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_workout_routine_sets (id, user_id, routine_exercise_id, position, set_type, reps, load_kg, rest_seconds) VALUES (
  'dddddddd-4444-0000-0000-000000000004',
  '44444444-4444-4444-4444-444444444444',
  'dddddddd-4444-0000-0000-000000000003',
  0,
  'normal',
  8,
  32.5,
  120
) ON CONFLICT (id) DO NOTHING;

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '44444444-4444-4444-4444-444444444444';

-- 78. Start workout with >100 char routine name and >100 char custom exercise name succeeds
SELECT lives_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'dddddddd-dddd-0000-0000-000000000001'::uuid,
      'dddddddd-4444-0000-0000-000000000001'::uuid,
      'dddddddd-4444-0000-0000-000000000002'::uuid,
      '2026-11-06 16:00:00+00'::timestamptz,
      '2026-11-06'::date,
      jsonb_build_object(
        'schema_version', 1,
        'routine_id', 'dddddddd-4444-0000-0000-000000000002'::uuid,
        'program_id', 'dddddddd-4444-0000-0000-000000000001'::uuid,
        'routine_name', %L,
        'captured_at_utc', '2026-11-06T16:00:00Z',
        'exercises', jsonb_build_array(
          jsonb_build_object(
            'exercise_ref', 'dddddddd-4444-0000-0000-000000000010'::uuid,
            'display_name', %L,
            'exercise_type', 'dumbbell_x2_simultaneous',
            'occurrence_index', 0,
            'prescribed_sets', jsonb_build_array(
              jsonb_build_object('set_type', 'normal', 'reps', 8, 'load_kg', 32.5, 'rest_seconds', 120)
            )
          )
        )
      )
    )
    $$,
    :'long_routine_name',
    :'long_exercise_name'
  ),
  'Start workout session succeeds with Routine and Custom Exercise names longer than 100 characters'
);

-- 79. Start workout session rejects snapshot when custom exercise display name differs from authoritative source
SELECT throws_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'dddddddd-dddd-0000-0000-000000000002'::uuid,
      'dddddddd-4444-0000-0000-000000000001'::uuid,
      'dddddddd-4444-0000-0000-000000000002'::uuid,
      '2026-11-06 16:30:00+00'::timestamptz,
      '2026-11-06'::date,
      jsonb_build_object(
        'schema_version', 1,
        'routine_id', 'dddddddd-4444-0000-0000-000000000002'::uuid,
        'program_id', 'dddddddd-4444-0000-0000-000000000001'::uuid,
        'routine_name', %L,
        'captured_at_utc', '2026-11-06T16:30:00Z',
        'exercises', jsonb_build_array(
          jsonb_build_object(
            'exercise_ref', 'dddddddd-4444-0000-0000-000000000010'::uuid,
            'display_name', 'Tampered Custom Exercise Name',
            'exercise_type', 'dumbbell_x2_simultaneous',
            'occurrence_index', 0,
            'prescribed_sets', jsonb_build_array(
              jsonb_build_object('set_type', 'normal', 'reps', 8, 'load_kg', 32.5, 'rest_seconds', 120)
            )
          )
        )
      )
    )
    $$,
    :'long_routine_name'
  ),
  '22023',
  'snapshot_custom_exercise_metadata_mismatch',
  'Start RPC rejects snapshot when custom exercise display name differs from authoritative database record'
);

-- 80. Start workout session rejects snapshot when routine name differs from authoritative source (long name mismatch)
SELECT throws_ok(
  format(
    $$
    SELECT public.rpc_start_workout_session(
      'dddddddd-dddd-0000-0000-000000000003'::uuid,
      'dddddddd-4444-0000-0000-000000000001'::uuid,
      'dddddddd-4444-0000-0000-000000000002'::uuid,
      '2026-11-06 17:00:00+00'::timestamptz,
      '2026-11-06'::date,
      jsonb_build_object(
        'schema_version', 1,
        'routine_id', 'dddddddd-4444-0000-0000-000000000002'::uuid,
        'program_id', 'dddddddd-4444-0000-0000-000000000001'::uuid,
        'routine_name', 'Tampered Long Routine Name',
        'captured_at_utc', '2026-11-06T17:00:00Z',
        'exercises', jsonb_build_array(
          jsonb_build_object(
            'exercise_ref', 'dddddddd-4444-0000-0000-000000000010'::uuid,
            'display_name', %L,
            'exercise_type', 'dumbbell_x2_simultaneous',
            'occurrence_index', 0,
            'prescribed_sets', jsonb_build_array(
              jsonb_build_object('set_type', 'normal', 'reps', 8, 'load_kg', 32.5, 'rest_seconds', 120)
            )
          )
        )
      )
    )
    $$,
    :'long_exercise_name'
  ),
  '22023',
  'snapshot_routine_name_mismatch',
  'Start RPC rejects snapshot when routine name differs from authoritative database record'
);

RESET ROLE;

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
