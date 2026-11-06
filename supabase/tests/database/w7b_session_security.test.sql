BEGIN;
SELECT plan(22);

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

INSERT INTO public.user_workout_programs (id, user_id, name) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Program A'),
  ('bbbbbbbb-2222-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'Program B')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_workout_routines (id, user_id, program_id, name) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000001', 'Routine A'),
  ('bbbbbbbb-2222-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-2222-0000-0000-000000000002', 'Routine B')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_workout_routine_exercises (id, user_id, routine_id, position, catalog_exercise_id) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000002', 0, 'ex_barbell_bench_press')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_workout_routine_sets (id, user_id, routine_exercise_id, position, set_type, reps, load_kg, rest_seconds) VALUES
  ('aaaaaaaa-1111-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-1111-0000-0000-000000000003', 0, 'normal', 10, 100.0, 90)
ON CONFLICT (id) DO NOTHING;

-- Valid snapshot matching Routine A
\set valid_snapshot '{"schema_version":1,"routine_id":"aaaaaaaa-1111-0000-0000-000000000002","program_id":"aaaaaaaa-1111-0000-0000-000000000001","routine_name":"Routine A","captured_at_utc":"2026-11-06T00:00:00Z","exercises":[{"exercise_ref":"ex_barbell_bench_press","display_name":"Barbell Bench Press","exercise_type":"weight_reps","occurrence_index":0,"prescribed_sets":[{"set_type":"normal","reps":10,"load_kg":100.0,"rest_seconds":90}]}]}'

-- ============================================================================
-- 1-4. Direct Authenticated DML Denial Tests
-- ============================================================================
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" = '11111111-1111-1111-1111-111111111111';

-- 1. Direct INSERT on user_workout_sessions denied
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

-- 2. Direct INSERT on user_workout_performed_sets denied
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

-- 3. Direct UPDATE on user_workout_sessions denied
SELECT throws_ok(
  $$
  UPDATE public.user_workout_sessions SET notes = 'tampered'
  $$,
  '42501',
  'permission denied for table user_workout_sessions',
  'Direct UPDATE on user_workout_sessions must be denied to authenticated users'
);

-- 4. Direct DELETE on user_workout_sessions denied
SELECT throws_ok(
  $$
  DELETE FROM public.user_workout_sessions
  $$,
  '42501',
  'permission denied for table user_workout_sessions',
  'Direct DELETE on user_workout_sessions must be denied to authenticated users'
);

-- ============================================================================
-- 5. Forged Source Routine/Program Failure in RPC
-- ============================================================================
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
    :'valid_snapshot'
  ),
  '42501',
  'invalid_routine_or_unauthorized',
  'Owner A cannot start workout using Owner B routine'
);

-- ============================================================================
-- 6. Valid Session Start via RPC
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
-- 7. Owner-Only SELECT via RLS
-- ============================================================================
SET LOCAL "request.jwt.claim.sub" = '22222222-2222-2222-2222-222222222222'; -- Switch to Owner B
SELECT is(
  (SELECT count(*)::integer FROM public.user_workout_sessions WHERE id = 'aaaaaaaa-aaaa-0000-0000-000000000001'),
  0,
  'Owner B cannot view Owner A session via SELECT'
);

-- ============================================================================
-- 8. Cross-User Performed-Set Foreign Key Protection
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
-- 9. Single Active Session Invariant (Partial Unique Index)
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
-- 10. Valid Set Logging
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
-- 11. Slot Collision Rejection on Active Session
-- ============================================================================
SELECT throws_ok(
  $$
  SELECT public.rpc_log_workout_performed_set(
    'cccccccc-cccc-0000-0000-000000000002'::uuid, -- Different set ID
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    2, -- Revision 2
    'ex_barbell_bench_press',
    0, 0, -- Same slot (0, 0)
    12, 105.0, null, null, '2026-11-06 10:03:00+00'::timestamptz, false, 'Conflicting set'
  )
  $$,
  '23505',
  'duplicate key value violates unique constraint "uq_user_workout_performed_sets_slot"',
  'Slot unique constraint rejects duplicate set slot in active session'
);

-- ============================================================================
-- 12. Pause Session
-- ============================================================================
SELECT lives_ok(
  $$
  SELECT public.rpc_pause_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    2,
    '2026-11-06 10:10:00+00'::timestamptz
  )
  $$,
  'Owner A pauses session successfully'
);

-- ============================================================================
-- 13. Resume Session (adds 5 minutes = 300,000,000 microseconds)
-- ============================================================================
SELECT lives_ok(
  $$
  SELECT public.rpc_resume_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    3,
    '2026-11-06 10:15:00+00'::timestamptz
  )
  $$,
  'Owner A resumes session successfully'
);

-- ============================================================================
-- 14. WorkoutTime Reconstruction & Microsecond Pause Fidelity
-- ============================================================================
SELECT is(
  (SELECT accumulated_paused_microseconds FROM public.user_workout_sessions WHERE id = 'aaaaaaaa-aaaa-0000-0000-000000000001'),
  300000000::bigint,
  'Accumulated paused microseconds computed with exact 1:1 microsecond fidelity'
);

-- ============================================================================
-- 15. Stale Revision Conflict Protection (OCC)
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
-- 16. Idempotent Retry of Resume
-- ============================================================================
SELECT lives_ok(
  $$
  SELECT public.rpc_resume_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    4,
    '2026-11-06 10:15:00+00'::timestamptz
  )
  $$,
  'Duplicate resume call at matching watermark succeeds idempotently'
);

-- ============================================================================
-- 17. Session Completion
-- ============================================================================
SELECT lives_ok(
  $$
  SELECT public.rpc_complete_workout_session(
    'aaaaaaaa-aaaa-0000-0000-000000000001'::uuid,
    4,
    '2026-11-06 10:30:00+00'::timestamptz,
    'Great workout'
  )
  $$,
  'Owner A completes session successfully'
);

-- ============================================================================
-- 18. Parent Terminal Immutability
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
-- 19. Child Terminal Immutability
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
-- 20. Source Routine Deletion Preserves Workout History
-- ============================================================================
DELETE FROM public.user_workout_routines WHERE id = 'aaaaaaaa-1111-0000-0000-000000000002';
SELECT is(
  (SELECT count(*)::integer FROM public.user_workout_sessions WHERE id = 'aaaaaaaa-aaaa-0000-0000-000000000001'),
  1,
  'Workout history preserved completely after source routine deletion'
);

-- ============================================================================
-- 21. Malformed Snapshot Rejection
-- ============================================================================
SELECT is(
  private.is_valid_workout_session_snapshot_v1('{"schema_version": 2}'::jsonb),
  false,
  'Snapshot validator rejects unsupported schema version'
);

-- ============================================================================
-- 22. Legitimate User Account Deletion Cascade
-- ============================================================================
DELETE FROM auth.users WHERE id = '11111111-1111-1111-1111-111111111111';
SELECT is(
  (SELECT count(*)::integer FROM public.user_workout_sessions WHERE user_id = '11111111-1111-1111-1111-111111111111'),
  0,
  'Account cascade deletion removes all sessions cleanly without trigger blockage'
);

SELECT * FROM finish();
ROLLBACK;
