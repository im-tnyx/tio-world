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
  List<Map<String, dynamic>> Function()? onReadHeaderSequence;

  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onStart;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onPause;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onResume;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onLogSet;
  Future<void> Function(Map<String, dynamic>)? onRemoveSet;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onComplete;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onDiscard;

  @override
  Future<Map<String, dynamic>?> readActiveSessionHeader(String userId) async =>
      activeHeader;

  @override
  Future<Map<String, dynamic>?> readSessionHeader(
    String userId,
    String sessionId,
  ) async {
    readHeaderCallCount++;
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
  ) async =>
      onPause != null
          ? await onPause!(params)
          : _mockSessionRow(revision: 2, status: 'paused');

  @override
  Future<Map<String, dynamic>> rpcResumeWorkoutSession(
    Map<String, dynamic> params,
  ) async =>
      onResume != null
          ? await onResume!(params)
          : _mockSessionRow(revision: 3, status: 'active');

  @override
  Future<Map<String, dynamic>> rpcLogWorkoutPerformedSet(
    Map<String, dynamic> params,
  ) async =>
      onLogSet != null ? await onLogSet!(params) : _mockSetRow();

  @override
  Future<void> rpcRemoveWorkoutPerformedSet(Map<String, dynamic> params) async {
    if (onRemoveSet != null) await onRemoveSet!(params);
  }

  @override
  Future<Map<String, dynamic>> rpcCompleteWorkoutSession(
    Map<String, dynamic> params,
  ) async =>
      onComplete != null
          ? await onComplete!(params)
          : _mockSessionRow(revision: 4, status: 'completed');

  @override
  Future<Map<String, dynamic>> rpcDiscardWorkoutSession(
    Map<String, dynamic> params,
  ) async =>
      onDiscard != null
          ? await onDiscard!(params)
          : _mockSessionRow(
              revision: 4,
              status: 'discarded',
              discardReason: 'Fatigue',
            );
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
      );

      final completedRecord = await repo.completeSession(
        sessionId: _sessionId,
        expectedRevision: 3,
        completedAtUtc: finishTime,
        notes: 'Great workout',
      );

      expect(completedRecord.session.status, WorkoutSessionStatus.completed);
      expect(completedRecord.session.notes, 'Great workout');
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
  });
}
