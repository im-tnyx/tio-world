import 'package:tio_shared/shared.dart';

import '../../domain/models/workout_session_record.dart';
import '../../domain/repositories/workout_session_repository.dart';

/// DTO mapping for frozen routine snapshots stored in `user_workout_sessions.routine_snapshot`.
///
/// Adheres strictly to the schema validated by `private.is_valid_workout_session_snapshot_v1`.
abstract final class WorkoutSessionSnapshotDto {
  static const int currentSchemaVersion = 1;

  /// Serializes a [WorkoutSessionSnapshot] to a JSON-compatible map.
  static Map<String, dynamic> toJson(WorkoutSessionSnapshot snapshot) => {
        'schema_version': currentSchemaVersion,
        'routine_id': snapshot.routineId.value,
        'routine_name': snapshot.routineName,
        'program_id': snapshot.programId.value,
        'captured_at_utc': snapshot.capturedAtUtc.toUtc().toIso8601String(),
        'exercises': snapshot.exercises
            .map((exercise) => {
                  'exercise_ref': exercise.exerciseRef.value,
                  'display_name': exercise.displayName,
                  if (exercise.exerciseType != null)
                    'exercise_type': exercise.exerciseType!.storageValue,
                  'occurrence_index': exercise.occurrenceIndex,
                  'prescribed_sets': exercise.prescribedSets
                      .map((set) => {
                            'set_type': set.setType.wireValue,
                            if (set.reps != null) 'reps': set.reps,
                            if (set.repsMax != null) 'reps_max': set.repsMax,
                            if (set.loadKg != null) 'load_kg': set.loadKg,
                            if (set.distanceMeters != null)
                              'distance_meters': set.distanceMeters,
                            if (set.durationSeconds != null)
                              'duration_seconds': set.durationSeconds,
                            if (set.restSeconds != null)
                              'rest_seconds': set.restSeconds,
                          })
                      .toList(growable: false),
                })
            .toList(growable: false),
      };

  /// Deserializes a [WorkoutSessionSnapshot] from a JSON-compatible map.
  static WorkoutSessionSnapshot fromJson(Map<String, dynamic> json) {
    try {
      final schemaVersion = json['schema_version'];
      if (schemaVersion != currentSchemaVersion) {
        throw FormatException(
          'Unsupported snapshot schema_version: $schemaVersion (expected $currentSchemaVersion)',
        );
      }

      final routineId = RoutineId(json['routine_id'] as String);
      final routineName = json['routine_name'] as String;
      final programId = ProgramId(json['program_id'] as String);
      final capturedAtUtc =
          DateTime.parse(json['captured_at_utc'] as String).toUtc();

      final rawExercises = json['exercises'] as List<dynamic>? ?? const [];
      final exercises = rawExercises.map((e) {
        final exerciseMap = Map<String, dynamic>.from(e as Map);
        final exerciseRef =
            ExerciseRef.parse(exerciseMap['exercise_ref'] as String);
        final displayName = exerciseMap['display_name'] as String;
        final rawType = exerciseMap['exercise_type'] as String?;
        final exerciseType =
            rawType != null ? ExerciseType.fromStorageValue(rawType) : null;
        final occurrenceIndex =
            (exerciseMap['occurrence_index'] as num).toInt();

        final rawSets =
            exerciseMap['prescribed_sets'] as List<dynamic>? ?? const [];
        final prescribedSets = rawSets.map((s) {
          final setMap = Map<String, dynamic>.from(s as Map);
          final setType =
              RoutineSetType.fromWire(setMap['set_type'] as String);
          final reps = (setMap['reps'] as num?)?.toInt();
          final repsMax = (setMap['reps_max'] as num?)?.toInt();
          final loadKg = (setMap['load_kg'] as num?)?.toDouble();
          final distanceMeters =
              (setMap['distance_meters'] as num?)?.toDouble();
          final durationSeconds =
              (setMap['duration_seconds'] as num?)?.toInt();
          final restSeconds = (setMap['rest_seconds'] as num?)?.toInt();

          return SetPrescription(
            reps: reps,
            repsMax: repsMax,
            setType: setType,
            loadKg: loadKg,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            restSeconds: restSeconds,
          );
        }).toList(growable: false);

        return SessionExerciseSnapshot(
          exerciseRef: exerciseRef,
          displayName: displayName,
          exerciseType: exerciseType,
          occurrenceIndex: occurrenceIndex,
          prescribedSets: prescribedSets,
        );
      }).toList(growable: false);

      return WorkoutSessionSnapshot(
        routineId: routineId,
        routineName: routineName,
        programId: programId,
        capturedAtUtc: capturedAtUtc,
        exercises: exercises,
      );
    } catch (e, st) {
      if (e is WorkoutSessionPersistenceException) rethrow;
      throw WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.invalidPayload,
        message: 'Malformed workout session snapshot JSON: $e',
        cause: st,
      );
    }
  }
}

