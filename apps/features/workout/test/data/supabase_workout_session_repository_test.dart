import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-a111-111111111111';
const _otherOwner = '99999999-9999-4999-a999-999999999999';
final _sessionId = WorkoutSessionId('22222222-2222-4222-a222-222222222222');
final _programId = ProgramId('33333333-3333-4333-a333-333333333333');
final _routineId = RoutineId('44444444-4444-4444-a444-444444444444');
final _startedAt = DateTime.utc(2026, 11, 7, 10, 0, 0);

WorkoutSessionSnapshot _mockSnapshot() => WorkoutSessionSnapshot(
      routineId: _routineId,
      routineName: 'Upper Body Blast',
      programId: _programId,
      capturedAtUtc: _startedAt,
      exercises: [
        SessionExerciseSnapshot(
          exerciseRef: CatalogExerciseRef('ex_bench_press'),
          displayName: 'Bench Press',
          occurrenceIndex: 0,
          prescribedSets: [
            SetPrescription(setType: RoutineSetType.normal, reps: 8, loadKg: 80.0),
          ],
        ),
      ],
    );

WorkoutSession _mockSession({
  WorkoutSessionStatus status = WorkoutSessionStatus.active,
  DateTime? pausedAt,
  int pausedUs = 0,
  List<PerformedSet> sets = const [],
  String? notes,
  String? workoutTitle,
  DateTime? workoutAtUtc,
  int? workoutUtcOffsetMinutes,
  String? discardReason,
}) =>
    WorkoutSession(
      id: _sessionId,
      userId: _owner,
      programId: _programId,
      routineId: _routineId,
      status: status,
      time: WorkoutTime(
        startedAtUtc: _startedAt,
        pausedAtUtc: pausedAt,
        accumulatedPausedDuration: Duration(microseconds: pausedUs),
        completedAtUtc: status.isTerminal ? pausedAt ?? _startedAt : null,
        lastTransitionAtUtc: pausedAt ?? _startedAt,
      ),
      localDate: '2026-11-07',
      snapshot: _mockSnapshot(),
      performedSets: sets,
      notes: notes,
      workoutTitle: workoutTitle,
      workoutAtUtc: workoutAtUtc,
      workoutUtcOffsetMinutes: workoutUtcOffsetMinutes,
      discardReason: discardReason,
    );

Map<String, dynamic> _mockSessionRow({
  int revision = 1,
  String status = 'active',
  DateTime? pausedAt,
  DateTime? completedAt,
  DateTime? lastTransitionAt,
  int pausedUs = 0,
  String? notes,
  String? workoutTitle,
  DateTime? workoutAtUtc,
  int? workoutUtcOffsetMinutes,
  String? discardReason,
}) =>
    {
      'id': _sessionId.value,
      'user_id': _owner,
      'program_id': _programId.value,
      'routine_id': _routineId.value,
      'status': status,
      'started_at_utc': _startedAt.toIso8601String(),
      'paused_at_utc': pausedAt?.toIso8601String(),
      'completed_at_utc': completedAt?.toIso8601String(),
      'last_transition_at_utc':
          (lastTransitionAt ?? pausedAt ?? completedAt ?? _startedAt)
              .toIso8601String(),
      'accumulated_paused_microseconds': pausedUs,
      'local_date': '2026-11-07',
      'routine_snapshot': WorkoutSessionSnapshotDto.toJson(_mockSnapshot()),
      'notes': notes,
      'workout_title': workoutTitle,
      'workout_at_utc': workoutAtUtc?.toIso8601String(),
      'workout_utc_offset_minutes': workoutUtcOffsetMinutes,
      'discard_reason': discardReason,
      'revision': revision,
      'created_at': _startedAt.toIso8601String(),
      'updated_at':
          (lastTransitionAt ?? pausedAt ?? completedAt ?? _startedAt)
              .toIso8601String(),
    };

