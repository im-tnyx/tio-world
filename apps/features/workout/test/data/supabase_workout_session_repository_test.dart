import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_feature_workout/src/presentation/controllers/workout_history_edit_controller.dart';
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
            SetPrescription(
                setType: RoutineSetType.normal, reps: 8, loadKg: 80.0),
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
      'updated_at': (lastTransitionAt ?? pausedAt ?? completedAt ?? _startedAt)
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

final class _FakeGateway
    implements WorkoutSessionGateway, WorkoutHistoryEditGateway {
  List<Map<String, dynamic>> historyHeaders = [];
  List<Map<String, dynamic>> historySets = [];
  String? lastHistoryOwner;
  DateTime? lastHistoryBefore;
  String? lastHistoryBeforeId;
  List<String>? lastHistorySessionIds;
  int historyHeaderReadCount = 0;
  int historySetReadCount = 0;
  void Function()? beforeHistorySetRead;
  Future<List<Map<String, dynamic>>> Function()? onReadHistoryHeaders;

  @override
  Future<List<Map<String, dynamic>>> readCompletedHistoryHeaders(
    String userId, {
    required int limit,
    DateTime? beforeCompletedAtUtc,
    String? beforeId,
  }) async {
    historyHeaderReadCount++;
    lastHistoryOwner = userId;
    lastHistoryBefore = beforeCompletedAtUtc;
    lastHistoryBeforeId = beforeId;
    return onReadHistoryHeaders == null
        ? historyHeaders.take(limit).toList()
        : await onReadHistoryHeaders!();
  }

  @override
  Future<List<Map<String, dynamic>>> readHistoryPerformedSets(
    String userId,
    List<String> sessionIds, {
    required int offset,
    required int limit,
  }) async {
    historySetReadCount++;
    beforeHistorySetRead?.call();
    lastHistorySessionIds = sessionIds;
    return historySets.skip(offset).take(limit).toList();
  }

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
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onSaveDraft;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onEdit;
  Map<String, dynamic>? lastEditParams;
  Future<Map<String, dynamic>> Function(Map<String, dynamic>)? onDiscard;

  @override
  Future<Map<String, dynamic>?> readActiveSessionHeader(String userId) async =>
      onReadActiveHeader != null ? await onReadActiveHeader!() : activeHeader;

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

  String? lastDetailOwner;
  String? lastDetailSessionId;

  @override
  Future<Map<String, dynamic>?> readCompletedHistoryHeader(
    String userId,
    String sessionId,
  ) async {
    lastDetailOwner = userId;
    lastDetailSessionId = sessionId;
    final row = await readSessionHeader(userId, sessionId);
    return row?['status'] == 'completed' ? row : null;
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
  Future<Map<String, dynamic>> rpcSaveWorkoutDraft(
    Map<String, dynamic> params,
  ) async =>
      onSaveDraft != null
          ? await onSaveDraft!(params)
          : _mockSessionRow(revision: 2, status: 'completed');

  @override
  Future<Map<String, dynamic>> rpcUpdateCompletedWorkout(
      Map<String, dynamic> params) async {
    lastEditParams = params;
    return onEdit != null
        ? await onEdit!(params)
        : _mockSessionRow(revision: 3, status: 'completed');
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

    test('Detail reads one completed owner session and actual ordered sets',
        () async {
      final snapshot = WorkoutSessionSnapshotDto.toJson(_mockSnapshot());
      final exercises =
          List<Map<String, dynamic>>.from(snapshot['exercises'] as List);
      exercises.add({
        'exercise_ref': 'ex_spinning',
        'display_name': 'Spinning',
        'exercise_type': 'duration',
        'occurrence_index': 1,
        'prescribed_sets': [
          {'set_type': 'normal', 'duration_seconds': 600}
        ],
      });
      snapshot['exercises'] = exercises;
      gateway.sessionHeader = {
        ..._mockSessionRow(
          status: 'completed',
          completedAt: _startedAt.add(const Duration(minutes: 44)),
          workoutTitle: 'Shoulders & Triceps',
          notes: '  Good day  ',
        ),
        'routine_snapshot': snapshot,
        'gym_name': '  Main Gym  ',
        'workout_duration_seconds': 2640,
      };
      gateway.performedSets = [
        _mockSetRow(setIndex: 1, setId: '55555555-5555-4555-a555-555555555556'),
        _mockSetRow(setIndex: 0),
        {..._mockSetRow(setIndex: 2), 'is_skipped': true},
        {
          ..._mockSetRow(
            exerciseIndex: 1,
            setId: '55555555-5555-4555-a555-555555555557',
            reps: null,
            loadKg: null,
          ),
          'exercise_ref': 'ex_spinning',
          'duration_seconds': 429,
        },
      ];

      final detail = await repo.getCompletedHistoryDetail(_sessionId);

      expect(gateway.lastDetailOwner, _owner);
      expect(gateway.lastDetailSessionId, _sessionId.value);
      expect(gateway.readHeaderCallCount, 2);
      expect(detail!.summary.title, 'Shoulders & Triceps');
      expect(detail.summary.duration, const Duration(minutes: 44));
      expect(detail.summary.volumeKg, 1600);
      expect(detail.summary.description, 'Good day');
      expect(detail.summary.gymName, 'Main Gym');
      expect(detail.performedSetCount, 3);
      expect(detail.exercises.map((e) => e.name), ['Bench Press', 'Spinning']);
      expect(detail.exercises.first.sets.map((e) => e.setIndex), [0, 1]);
      expect(detail.exercises.last.sets.single.durationSeconds, 429);
    });

    test(
        'completed Update sends owner revision and verifies canonical readback',
        () async {
      final completed = _startedAt.add(const Duration(minutes: 44));
      gateway.sessionHeader = {
        ..._mockSessionRow(
          revision: 2,
          status: 'completed',
          completedAt: completed,
          workoutTitle: 'Original',
          workoutAtUtc: _startedAt,
        ),
        'workout_duration_seconds': 2640,
      };
      gateway.performedSets = [_mockSetRow()];
      final source = (await repo.getCompletedHistoryDetail(_sessionId))!;
      final controller = WorkoutHistoryEditController(source);
      final request = WorkoutHistoryEditRequest(
        source: source,
        title: 'Updated',
        description: 'Edited',
        workoutAtUtc: _startedAt,
        utcOffsetMinutes: 0,
        durationSeconds: 2400,
        gymName: 'Main Gym',
        activityType: 'Weight Training',
        overallRpe: 7,
        exercises: controller.exercises,
      );
      gateway.onEdit = (params) async {
        final payload = params['p_payload'] as Map<String, dynamic>;
        gateway.sessionHeader = {
          ...gateway.sessionHeader!,
          'revision': 3,
          'workout_title': payload['workout_title'],
          'notes': payload['description'],
          'workout_at_utc': payload['workout_at_utc'],
          'workout_utc_offset_minutes': payload['workout_utc_offset_minutes'],
          'workout_duration_seconds': payload['selected_duration_seconds'],
          'gym_name': payload['gym_name'],
          'workout_activity_type': payload['activity_type'],
          'workout_rpe': payload['overall_rpe'],
          'routine_snapshot': payload['routine_snapshot'],
        };
        final set = (payload['performed_sets'] as List).single as Map;
        gateway.performedSets = [
          {
            ..._mockSetRow(),
            'id': set['id'],
            'reps': set['reps'],
            'load_kg': set['load_kg'],
            'completed_at_utc': set['completed_at_utc'],
          }
        ];
        return gateway.sessionHeader!;
      };
      final saved = await repo.updateCompletedWorkout(request);
      expect(gateway.lastEditParams?['p_session_id'], _sessionId.value);
      expect(gateway.lastEditParams?['p_expected_revision'], 2);
      expect(saved.revision, 3);
      expect(saved.summary.title, 'Updated');
      expect(saved.summary.duration, const Duration(minutes: 40));
      expect(saved.summary.sessionId, _sessionId);
      controller.dispose();
    });

    test('completed Update rejects an account switch before readback',
        () async {
      final completed = _startedAt.add(const Duration(minutes: 44));
      gateway.sessionHeader = {
        ..._mockSessionRow(
          revision: 2,
          status: 'completed',
          completedAt: completed,
          workoutTitle: 'Original',
          workoutAtUtc: _startedAt,
        ),
        'workout_duration_seconds': 2640,
      };
      gateway.performedSets = [_mockSetRow()];
      final source = (await repo.getCompletedHistoryDetail(_sessionId))!;
      final controller = WorkoutHistoryEditController(source);
      final pending = Completer<Map<String, dynamic>>();
      gateway.onEdit = (_) => pending.future;
      final result = repo.updateCompletedWorkout(WorkoutHistoryEditRequest(
        source: source,
        title: 'Updated',
        description: null,
        workoutAtUtc: _startedAt,
        utcOffsetMinutes: 0,
        durationSeconds: 2400,
        gymName: null,
        activityType: null,
        overallRpe: null,
        exercises: controller.exercises,
      ));
      await Future<void>.delayed(Duration.zero);
      currentUserId = _otherOwner;
      pending.complete(_mockSessionRow(revision: 3, status: 'completed'));
      await expectLater(
        result,
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (error) => error.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.unauthorized,
        )),
      );
      controller.dispose();
    });

    test('Detail excludes active and foreign rows and stale account results',
        () async {
      gateway.sessionHeader = _mockSessionRow(status: 'active');
      expect(await repo.getCompletedHistoryDetail(_sessionId), isNull);
      gateway.sessionHeader = {
        ..._mockSessionRow(
          status: 'completed',
          completedAt: _startedAt.add(const Duration(minutes: 1)),
        ),
        'user_id': _otherOwner,
      };
      await expectLater(repo.getCompletedHistoryDetail(_sessionId),
          throwsA(isA<WorkoutSessionPersistenceException>()));

      final pending = Completer<Map<String, dynamic>?>();
      gateway.onReadSessionHeader = (_, __) => pending.future;
      final read = repo.getCompletedHistoryDetail(_sessionId);
      currentUserId = _otherOwner;
      pending.complete({
        ..._mockSessionRow(
          status: 'completed',
          completedAt: _startedAt.add(const Duration(minutes: 1)),
        ),
      });
      await expectLater(
          read, throwsA(isA<WorkoutSessionPersistenceException>()));
    });

    test('Detail retries a changed revision and rejects quota overflow',
        () async {
      final completed = {
        ..._mockSessionRow(
          status: 'completed',
          completedAt: _startedAt.add(const Duration(minutes: 44)),
        ),
        'gym_name': null,
        'workout_duration_seconds': null,
      };
      final headers = <Map<String, dynamic>>[
        completed,
        {...completed, 'revision': 2},
        {...completed, 'revision': 2},
        {...completed, 'revision': 2},
      ];
      gateway.onReadHeaderSequence = () => headers;
      gateway.performedSets = [_mockSetRow()];
      expect(
          (await repo.getCompletedHistoryDetail(_sessionId))!.performedSetCount,
          1);
      expect(gateway.readHeaderCallCount, 4);

      gateway.onReadHeaderSequence = null;
      gateway.sessionHeader = completed;
      gateway.performedSets = List.filled(501, _mockSetRow());
      await expectLater(repo.getCompletedHistoryDetail(_sessionId),
          throwsA(isA<WorkoutSessionPersistenceException>()));
    });

    test('History maps saved title, time, gym and performed-only preview',
        () async {
      gateway.historyHeaders = [
        {
          ..._mockSessionRow(
            status: 'completed',
            completedAt: _startedAt.add(const Duration(minutes: 53)),
            workoutTitle: 'Shoulders',
            workoutAtUtc: _startedAt,
            workoutUtcOffsetMinutes: 330,
            notes: '  Strong session  ',
          ),
          'gym_name': '  Main Gym  ',
          'workout_duration_seconds': 3180,
        },
      ];
      gateway.historySets = [
        _mockSetRow(),
        {..._mockSetRow(setIndex: 1), 'is_skipped': true},
        _mockSetRow(setIndex: 2),
      ];

      final page = await repo.listCompletedHistory();

      expect(gateway.lastHistoryOwner, _owner);
      expect(gateway.lastHistorySessionIds, [_sessionId.value]);
      expect(page.hasMore, isFalse);
      final entry = page.entries.single;
      expect(entry.sessionId, _sessionId);
      expect(entry.title, 'Shoulders');
      expect(entry.displayAt.hour, 15);
      expect(entry.displayAt.minute, 30);
      expect(entry.duration, const Duration(minutes: 53));
      expect(entry.volumeKg, 1600);
      expect(entry.description, 'Strong session');
      expect(entry.gymName, 'Main Gym');
      expect(entry.exercises.single.name, 'Bench Press');
      expect(entry.exercises.single.setCount, 2);
    });

    test('History retries when Update changes rows between header and set reads',
        () async {
      final beforeHeader = {
        ..._mockSessionRow(
          status: 'completed',
          completedAt: _startedAt.add(const Duration(minutes: 10)),
          revision: 1,
        ),
        'gym_name': null,
        'workout_duration_seconds': null,
      };
      final updatedSnapshot = WorkoutSessionSnapshot(
        routineId: _routineId,
        routineName: 'Upper Body Blast',
        programId: _programId,
        capturedAtUtc: _startedAt,
        exercises: [
          SessionExerciseSnapshot(
            exerciseRef: CatalogExerciseRef('ex_squat'),
            displayName: 'Squat',
            occurrenceIndex: 0,
            prescribedSets: [
              SetPrescription(
                setType: RoutineSetType.normal,
                reps: 8,
                loadKg: 80,
              ),
            ],
          ),
        ],
      );
      final updatedHeader = {
        ...beforeHeader,
        'revision': 2,
        'workout_title': 'Updated title',
        'routine_snapshot': WorkoutSessionSnapshotDto.toJson(updatedSnapshot),
      };
      gateway.historyHeaders = [beforeHeader];
      gateway.historySets = [_mockSetRow()];
      var didInterleaveUpdate = false;
      gateway.beforeHistorySetRead = () {
        if (didInterleaveUpdate) return;
        didInterleaveUpdate = true;
        gateway.historyHeaders = [updatedHeader];
        gateway.historySets = [
          {..._mockSetRow(), 'exercise_ref': 'ex_squat'},
        ];
      };

      final page = await repo.listCompletedHistory();

      expect(gateway.historyHeaderReadCount, 4);
      expect(gateway.historySetReadCount, 2);
      expect(page.entries.single.title, 'Updated title');
      expect(page.entries.single.exercises.single.name, 'Squat');
    });

    test('History is bounded and forwards newest-first keyset cursor',
        () async {
      gateway.historyHeaders = [
        for (var index = 0; index < 6; index++)
          {
            ..._mockSessionRow(
              status: 'completed',
              completedAt: _startedAt.add(Duration(minutes: 60 - index)),
            ),
            'id':
                '22222222-2222-4222-a222-${(222222222220 + index).toString()}',
            'gym_name': null,
            'workout_duration_seconds': null,
          },
      ];
      final page = await repo.listCompletedHistory();
      expect(page.entries, hasLength(5));
      expect(page.hasMore, isTrue);
      expect(gateway.lastHistorySessionIds, hasLength(5));
      expect(page.nextCursor!.sessionId.value, gateway.historyHeaders[4]['id']);
      await repo.listCompletedHistory(after: page.nextCursor);
      expect(gateway.lastHistoryBefore, page.nextCursor!.completedAtUtc);
      expect(gateway.lastHistoryBeforeId, page.nextCursor!.sessionId.value);
    });

    test(
        'History omits blank optional fields and uses performed exercise order',
        () async {
      final snapshot = WorkoutSessionSnapshotDto.toJson(_mockSnapshot());
      final exercises =
          List<Map<String, dynamic>>.from(snapshot['exercises'] as List);
      exercises.add({
        'exercise_ref': 'ex_row',
        'display_name': 'Row',
        'occurrence_index': 1,
        'prescribed_sets': [
          {'set_type': 'normal', 'reps': 8},
        ],
      });
      snapshot['exercises'] = exercises;
      gateway.historyHeaders = [
        {
          ..._mockSessionRow(
            status: 'completed',
            completedAt: _startedAt.add(const Duration(minutes: 10)),
            notes: '   ',
          ),
          'routine_snapshot': snapshot,
          'gym_name': '  ',
          'workout_duration_seconds': null,
        },
      ];
      gateway.historySets = [
        {
          ..._mockSetRow(exerciseIndex: 1),
          'exercise_ref': 'ex_row',
        },
        _mockSetRow(),
      ];
      final entry = (await repo.listCompletedHistory()).entries.single;
      expect(entry.description, isNull);
      expect(entry.gymName, isNull);
      expect(entry.title, 'Upper Body Blast');
      expect(entry.duration, const Duration(minutes: 10));
      expect(entry.exercises.map((exercise) => exercise.name),
          ['Bench Press', 'Row']);
      expect(entry.exercises.map((exercise) => exercise.setCount), [1, 1]);
      expect(entry.volumeKg, 1600);
    });

    test('History volume uses only completed measured performed sets',
        () async {
      gateway.historyHeaders = [
        {
          ..._mockSessionRow(
            status: 'completed',
            completedAt: _startedAt.add(const Duration(minutes: 10)),
          ),
          'gym_name': null,
          'workout_duration_seconds': null,
        },
      ];
      gateway.historySets = [
        _mockSetRow(reps: 8, loadKg: 50),
        {
          ..._mockSetRow(setIndex: 1, reps: null, loadKg: null),
          'is_skipped': true
        },
        {
          ..._mockSetRow(setIndex: 2, reps: 10, loadKg: 100),
          'completed_at_utc': null
        },
        _mockSetRow(setIndex: 3, reps: 10, loadKg: null),
      ];
      final entry = (await repo.listCompletedHistory()).entries.single;
      expect(entry.volumeKg, 400);
      expect(entry.exercises.single.setCount, 2);

      gateway.historySets = [
        _mockSetRow(reps: 10, loadKg: null),
      ];
      expect(
          (await repo.listCompletedHistory()).entries.single.volumeKg, isNull);
    });

    test('History rejects non-completed, foreign and stale account results',
        () async {
      final completed = {
        ..._mockSessionRow(
          status: 'completed',
          completedAt: _startedAt.add(const Duration(minutes: 1)),
        ),
        'gym_name': null,
        'workout_duration_seconds': null,
      };
      gateway.historyHeaders = [
        {...completed, 'status': 'active'}
      ];
      await expectLater(
        repo.listCompletedHistory(),
        throwsA(isA<WorkoutSessionPersistenceException>()),
      );
      gateway.historyHeaders = [
        {...completed, 'user_id': _otherOwner}
      ];
      await expectLater(
        repo.listCompletedHistory(),
        throwsA(isA<WorkoutSessionPersistenceException>()),
      );
      final pending = Completer<List<Map<String, dynamic>>>();
      gateway.onReadHistoryHeaders = () => pending.future;
      final read = repo.listCompletedHistory();
      currentUserId = _otherOwner;
      pending.complete([completed]);
      await expectLater(
        read,
        throwsA(isA<WorkoutSessionPersistenceException>()),
      );
    });

    test('Save-only RPC confirms canonical title, metadata and performed set',
        () async {
      final draft = ActiveWorkoutDraft(
        id: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
        ownerId: _owner,
        saveRequestId: 'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb',
        time: WorkoutTime.start(startedAtUtc: _startedAt)
            .pause(_startedAt.add(const Duration(minutes: 10))),
        submittedAtUtc: _startedAt.add(const Duration(minutes: 12)),
        submittedTitle: 'Morning Workout',
        workoutTitle: '',
        description: 'Good session',
        workoutAtUtc: _startedAt,
        workoutUtcOffsetMinutes: 330,
        selectedDurationSeconds: 600,
        activityType: 'Weight Training',
        gymName: 'Gym One',
        overallRpe: 8,
        exercises: [
          ActiveWorkoutDraftExercise(
            id: 'cccccccc-cccc-4ccc-cccc-cccccccccccc',
            exerciseRef: CatalogExerciseRef('ex_bench_press'),
            displayName: 'Bench Press',
            sets: [
              ActiveWorkoutDraftSet(
                id: 'dddddddd-dddd-4ddd-dddd-dddddddddddd',
                prescription: SetPrescription(
                  setType: RoutineSetType.warmUp,
                ),
                reps: 10,
                loadKg: 80,
                rpe: 7.5,
                loggedAtUtc: _startedAt.add(const Duration(minutes: 5)),
              ),
            ],
          ),
        ],
      );
      var saves = 0;
      gateway.onSaveDraft = (params) async {
        saves++;
        final payload = params['p_payload'] as Map<String, dynamic>;
        expect(params['p_save_request_id'], draft.saveRequestId);
        expect(payload['workout_title'], 'Morning Workout');
        expect(payload['accumulated_paused_microseconds'], 120000000);
        final set = (payload['performed_sets'] as List).single as Map;
        gateway.performedSets = [
          {
            ..._mockSetRow(),
            'completed_at_utc': set['completed_at_utc'],
          }
        ];
        gateway.sessionHeader = {
          ..._mockSessionRow(
            status: 'completed',
            revision: 2,
            completedAt: draft.submittedAtUtc,
            notes: 'Good session',
            workoutTitle: 'Morning Workout',
            workoutAtUtc: _startedAt,
            workoutUtcOffsetMinutes: 330,
          ),
          'program_id': null,
          'routine_id': null,
          'save_request_id': draft.saveRequestId,
          'local_date': '2026-11-07',
          'workout_activity_type': 'Weight Training',
          'gym_name': 'Gym One',
          'workout_rpe': 8,
          'workout_duration_seconds': 600,
          'routine_snapshot': payload['routine_snapshot'],
        };
        return gateway.sessionHeader!;
      };
      final first = await repo.saveDraft(draft);
      expect(first.title, 'Morning Workout');
      expect(first.description, 'Good session');
      expect(first.performedSets.single.reps, 10);
      expect(first.performedSets.single.loadKg, 80);
      final exercise = (first.snapshot['exercises'] as List).single as Map;
      final prescribed = (exercise['prescribed_sets'] as List).single as Map;
      expect(prescribed['set_type'], 'warm_up');
      expect(prescribed['performed_rpe'], 7.5);
      final readback = await repo.getSavedDraft(first.sessionId);
      expect(readback!.saveRequestId, draft.saveRequestId);
      expect((await repo.saveDraft(draft)).sessionId, first.sessionId);
      expect(saves, 2);

      gateway.onSaveDraft = (params) async {
        saves++;
        gateway.performedSets = [];
        return gateway.sessionHeader!;
      };
      await expectLater(
          repo.saveDraft(draft),
          throwsA(
            isA<WorkoutSessionCommittedReadbackException>(),
          ));
      expect(saves, 3);
    });

    test('blank Save description matches canonical NULL notes readback',
        () async {
      final draft = ActiveWorkoutDraft(
        id: 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
        ownerId: _owner,
        saveRequestId: 'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb',
        time: WorkoutTime.start(startedAtUtc: _startedAt)
            .pause(_startedAt.add(const Duration(minutes: 10))),
        submittedAtUtc: _startedAt.add(const Duration(minutes: 12)),
        submittedTitle: 'Morning Workout',
        workoutTitle: '',
        description: '   ',
        workoutAtUtc: _startedAt,
        workoutUtcOffsetMinutes: 330,
        selectedDurationSeconds: 600,
        exercises: [
          ActiveWorkoutDraftExercise(
            id: 'cccccccc-cccc-4ccc-cccc-cccccccccccc',
            exerciseRef: CatalogExerciseRef('ex_bench_press'),
            displayName: 'Bench Press',
            sets: [
              ActiveWorkoutDraftSet(
                id: 'dddddddd-dddd-4ddd-dddd-dddddddddddd',
                prescription: SetPrescription(),
                reps: 8,
                loadKg: 50,
                loggedAtUtc: _startedAt.add(const Duration(minutes: 5)),
              ),
            ],
          ),
        ],
      );
      gateway.onSaveDraft = (params) async {
        final payload = params['p_payload'] as Map<String, dynamic>;
        expect(payload.containsKey('description'), isTrue);
        expect(payload['description'], isNull);
        gateway.performedSets = [
          {
            ..._mockSetRow(reps: 8, loadKg: 50),
            'completed_at_utc':
                (payload['performed_sets'] as List).single['completed_at_utc'],
          }
        ];
        gateway.sessionHeader = {
          ..._mockSessionRow(
            status: 'completed',
            revision: 2,
            completedAt: draft.submittedAtUtc,
            notes: null,
            workoutTitle: 'Morning Workout',
            workoutAtUtc: _startedAt,
            workoutUtcOffsetMinutes: 330,
          ),
          'program_id': null,
          'routine_id': null,
          'save_request_id': draft.saveRequestId,
          'local_date': '2026-11-07',
          'workout_duration_seconds': 600,
          'routine_snapshot': payload['routine_snapshot'],
        };
        return gateway.sessionHeader!;
      };
      final saved = await repo.saveDraft(draft);
      expect(saved.description, isNull);
    });

    test('startSession dispatches RPC and returns authoritative record',
        () async {
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

    test('getActiveSession returns null when no active/paused session exists',
        () async {
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

    test('bracketed read retries when revision changes mid-read and succeeds',
        () async {
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

    test('bracketed read throws readConflict under sustained contention',
        () async {
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

    test('pauseSession and resumeSession update status and perform readback',
        () async {
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

    test(
        'logPerformedSet dispatches RPC and reads authoritative session revision',
        () async {
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

    test('removePerformedSet dispatches RPC and reads authoritative session',
        () async {
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

    test('removePerformedSet does not treat P0002 as successful deletion',
        () async {
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

    test(
        'stale revision conflict (P0003) maps to typed staleRevisionConflict and does not overwrite',
        () async {
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

    test('timeout during mutation throws WorkoutSessionMutationOutcomeUnknown',
        () async {
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

    test(
        'terminal session immutability (P0001) maps to terminalSessionImmutable',
        () async {
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

    test(
        'auth invalidation / user change throws unauthorized and denies operations',
        () async {
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

    test(
        'getActiveSession returns null if session transitioned to terminal during bracketed read',
        () async {
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

    test(
        'performed-set slot conflict (23505 uq_user_workout_performed_sets_slot) maps to setSlotConflict',
        () async {
      gateway.onLogSet = (_) async {
        throw const PostgrestException(
          message:
              'duplicate key value violates unique constraint "uq_user_workout_performed_sets_slot"',
          code: '23505',
          details:
              'Key (session_id, session_exercise_index, set_index)=(...) already exists.',
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

    test(
        'session_already_terminal with code P0002 maps to terminalSessionImmutable',
        () async {
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

    test(
        'unrecognized 23505 constraint maps to invalidPayload instead of duplicateActiveSession',
        () async {
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

    test(
        'in-flight auth invalidation during read preserves unauthenticated / unauthorized',
        () async {
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

    test(
        'in-flight auth change during mutation raises WorkoutSessionMutationOutcomeUnknown(sessionChanged)',
        () async {
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

    test(
        'RPC success followed by readback timeout throws WorkoutSessionCommittedReadbackException',
        () async {
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

    test(
        'RPC success followed by revision read conflict throws WorkoutSessionCommittedReadbackException',
        () async {
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
      expect(
          thrownEx.cause,
          isA<WorkoutSessionPersistenceException>().having(
            (e) => e.kind,
            'kind',
            WorkoutSessionPersistenceFailureKind.readConflict,
          ));
      // Verify the delete was dispatched once and not retried automatically
      expect(gateway.removeSetCallCount, 1);
    });

    test(
        'caller can safely reconcile state via getSession after WorkoutSessionCommittedReadbackException',
        () async {
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

    test(
        'auth invalidation during post-mutation readback preserves unauthenticated / unauthorized',
        () async {
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

    test(
        'P0001 invalid_transition_from_status maps to invalidStateTransition (pause/resume)',
        () async {
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

    test(
        'genuinely terminal session mutations still map to terminalSessionImmutable',
        () async {
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