/// DTO mapping for `public.user_workout_performed_sets` rows.
final class WorkoutPerformedSetRowDto {
  const WorkoutPerformedSetRowDto({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.exerciseRef,
    required this.sessionExerciseIndex,
    required this.setIndex,
    this.reps,
    this.loadKg,
    this.durationSeconds,
    this.distanceMeters,
    this.completedAtUtc,
    this.isSkipped = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String userId;
  final String exerciseRef;
  final int sessionExerciseIndex;
  final int setIndex;
  final int? reps;
  final double? loadKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final DateTime? completedAtUtc;
  final bool isSkipped;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WorkoutPerformedSetRowDto.fromJson(Map<String, dynamic> json) {
    try {
      return WorkoutPerformedSetRowDto(
        id: json['id'] as String,
        sessionId: json['session_id'] as String,
        userId: json['user_id'] as String,
        exerciseRef: json['exercise_ref'] as String,
        sessionExerciseIndex: (json['session_exercise_index'] as num).toInt(),
        setIndex: (json['set_index'] as num).toInt(),
        reps: (json['reps'] as num?)?.toInt(),
        loadKg: (json['load_kg'] as num?)?.toDouble(),
        durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
        distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
        completedAtUtc: json['completed_at_utc'] != null
            ? DateTime.parse(json['completed_at_utc'] as String).toUtc()
            : null,
        isSkipped: (json['is_skipped'] as bool?) ?? false,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String).toUtc()
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String).toUtc()
            : null,
      );
    } catch (e, st) {
      throw WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.invalidPayload,
        message: 'Malformed performed set row JSON: $e',
        cause: st,
      );
    }
  }

  /// Converts this DTO into a canonical [PerformedSet] domain entity.
  PerformedSet toDomain() => PerformedSet(
        id: id,
        exerciseRef: ExerciseRef.parse(exerciseRef),
        sessionExerciseIndex: sessionExerciseIndex,
        setIndex: setIndex,
        reps: reps,
        loadKg: loadKg,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        completedAtUtc: completedAtUtc,
        isSkipped: isSkipped,
        notes: notes,
      );

  /// Builds RPC parameter map for `rpc_log_workout_performed_set`.
  static Map<String, dynamic> toRpcParams({
    required String sessionId,
    required int expectedRevision,
    required PerformedSet set,
  }) =>
      {
        'p_set_id': set.id,
        'p_session_id': sessionId,
        'p_expected_session_revision': expectedRevision,
        'p_exercise_ref': set.exerciseRef.value,
        'p_session_exercise_index': set.sessionExerciseIndex,
        'p_set_index': set.setIndex,
        'p_reps': set.reps,
        'p_load_kg': set.loadKg,
        'p_duration_seconds': set.durationSeconds,
        'p_distance_meters': set.distanceMeters,
        'p_completed_at_utc': set.completedAtUtc?.toUtc().toIso8601String(),
        'p_is_skipped': set.isSkipped,
        'p_notes': set.notes,
      };
}

