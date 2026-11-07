import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('WorkoutSessionSnapshotDto', () {
    final routineId = RoutineId('aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa');
    final programId = ProgramId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
    final capturedAt = DateTime.utc(2026, 11, 7, 10, 0, 0);

    test('serializes and deserializes a rich snapshot matching schema version 1', () {
      final snapshot = WorkoutSessionSnapshot(
        routineId: routineId,
        routineName: 'Hypertrophy Upper A',
        programId: programId,
        capturedAtUtc: capturedAt,
        exercises: [
          SessionExerciseSnapshot(
            exerciseRef: CatalogExerciseRef('ex_bench_press'),
            displayName: 'Barbell Bench Press',
            exerciseType: ExerciseType.weightReps,
            occurrenceIndex: 0,
            prescribedSets: [
              SetPrescription(
                setType: RoutineSetType.warmUp,
                reps: 15,
                loadKg: 40.0,
                restSeconds: 60,
              ),
              SetPrescription(
                setType: RoutineSetType.normal,
                reps: 8,
                repsMax: 10,
                loadKg: 80.0,
                restSeconds: 120,
              ),
            ],
          ),
          SessionExerciseSnapshot(
            exerciseRef: CatalogExerciseRef('ex_treadmill_run'),
            displayName: 'Treadmill Incline Run',
            exerciseType: ExerciseType.distanceDuration,
            occurrenceIndex: 1,
            prescribedSets: [
              SetPrescription(
                setType: RoutineSetType.normal,
                distanceMeters: 5000.0,
                durationSeconds: 1800,
                restSeconds: 0,
              ),
            ],
          ),
        ],
      );

      final json = WorkoutSessionSnapshotDto.toJson(snapshot);

      // Verify root keys whitelist
      expect(
        json.keys,
        containsAll([
          'schema_version',
          'routine_id',
          'routine_name',
          'program_id',
          'captured_at_utc',
          'exercises',
        ]),
      );
      expect(json['schema_version'], 1);
      expect(json['routine_id'], routineId.value);
      expect(json['routine_name'], 'Hypertrophy Upper A');
      expect(json['program_id'], programId.value);
      expect(json['captured_at_utc'], '2026-11-07T10:00:00.000Z');

      // Roundtrip
      final restored = WorkoutSessionSnapshotDto.fromJson(json);
      expect(restored, equals(snapshot));
      expect(restored.exercises.length, 2);
      expect(restored.exercises[0].exerciseRef.value, 'ex_bench_press');
      expect(restored.exercises[0].prescribedSets[0].setType, RoutineSetType.warmUp);
      expect(restored.exercises[0].prescribedSets[1].isRepRange, isTrue);
      expect(restored.exercises[1].prescribedSets[0].distanceMeters, 5000.0);
    });

    test('rejects unsupported schema version', () {
      final invalidJson = <String, dynamic>{
        'schema_version': 2,
        'routine_id': routineId.value,
        'routine_name': 'Routine',
        'program_id': programId.value,
        'captured_at_utc': capturedAt.toIso8601String(),
        'exercises': <dynamic>[],
      };

      expect(
        () => WorkoutSessionSnapshotDto.fromJson(invalidJson),
        throwsA(isA<WorkoutSessionPersistenceException>().having(
          (e) => e.kind,
          'kind',
          WorkoutSessionPersistenceFailureKind.invalidPayload,
        )),
      );
    });

    test('handles nullable and omitted prescription fields cleanly', () {
      final snapshot = WorkoutSessionSnapshot(
        routineId: routineId,
        routineName: 'Minimal Routine',
        programId: programId,
        capturedAtUtc: capturedAt,
        exercises: [
          SessionExerciseSnapshot(
            exerciseRef: CatalogExerciseRef('ex_pull_ups'),
            displayName: 'Bodyweight Pull Ups',
            occurrenceIndex: 0,
            prescribedSets: [
              SetPrescription(
                setType: RoutineSetType.normal,
              ),
            ],
          ),
        ],
      );

      final json = WorkoutSessionSnapshotDto.toJson(snapshot);
      final setJson = (json['exercises'] as List)[0]['prescribed_sets'][0];
      expect(setJson.containsKey('reps'), isFalse);
      expect(setJson.containsKey('load_kg'), isFalse);
      expect(setJson.containsKey('distance_meters'), isFalse);
      expect(setJson.containsKey('duration_seconds'), isFalse);

      final restored = WorkoutSessionSnapshotDto.fromJson(json);
      expect(restored.exercises[0].exerciseType, isNull);
      expect(restored.exercises[0].prescribedSets[0].reps, isNull);
      expect(restored.exercises[0].prescribedSets[0].loadKg, isNull);
    });
  });

  group('WorkoutPerformedSetRowDto', () {
    test('maps raw SQL row to domain and RPC parameters', () {
      final completedAt = DateTime.utc(2026, 11, 7, 10, 15, 30);
      final rowJson = <String, dynamic>{
        'id': '11111111-1111-4111-a111-111111111111',
        'session_id': '22222222-2222-4222-a222-222222222222',
        'user_id': '33333333-3333-4333-a333-333333333333',
        'exercise_ref': 'ex_bench_press',
        'session_exercise_index': 0,
        'set_index': 1,
        'reps': 10,
        'load_kg': 82.5,
        'duration_seconds': 45,
        'distance_meters': null,
        'completed_at_utc': completedAt.toIso8601String(),
        'is_skipped': false,
        'notes': 'RPE 8.5 good velocity',
        'created_at': completedAt.toIso8601String(),
        'updated_at': completedAt.toIso8601String(),
      };

      final dto = WorkoutPerformedSetRowDto.fromJson(rowJson);
      expect(dto.id, '11111111-1111-4111-a111-111111111111');
      expect(dto.loadKg, 82.5);

      final domain = dto.toDomain();
      expect(domain.id, '11111111-1111-4111-a111-111111111111');
      expect(domain.exerciseRef.value, 'ex_bench_press');
      expect(domain.reps, 10);
      expect(domain.loadKg, 82.5);
      expect(domain.notes, 'RPE 8.5 good velocity');

      final rpcParams = WorkoutPerformedSetRowDto.toRpcParams(
        sessionId: '22222222-2222-4222-a222-222222222222',
        expectedRevision: 3,
        set: domain,
      );

      expect(rpcParams['p_set_id'], '11111111-1111-4111-a111-111111111111');
      expect(rpcParams['p_session_id'], '22222222-2222-4222-a222-222222222222');
      expect(rpcParams['p_expected_session_revision'], 3);
      expect(rpcParams['p_exercise_ref'], 'ex_bench_press');
      expect(rpcParams['p_reps'], 10);
      expect(rpcParams['p_load_kg'], 82.5);
      expect(rpcParams['p_is_skipped'], isFalse);
    });
  });

  group('WorkoutSessionRowDto', () {
    test('maps raw SQL row to pure-Dart WorkoutSession and WorkoutSessionRecord', () {
      final startedAt = DateTime.utc(2026, 11, 7, 10, 0, 0);
      final pausedAt = DateTime.utc(2026, 11, 7, 10, 20, 0);
      final snapshot = WorkoutSessionSnapshot(
        routineId: RoutineId('aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa'),
        routineName: 'Leg Day',
        programId: ProgramId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb'),
        capturedAtUtc: startedAt,
        exercises: [
          SessionExerciseSnapshot(
            exerciseRef: CatalogExerciseRef('ex_squat'),
            displayName: 'Barbell Back Squat',
            occurrenceIndex: 0,
            prescribedSets: [
              SetPrescription(setType: RoutineSetType.normal, reps: 5, loadKg: 100),
            ],
          ),
        ],
      );

      final rowJson = <String, dynamic>{
        'id': 'cccccccc-cccc-4ccc-accc-cccccccccccc',
        'user_id': 'dddddddd-dddd-4ddd-addd-dddddddddddd',
        'program_id': 'bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb',
        'routine_id': 'aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa',
        'status': 'paused',
        'started_at_utc': startedAt.toIso8601String(),
        'paused_at_utc': pausedAt.toIso8601String(),
        'completed_at_utc': null,
        'last_transition_at_utc': pausedAt.toIso8601String(),
        'accumulated_paused_microseconds': 0,
        'local_date': '2026-11-07',
        'routine_snapshot': WorkoutSessionSnapshotDto.toJson(snapshot),
        'notes': 'Felt strong on squats',
        'discard_reason': null,
        'revision': 4,
        'created_at': startedAt.toIso8601String(),
        'updated_at': pausedAt.toIso8601String(),
      };

      final dto = WorkoutSessionRowDto.fromJson(rowJson);
      expect(dto.id, 'cccccccc-cccc-4ccc-accc-cccccccccccc');
      expect(dto.revision, 4);
      expect(dto.status, 'paused');

      final record = dto.toRecord();
      expect(record.revision, 4);
      expect(record.syncState, WorkoutSessionSyncState.synced);
      expect(record.session.status, WorkoutSessionStatus.paused);
      expect(record.session.time.pausedAtUtc, pausedAt);
      expect(record.session.notes, 'Felt strong on squats');
      expect(record.session.discardReason, isNull);
    });
  });
}