Map<String, dynamic> _mockSetRow({
  String setId = '55555555-5555-4555-a555-555555555555',
  int exerciseIndex = 0,
  int setIndex = 0,
  int? reps = 10,
  double? loadKg = 80.0,
}) =>
    {
      'id': setId,
      'session_id': _sessionId.value,
      'user_id': _owner,
      'exercise_ref': 'ex_bench_press',
      'session_exercise_index': exerciseIndex,
      'set_index': setIndex,
      'reps': reps,
      'load_kg': loadKg,
      'duration_seconds': null,
      'distance_meters': null,
      'completed_at_utc': _startedAt.toIso8601String(),
      'is_skipped': false,
      'notes': null,
      'created_at': _startedAt.toIso8601String(),
      'updated_at': _startedAt.toIso8601String(),
    };

final class _FakeGateway implements WorkoutSessionGateway {
  Map<String, dynamic>? activeHeader;
  Map<String, dynamic>? sessionHeader;
  List<Map<String, dynamic>> performedSets = [];
  int readHeaderCallCount = 0;
  int logSetCallCount = 0;
  int removeSetCallCount = 0;
  int pauseCallCount = 0;
  int resumeCallCount = 0;
  int completeCallCount = 0;
  Map<String, dynamic>? lastCompleteParams;
  int discardCallCount = 0;
  List<Map<String, dynamic>> Function()? onReadHeaderSequence;
  Future<Map<String, dynamic>?> Function()? onReadActiveHeader;
  Future<Map<String, dynamic>?> Function(String, String)? onReadSessionHeader;

  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onStart;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onPause;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onResume;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onLogSet;
  Future<void> Function(Map<String, dynamic>)? onRemoveSet;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onComplete;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onDiscard;

  @override
  Future<Map<String, dynamic>?> readActiveSessionHeader(String userId) async =>
      onReadActiveHeader != null
          ? await onReadActiveHeader!()
          : activeHeader;

  @override
  Future<Map<String, dynamic>?> readSessionHeader(
    String userId,
    String sessionId,
  ) async {
    readHeaderCallCount++;
    if (onReadSessionHeader != null) {
      return onReadSessionHeader!(userId, sessionId);
    }
    if (onReadHeaderSequence != null) {
      final seq = onReadHeaderSequence!();
      if (seq.isNotEmpty) return seq.removeAt(0);
    }
    return sessionHeader;
  }

  @override
  Future<List<Map<String, dynamic>>> readPerformedSets(
    String userId,
    String sessionId, {
    int limit = 500,
    int? afterSessionExerciseIndex,
    int? afterSetIndex,
  }) async =>
      performedSets;

  @override
  Future<Map<String, dynamic>> rpcStartWorkoutSession(
    Map<String, dynamic> params,
  ) async =>
      onStart != null
          ? await onStart!(params)
          : _mockSessionRow(revision: 1, status: 'active');

  @override
  Future<Map<String, dynamic>> rpcPauseWorkoutSession(
    Map<String, dynamic> params,
  ) async {
    pauseCallCount++;
    return onPause != null
        ? await onPause!(params)
        : _mockSessionRow(revision: 2, status: 'paused');
  }

  @override
  Future<Map<String, dynamic>> rpcResumeWorkoutSession(
    Map<String, dynamic> params,
  ) async {
    resumeCallCount++;
    return onResume != null
        ? await onResume!(params)
        : _mockSessionRow(revision: 3, status: 'active');
  }

  @override
  Future<Map<String, dynamic>> rpcLogWorkoutPerformedSet(
    Map<String, dynamic> params,
  ) async {
    logSetCallCount++;
    return onLogSet != null ? await onLogSet!(params) : _mockSetRow();
  }

  @override
  Future<void> rpcRemoveWorkoutPerformedSet(Map<String, dynamic> params) async {
    removeSetCallCount++;
    if (onRemoveSet != null) await onRemoveSet!(params);
  }

  @override
  Future<Map<String, dynamic>> rpcCompleteWorkoutSession(
    Map<String, dynamic> params,
  ) async {
    completeCallCount++;
    lastCompleteParams = Map<String, dynamic>.from(params);
    return onComplete != null
        ? await onComplete!(params)
        : _mockSessionRow(revision: 4, status: 'completed');
  }