/// DTO mapping for `public.user_workout_sessions` rows.
final class WorkoutSessionRowDto {
  const WorkoutSessionRowDto({
    required this.id,
    required this.userId,
    required this.programId,
    required this.routineId,
    required this.status,
    required this.startedAtUtc,
    this.pausedAtUtc,
    this.completedAtUtc,
    required this.lastTransitionAtUtc,
    required this.accumulatedPausedMicroseconds,
    required this.localDate,
    required this.routineSnapshot,
    this.notes,
    this.discardReason,
    required this.revision,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String programId;
  final String routineId;
  final String status;
  final DateTime startedAtUtc;
  final DateTime? pausedAtUtc;
  final DateTime? completedAtUtc;
  final DateTime lastTransitionAtUtc;
  final int accumulatedPausedMicroseconds;
  final String localDate;
  final Map<String, dynamic> routineSnapshot;
  final String? notes;
  final String? discardReason;
  final int revision;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WorkoutSessionRowDto.fromJson(Map<String, dynamic> json) {
    try {
      final rawSnapshot = json['routine_snapshot'];
      final Map<String, dynamic> snapshotMap;
      if (rawSnapshot is Map<String, dynamic>) {
        snapshotMap = rawSnapshot;
      } else if (rawSnapshot is Map) {
        snapshotMap = Map<String, dynamic>.from(rawSnapshot);
      } else {
        throw const FormatException('Missing or non-map routine_snapshot');
      }

      return WorkoutSessionRowDto(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        programId: json['program_id'] as String,
        routineId: json['routine_id'] as String,
        status: json['status'] as String,
        startedAtUtc: DateTime.parse(json['started_at_utc'] as String).toUtc(),
        pausedAtUtc: json['paused_at_utc'] != null
            ? DateTime.parse(json['paused_at_utc'] as String).toUtc()
            : null,
        completedAtUtc: json['completed_at_utc'] != null
            ? DateTime.parse(json['completed_at_utc'] as String).toUtc()
            : null,
        lastTransitionAtUtc:
            DateTime.parse(json['last_transition_at_utc'] as String).toUtc(),
        accumulatedPausedMicroseconds:
            (json['accumulated_paused_microseconds'] as num).toInt(),
        localDate: json['local_date'] as String,
        routineSnapshot: snapshotMap,
        notes: json['notes'] as String?,
        discardReason: json['discard_reason'] as String?,
        revision: (json['revision'] as num).toInt(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String).toUtc()
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String).toUtc()
            : null,
      );
    } catch (e, st) {
      throw WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.invalidPayload,
        message: 'Malformed workout session row JSON: $e',
        cause: st,
      );
    }
  }

  /// Converts this row DTO and an optional list of [performedSets] into
  /// a pure-Dart [WorkoutSession] domain aggregate.
  WorkoutSession toDomain({
    List<PerformedSet> performedSets = const [],
    WorkoutSessionSnapshot? snapshotOverride,
  }) {
    final parsedSnapshot = snapshotOverride ??
        WorkoutSessionSnapshotDto.fromJson(routineSnapshot);

    final domainStatus = WorkoutSessionStatus.fromWire(status);

    final time = WorkoutTime(
      startedAtUtc: startedAtUtc,
      pausedAtUtc: pausedAtUtc,
      accumulatedPausedDuration: Duration(
        microseconds: accumulatedPausedMicroseconds,
      ),
      completedAtUtc: completedAtUtc,
      lastTransitionAtUtc: lastTransitionAtUtc,
    );

    return WorkoutSession(
      id: WorkoutSessionId(id),
      userId: userId,
      programId: ProgramId(programId),
      routineId: RoutineId(routineId),
      status: domainStatus,
      time: time,
      localDate: localDate,
      snapshot: parsedSnapshot,
      performedSets: performedSets,
      notes: notes,
      discardReason: discardReason,
    );
  }

  /// Converts this row DTO into an authoritative [WorkoutSessionRecord] envelope.
  WorkoutSessionRecord toRecord({
    List<PerformedSet> performedSets = const [],
    WorkoutSessionSnapshot? snapshotOverride,
    WorkoutSessionSyncState syncState = WorkoutSessionSyncState.synced,
  }) =>
      WorkoutSessionRecord(
        session: toDomain(
          performedSets: performedSets,
          snapshotOverride: snapshotOverride,
        ),
        revision: revision,
        syncState: syncState,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