  @override
  Future<Map<String, dynamic>> rpcDiscardWorkoutSession(
    Map<String, dynamic> params,
  ) async {
    discardCallCount++;
    return onDiscard != null
        ? await onDiscard!(params)
        : _mockSessionRow(revision: 5, status: 'discarded');
  }
}

void main() {
  group('SupabaseWorkoutSessionRepository', () {
    late _FakeGateway gateway;
    String? currentUserId;
    late SupabaseWorkoutSessionRepository repo;

    setUp(() {
      gateway = _FakeGateway();
      currentUserId = _owner;
      repo = SupabaseWorkoutSessionRepository(
        gateway: gateway,
        currentUserId: () => currentUserId,
      );
    });

    test('startSession dispatches RPC and returns authoritative record', () async {
      final session = _mockSession();
      final record = await repo.startSession(session);

      expect(record.revision, 1);
      expect(record.syncState, WorkoutSessionSyncState.synced);
      expect(record.session.id, _sessionId);
      expect(record.session.status, WorkoutSessionStatus.active);
    });

    test('startSession rejects cross-user start attempt locally', () async {
      final otherSession = WorkoutSession(
        id: _sessionId,
        userId: _otherOwner,
        programId: _programId,
        routineId: _routineId,
        status: WorkoutSessionStatus.active,
        time: WorkoutTime(startedAtUtc: _startedAt),
        localDate: '2026-11-07',
        snapshot: _mockSnapshot(),
      );

      expect(
        () => repo.startSession(otherSession),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.unauthorized,
        )),
      );
    });

    test('getActiveSession returns null when no active/paused session exists', () async {
      gateway.activeHeader = null;
      final result = await repo.getActiveSession();
      expect(result, isNull);
    });

    test('getActiveSession returns full session with performed sets', () async {
      gateway.activeHeader = _mockSessionRow(revision: 2, status: 'active');
      gateway.sessionHeader = _mockSessionRow(revision: 2, status: 'active');
      gateway.performedSets = [_mockSetRow()];

      final record = await repo.getActiveSession();
      expect(record, isNotNull);
      expect(record!.revision, 2);
      expect(record.session.performedSets.length, 1);
      expect(record.session.performedSets[0].reps, 10);
    });

    test('bracketed read retries when revision changes mid-read and succeeds', () async {
      gateway.activeHeader = _mockSessionRow(revision: 1);
      final sequence = [
        _mockSessionRow(revision: 1), // initial bracket start
        _mockSessionRow(revision: 2), // initial bracket end (mismatch!)
        _mockSessionRow(revision: 2), // retry bracket start
        _mockSessionRow(revision: 2), // retry bracket end (match!)
      ];
      gateway.onReadHeaderSequence = () => sequence;
      gateway.performedSets = [_mockSetRow()];

      final record = await repo.getActiveSession();
      expect(record, isNotNull);
      expect(record!.revision, 2);
    });

    test('bracketed read throws readConflict under sustained contention', () async {
      gateway.sessionHeader = _mockSessionRow(revision: 1);
      var count = 0;
      gateway.onReadHeaderSequence = () => [
            _mockSessionRow(revision: count++),
          ];

      expect(
        () => repo.getSession(_sessionId),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.readConflict,
        )),
      );
    });

    test('pauseSession and resumeSession update status and perform readback', () async {
      final pausedTime = DateTime.utc(2026, 11, 7, 10, 20, 0);
      gateway.sessionHeader = _mockSessionRow(
        revision: 2,
        status: 'paused',
        pausedAt: pausedTime,
      );

      final pausedRecord = await repo.pauseSession(
        sessionId: _sessionId,
        expectedRevision: 1,
        pausedAtUtc: pausedTime,
      );
      expect(pausedRecord.revision, 2);
      expect(pausedRecord.session.status, WorkoutSessionStatus.paused);

      final resumedTime = DateTime.utc(2026, 11, 7, 10, 25, 0);
      gateway.sessionHeader = _mockSessionRow(
        revision: 3,
        status: 'active',
        pausedUs: 300000000,
        lastTransitionAt: resumedTime,
      );

      final resumedRecord = await repo.resumeSession(
        sessionId: _sessionId,
        expectedRevision: 2,
        resumedAtUtc: resumedTime,
      );
      expect(resumedRecord.revision, 3);
      expect(resumedRecord.session.status, WorkoutSessionStatus.active);
      expect(
        resumedRecord.session.time.accumulatedPausedDuration,
        const Duration(minutes: 5),
      );
    });

    test('logPerformedSet dispatches RPC and reads authoritative session revision', () async {
      final set = PerformedSet(
        id: '55555555-5555-4555-a555-555555555555',
        exerciseRef: CatalogExerciseRef('ex_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 12,
        loadKg: 85.0,
      );

      // Server bumped revision from 2 to 3
      gateway.sessionHeader = _mockSessionRow(revision: 3, status: 'active');
      gateway.performedSets = [
        _mockSetRow(reps: 12, loadKg: 85.0),
      ];

      final record = await repo.logPerformedSet(
        sessionId: _sessionId,
        expectedRevision: 2,
        set: set,
      );

      expect(record.revision, 3);
      expect(record.session.performedSets.length, 1);
      expect(record.session.performedSets[0].reps, 12);
      expect(record.session.performedSets[0].loadKg, 85.0);
    });

    test('removePerformedSet dispatches RPC and reads authoritative session', () async {
      gateway.sessionHeader = _mockSessionRow(revision: 4, status: 'active');
      gateway.performedSets = []; // set removed

      final record = await repo.removePerformedSet(
        sessionId: _sessionId,
        expectedRevision: 3,
        setId: '55555555-5555-4555-a555-555555555555',
      );

      expect(record.revision, 4);
      expect(record.session.performedSets, isEmpty);
    });

    test('removePerformedSet does not treat P0002 as successful deletion', () async {
      gateway.onRemoveSet = (_) async {
        throw const PostgrestException(
          message: 'set_not_found',
          code: 'P0002',
        );
      };

      expect(
        () => repo.removePerformedSet(
          sessionId: _sessionId,
          expectedRevision: 3,
          setId: '55555555-5555-4555-a555-555555555555',
        ),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.notFound,
        )),
      );
    });

    test('stale revision conflict (P0003) maps to typed staleRevisionConflict and does not overwrite', () async {
      gateway.onLogSet = (_) async {
        throw const PostgrestException(
          message: 'stale_revision_conflict',
          code: 'P0003',
        );
      };

      final set = PerformedSet(
        id: '55555555-5555-4555-a555-555555555555',
        exerciseRef: CatalogExerciseRef('ex_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
      );

      expect(
        () => repo.logPerformedSet(
          sessionId: _sessionId,
          expectedRevision: 1, // stale!
          set: set,
        ),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.staleRevisionConflict,
        )),
      );
    });

    test('timeout during mutation throws WorkoutSessionMutationOutcomeUnknown', () async {
      gateway.onPause = (_) async {
        throw TimeoutException('In-flight gateway timeout');
      };

      expect(
        () => repo.pauseSession(
          sessionId: _sessionId,
          expectedRevision: 1,
          pausedAtUtc: _startedAt.add(const Duration(minutes: 10)),
        ),
        throwsA(isA<WorkoutSessionMutationOutcomeUnknown>()
            .having(
              (e) => e.sessionId,
              'sessionId',
              _sessionId,
            )
            .having(
              (e) => e.reason,
              'reason',
              WorkoutSessionMutationUncertainty.networkTimeout,
            )),
      );
    });

    test('completeSession and discardSession mark session terminal', () async {
      final finishTime = DateTime.utc(2026, 11, 7, 11, 0, 0);

      gateway.sessionHeader = _mockSessionRow(
        revision: 4,
        status: 'completed',
        completedAt: finishTime,
        notes: 'Great workout',
        workoutTitle: 'Morning Workout',
        workoutAtUtc: finishTime.subtract(const Duration(hours: 1)),
        workoutUtcOffsetMinutes: 330,
      );

      final completedRecord = await repo.completeSession(
        sessionId: _sessionId,
        expectedRevision: 3,
        completedAtUtc: finishTime,
        notes: 'Great workout',
        workoutTitle: 'Morning Workout',
        workoutAtUtc: finishTime.subtract(const Duration(hours: 1)),
        workoutUtcOffsetMinutes: 330,
      );

      expect(completedRecord.session.status, WorkoutSessionStatus.completed);
      expect(completedRecord.session.notes, 'Great workout');
      expect(completedRecord.session.workoutTitle, 'Morning Workout');
      expect(
        completedRecord.session.workoutAtUtc,
        finishTime.subtract(const Duration(hours: 1)),
      );
      expect(completedRecord.session.workoutUtcOffsetMinutes, 330);
      expect(gateway.lastCompleteParams, {
        'p_session_id': _sessionId.value,
        'p_expected_revision': 3,
        'p_completed_at_utc': finishTime.toIso8601String(),
        'p_notes': 'Great workout',
        'p_workout_title': 'Morning Workout',
        'p_workout_at_utc':
            finishTime.subtract(const Duration(hours: 1)).toIso8601String(),
        'p_workout_utc_offset_minutes': 330,
      });
      expect(completedRecord.session.isTerminal, isTrue);

      gateway.sessionHeader = _mockSessionRow(
        revision: 5,
        status: 'discarded',
        completedAt: finishTime,
        discardReason: 'Torn bicep',
      );

      final discardedRecord = await repo.discardSession(
        sessionId: _sessionId,
        expectedRevision: 4,
        discardedAtUtc: finishTime,
        reason: 'Torn bicep',
      );

      expect(discardedRecord.session.status, WorkoutSessionStatus.discarded);
      expect(discardedRecord.session.discardReason, 'Torn bicep');
      expect(discardedRecord.session.isTerminal, isTrue);
    });

    test('completion metadata mismatch remains an unresolved committed write',
        () async {
      final finishTime = DateTime.utc(2026, 11, 7, 11);
      gateway.sessionHeader = _mockSessionRow(
        revision: 4,
        status: 'completed',
        completedAt: finishTime,
        notes: 'Saved notes',
        workoutTitle: 'Morning Workout',
        workoutAtUtc: finishTime.subtract(const Duration(hours: 1)),
        workoutUtcOffsetMinutes: 330,
      );

      await expectLater(
        repo.completeSession(
          sessionId: _sessionId,
          expectedRevision: 3,
          completedAtUtc: finishTime,
          notes: 'Saved notes',
          workoutTitle: 'Afternoon Workout',
          workoutAtUtc: finishTime.subtract(const Duration(hours: 1)),
          workoutUtcOffsetMinutes: 330,
        ),
        throwsA(isA<WorkoutSessionCommittedReadbackException>()),
      );
      expect(gateway.completeCallCount, 1);
    });

    test('terminal session immutability (P0001) maps to terminalSessionImmutable', () async {
      gateway.onLogSet = (_) async {
        throw const PostgrestException(
          message: 'terminal_session_sets_immutable',
          code: 'P0001',
        );
      };

      final set = PerformedSet(
        id: '55555555-5555-4555-a555-555555555555',
        exerciseRef: CatalogExerciseRef('ex_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
      );

      expect(
        () => repo.logPerformedSet(
          sessionId: _sessionId,
          expectedRevision: 5,
          set: set,
        ),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.terminalSessionImmutable,
        )),
      );
    });

    test('auth invalidation / user change throws unauthorized and denies operations', () async {
      currentUserId = null; // signed out!

      expect(
        () => repo.getSession(_sessionId),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.unauthenticated,
        )),
      );

      currentUserId = 'invalid-uuid';
      expect(
        () => repo.getSession(_sessionId),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.unauthenticated,
        )),
      );
    });

    test('getActiveSession returns null if session transitioned to terminal during bracketed read', () async {
      // 1. readActiveSessionHeader sees active session
      gateway.activeHeader = _mockSessionRow(revision: 1, status: 'active');
      // 2. Concurrent actor completes or discards before/during _readSession
      gateway.sessionHeader = _mockSessionRow(
        revision: 2,
        status: 'completed',
        completedAt: _startedAt.add(const Duration(minutes: 30)),
      );

      final active = await repo.getActiveSession();
      expect(active, isNull);
    });

    test('performed-set slot conflict (23505 uq_user_workout_performed_sets_slot) maps to setSlotConflict', () async {
      gateway.onLogSet = (_) async {
        throw const PostgrestException(
          message: 'duplicate key value violates unique constraint "uq_user_workout_performed_sets_slot"',
          code: '23505',
          details: 'Key (session_id, session_exercise_index, set_index)=(...) already exists.',
        );
      };

      final set = PerformedSet(
        id: '55555555-5555-4555-a555-555555555555',
        exerciseRef: CatalogExerciseRef('ex_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
      );

      expect(
        () => repo.logPerformedSet(
          sessionId: _sessionId,
          expectedRevision: 1,
          set: set,
        ),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.setSlotConflict,
        )),
      );
    });

    test('session_already_terminal with code P0002 maps to terminalSessionImmutable', () async {
      gateway.onLogSet = (_) async {
        throw const PostgrestException(
          message: 'session_already_terminal',
          code: 'P0002',
        );
      };

      final set = PerformedSet(
        id: '55555555-5555-4555-a555-555555555555',
        exerciseRef: CatalogExerciseRef('ex_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
      );

      expect(
        () => repo.logPerformedSet(
          sessionId: _sessionId,
          expectedRevision: 1,
          set: set,
        ),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.terminalSessionImmutable,
        )),
      );
    });

    test('unrecognized 23505 constraint maps to invalidPayload instead of duplicateActiveSession', () async {
      gateway.onStart = (_) async {
        throw const PostgrestException(
          message: 'duplicate key violates unknown_constraint',
          code: '23505',
        );
      };

      expect(
        () => repo.startSession(_mockSession()),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.invalidPayload,
        )),
      );
    });

    test('in-flight auth invalidation during read preserves unauthenticated / unauthorized', () async {
      final completer = Completer<Map<String, dynamic>?>();
      gateway.onReadActiveHeader = () => completer.future;

      final futureUnauth = repo.getActiveSession();
      currentUserId = null; // signed out mid-request
      completer.complete(_mockSessionRow());

      await expectLater(
        futureUnauth,
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.unauthenticated,
        )),
      );

      // Reset and test account switch
      currentUserId = _owner;
      final completerSwitch = Completer<Map<String, dynamic>?>();
      gateway.onReadActiveHeader = () => completerSwitch.future;

      final futureSwitch = repo.getActiveSession();
      currentUserId = _otherOwner; // user switched mid-request
      completerSwitch.complete(_mockSessionRow());

      await expectLater(
        futureSwitch,
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.unauthorized,
        )),
      );
    });

    test('in-flight auth change during mutation raises WorkoutSessionMutationOutcomeUnknown(sessionChanged)', () async {
      final completer = Completer<Map<String, dynamic>>();
      gateway.onPause = (_) => completer.future;

      final future = repo.pauseSession(
        sessionId: _sessionId,
        expectedRevision: 1,
        pausedAtUtc: _startedAt.add(const Duration(minutes: 5)),
      );

      // Account changed while mutation was in flight:
      currentUserId = _otherOwner;
      completer.complete(_mockSessionRow(revision: 2, status: 'paused'));

      await expectLater(
        future,
        throwsA(isA<WorkoutSessionMutationOutcomeUnknown>().having(
          (e) => e.reason,
          'reason',
          WorkoutSessionMutationUncertainty.sessionChanged,
        )),
      );
    });

    test('RPC success followed by readback timeout throws WorkoutSessionCommittedReadbackException', () async {
      // 1. RPC log performed set succeeds
      gateway.onLogSet = (_) async => _mockSetRow(setIndex: 0);
      // 2. Subsequent readback times out
      gateway.onReadSessionHeader = (_, __) => Future.delayed(
            const Duration(milliseconds: 50),
            () => throw TimeoutException('Read timed out'),
          );

      final fastRepo = SupabaseWorkoutSessionRepository(
        gateway: gateway,
        currentUserId: () => _owner,
        requestTimeout: const Duration(milliseconds: 20),
        readAttempts: 1,
      );

      final set = PerformedSet(
        id: '55555555-5555-4555-a555-555555555555',
        exerciseRef: CatalogExerciseRef('ex_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
      );

      WorkoutSessionCommittedReadbackException? thrownEx;
      try {
        await fastRepo.logPerformedSet(
          sessionId: _sessionId,
          expectedRevision: 1,
          set: set,
        );
      } on WorkoutSessionCommittedReadbackException catch (e) {
        thrownEx = e;
      }

      expect(thrownEx, isNotNull);
      expect(thrownEx!.sessionId, _sessionId);
      expect(thrownEx.operationName, 'logPerformedSet');
      expect(
        thrownEx.kind,
        WorkoutSessionPersistenceFailureKind.mutationCommittedReadbackFailed,
      );
      // Verify RPC was executed and succeeded on server
      expect(gateway.logSetCallCount, 1);
    });

    test('RPC success followed by revision read conflict throws WorkoutSessionCommittedReadbackException', () async {
      // 1. RPC remove performed set succeeds
      gateway.onRemoveSet = (_) async {};
      // 2. Subsequent readback experiences revision skew between start & end headers
      var toggle = 0;
      gateway.onReadSessionHeader = (_, __) async {
        toggle++;
        // Odd calls return revision 2, even calls return revision 3 (simulating continuous concurrent writes)
        return _mockSessionRow(revision: toggle.isOdd ? 2 : 3);
      };

      final setRepo = SupabaseWorkoutSessionRepository(
        gateway: gateway,
        currentUserId: () => _owner,
        readAttempts: 2,
      );

      WorkoutSessionCommittedReadbackException? thrownEx;
      try {
        await setRepo.removePerformedSet(
          sessionId: _sessionId,
          expectedRevision: 1,
          setId: '55555555-5555-4555-a555-555555555555',
        );
      } on WorkoutSessionCommittedReadbackException catch (e) {
        thrownEx = e;
      }

      expect(thrownEx, isNotNull);
      expect(thrownEx!.sessionId, _sessionId);
      expect(thrownEx.operationName, 'removePerformedSet');
      expect(
        thrownEx.kind,
        WorkoutSessionPersistenceFailureKind.mutationCommittedReadbackFailed,
      );
      expect(thrownEx.cause, isA<WorkoutSessionPersistenceException>().having(
        (e) => e.kind,
        'kind',
        WorkoutSessionPersistenceFailureKind.readConflict,
      ));
      // Verify the delete was dispatched once and not retried automatically
      expect(gateway.removeSetCallCount, 1);
    });

    test('caller can safely reconcile state via getSession after WorkoutSessionCommittedReadbackException', () async {
      // Step 1: Mutation completes, but readback fails
      final pauseTime = _startedAt.add(const Duration(minutes: 5));
      gateway.onPause = (_) async => _mockSessionRow(
            revision: 2,
            status: 'paused',
            pausedAt: pauseTime,
          );
      var failRead = true;
      gateway.onReadSessionHeader = (_, __) async {
        if (failRead) {
          throw const PostgrestException(message: 'read error', code: '500');
        }
        return _mockSessionRow(
          revision: 2,
          status: 'paused',
          pausedAt: pauseTime,
        );
      };

      WorkoutSessionCommittedReadbackException? caughtException;
      try {
        await repo.pauseSession(
          sessionId: _sessionId,
          expectedRevision: 1,
          pausedAtUtc: pauseTime,
        );
      } on WorkoutSessionCommittedReadbackException catch (e) {
        caughtException = e;
      }

      expect(caughtException, isNotNull);
      expect(caughtException!.operationName, 'pauseSession');
      expect(gateway.pauseCallCount, 1);

      // Step 2: Caller reconciles state via getSession without replaying mutation with stale revision
      failRead = false;
      final reconciled = await repo.getSession(caughtException.sessionId);
      expect(reconciled, isNotNull);
      expect(reconciled!.revision, 2);
      expect(reconciled.session.status, WorkoutSessionStatus.paused);
      // RPC was NOT retried
      expect(gateway.pauseCallCount, 1);
    });

    test('auth invalidation during post-mutation readback preserves unauthenticated / unauthorized', () async {
      final pauseTime = _startedAt.add(const Duration(minutes: 5));
      final mutationCompleter = Completer<Map<String, dynamic>>();
      final readCompleter = Completer<Map<String, dynamic>?>();

      gateway.onPause = (_) => mutationCompleter.future;
      gateway.onReadSessionHeader = (_, __) => readCompleter.future;

      final futureUnauth = repo.pauseSession(
        sessionId: _sessionId,
        expectedRevision: 1,
        pausedAtUtc: pauseTime,
      );

      // 1. Let mutation finish while user is still authenticated
      mutationCompleter.complete(_mockSessionRow(
        revision: 2,
        status: 'paused',
        pausedAt: pauseTime,
      ));
      await Future<void>.delayed(Duration.zero);

      // 2. User logs out while readback is in flight
      currentUserId = null;
      readCompleter.complete(_mockSessionRow(
        revision: 2,
        status: 'paused',
        pausedAt: pauseTime,
      ));

      await expectLater(
        futureUnauth,
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.unauthenticated,
        )),
      );

      // Reset and test account switch during readback
      currentUserId = _owner;
      final mutationSwitchCompleter = Completer<Map<String, dynamic>>();
      final readSwitchCompleter = Completer<Map<String, dynamic>?>();
      gateway.onPause = (_) => mutationSwitchCompleter.future;
      gateway.onReadSessionHeader = (_, __) => readSwitchCompleter.future;

      final futureSwitch = repo.pauseSession(
        sessionId: _sessionId,
        expectedRevision: 1,
        pausedAtUtc: pauseTime,
      );

      // 1. Let mutation finish while user is still authenticated as _owner
      mutationSwitchCompleter.complete(_mockSessionRow(
        revision: 2,
        status: 'paused',
        pausedAt: pauseTime,
      ));
      await Future<void>.delayed(Duration.zero);

      // 2. User switches account while readback is in flight
      currentUserId = _otherOwner;
      readSwitchCompleter.complete(_mockSessionRow(
        revision: 2,
        status: 'paused',
        pausedAt: pauseTime,
      ));

      await expectLater(
        futureSwitch,
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.unauthorized,
        )),
      );
    });

    test('P0001 invalid_transition_from_status maps to invalidStateTransition (pause/resume)', () async {
      // 1. Pausing an already paused or non-active session
      gateway.onPause = (_) async {
        throw const PostgrestException(
          message: 'invalid_transition_from_status',
          code: 'P0001',
        );
      };

      expect(
        () => repo.pauseSession(
          sessionId: _sessionId,
          expectedRevision: 2,
          pausedAtUtc: _startedAt.add(const Duration(minutes: 10)),
        ),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.invalidStateTransition,
        )),
      );

      // 2. Resuming an active or non-paused session
      gateway.onResume = (_) async {
        throw const PostgrestException(
          message: 'invalid_transition_from_status',
          code: 'P0001',
        );
      };

      expect(
        () => repo.resumeSession(
          sessionId: _sessionId,
          expectedRevision: 3,
          resumedAtUtc: _startedAt.add(const Duration(minutes: 15)),
        ),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.invalidStateTransition,
        )),
      );
    });

    test('genuinely terminal session mutations still map to terminalSessionImmutable', () async {
      // 1. Logging set on already finished workout
      gateway.onLogSet = (_) async {
        throw const PostgrestException(
          message: 'session_already_terminal',
          code: 'P0002',
        );
      };

      final set = PerformedSet(
        id: '55555555-5555-4555-a555-555555555555',
        exerciseRef: CatalogExerciseRef('ex_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
      );

      expect(
        () => repo.logPerformedSet(
          sessionId: _sessionId,
          expectedRevision: 5,
          set: set,
        ),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.terminalSessionImmutable,
        )),
      );

      // 2. Trigger immutability error
      gateway.onLogSet = (_) async {
        throw const PostgrestException(
          message: 'terminal_session_sets_immutable',
          code: 'P0001',
        );
      };

      expect(
        () => repo.logPerformedSet(
          sessionId: _sessionId,
          expectedRevision: 5,
          set: set,
        ),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.terminalSessionImmutable,
        )),
      );
    });
  });
}
