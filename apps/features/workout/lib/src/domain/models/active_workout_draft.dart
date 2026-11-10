import 'package:tio_shared/shared.dart';

import 'routine_composition_limits.dart';
import 'routine_rest_timer_preset.dart';

const _unchanged = Object();

/// Device-local, versioned workout state. Its identity is never a server session ID.
/// Per-exercise notes are intentionally absent from this persistence contract.
final class ActiveWorkoutDraft {
  ActiveWorkoutDraft({
    required String id,
    required String ownerId,
    required String saveRequestId,
    required this.time,
    this.revision = 0,
    List<ActiveWorkoutDraftExercise> exercises = const [],
    this.canonicalSessionId,
    this.canonicalRevision,
    this.workoutTitle,
    this.description,
    this.workoutAtUtc,
    this.workoutUtcOffsetMinutes,
    this.selectedDurationSeconds,
    this.gymName,
    this.activityType,
    this.overallRpe,
    this.activeRest,
  })  : id = _uuid(id),
        ownerId = _uuid(ownerId),
        saveRequestId = _uuid(saveRequestId),
        exercises = List.unmodifiable(exercises) {
    if (revision < 0 || (canonicalRevision != null && canonicalRevision! < 0)) {
      throw ArgumentError('Draft revisions must be non-negative.');
    }
    if ((canonicalSessionId == null) != (canonicalRevision == null)) {
      throw ArgumentError(
          'Canonical session identity and revision must be paired.');
    }
    if (time.isCompleted) {
      throw ArgumentError('A local draft cannot be terminal.');
    }
    if ((workoutAtUtc == null) != (workoutUtcOffsetMinutes == null) ||
        workoutAtUtc != null && !workoutAtUtc!.isUtc ||
        workoutUtcOffsetMinutes != null &&
            (workoutUtcOffsetMinutes! < -840 ||
                workoutUtcOffsetMinutes! > 840) ||
        selectedDurationSeconds != null && selectedDurationSeconds! < 0 ||
        overallRpe != null &&
            (!overallRpe!.isFinite || overallRpe! < 0 || overallRpe! > 10)) {
      throw ArgumentError('Invalid draft Save metadata.');
    }
    if (exercises.length > 100) {
      throw ArgumentError('Too many draft exercises.');
    }
    final exerciseIds = <String>{};
    final setIds = <String>{};
    for (final exercise in exercises) {
      if (!exerciseIds.add(exercise.id)) {
        throw ArgumentError('Duplicate exercise ID.');
      }
      for (final set in exercise.sets) {
        if (!setIds.add(set.id)) {
          throw ArgumentError('Duplicate set ID.');
        }
      }
    }
    if (activeRest != null &&
        !exercises.any((exercise) =>
            exercise.id == activeRest!.exerciseId &&
            exercise.sets.any((set) => set.id == activeRest!.setId))) {
      throw ArgumentError('Rest timer references a removed draft set.');
    }
  }

  static const schemaVersion = 1;
  final String id;
  final String ownerId;
  final String saveRequestId;
  final int revision;
  final WorkoutTime time;
  final List<ActiveWorkoutDraftExercise> exercises;
  final WorkoutSessionId? canonicalSessionId;
  final int? canonicalRevision;
  final String? workoutTitle;
  final String? description;
  final DateTime? workoutAtUtc;
  final int? workoutUtcOffsetMinutes;
  final int? selectedDurationSeconds;
  final String? gymName;
  final String? activityType;
  final double? overallRpe;
  final ActiveWorkoutDraftRest? activeRest;

  ActiveWorkoutDraft copyWith({
    WorkoutTime? time,
    int? revision,
    List<ActiveWorkoutDraftExercise>? exercises,
    Object? canonicalSessionId = _unchanged,
    Object? canonicalRevision = _unchanged,
    Object? workoutTitle = _unchanged,
    Object? description = _unchanged,
    Object? workoutAtUtc = _unchanged,
    Object? workoutUtcOffsetMinutes = _unchanged,
    Object? selectedDurationSeconds = _unchanged,
    Object? gymName = _unchanged,
    Object? activityType = _unchanged,
    Object? overallRpe = _unchanged,
    Object? activeRest = _unchanged,
  }) =>
      ActiveWorkoutDraft(
        id: id,
        ownerId: ownerId,
        saveRequestId: saveRequestId,
        time: time ?? this.time,
        revision: revision ?? this.revision,
        exercises: exercises ?? this.exercises,
        canonicalSessionId: identical(canonicalSessionId, _unchanged)
            ? this.canonicalSessionId
            : canonicalSessionId as WorkoutSessionId?,
        canonicalRevision: identical(canonicalRevision, _unchanged)
            ? this.canonicalRevision
            : canonicalRevision as int?,
        workoutTitle: identical(workoutTitle, _unchanged)
            ? this.workoutTitle
            : workoutTitle as String?,
        description: identical(description, _unchanged)
            ? this.description
            : description as String?,
        workoutAtUtc: identical(workoutAtUtc, _unchanged)
            ? this.workoutAtUtc
            : workoutAtUtc as DateTime?,
        workoutUtcOffsetMinutes: identical(workoutUtcOffsetMinutes, _unchanged)
            ? this.workoutUtcOffsetMinutes
            : workoutUtcOffsetMinutes as int?,
        selectedDurationSeconds: identical(selectedDurationSeconds, _unchanged)
            ? this.selectedDurationSeconds
            : selectedDurationSeconds as int?,
        gymName:
            identical(gymName, _unchanged) ? this.gymName : gymName as String?,
        activityType: identical(activityType, _unchanged)
            ? this.activityType
            : activityType as String?,
        overallRpe: identical(overallRpe, _unchanged)
            ? this.overallRpe
            : overallRpe as double?,
        activeRest: identical(activeRest, _unchanged)
            ? this.activeRest
            : activeRest as ActiveWorkoutDraftRest?,
      );

  Map<String, Object?> toJson() => {
        'version': schemaVersion,
        'id': id,
        'owner_id': ownerId,
        'save_request_id': saveRequestId,
        'revision': revision,
        'time': {
          'started_at_utc': time.startedAtUtc.toIso8601String(),
          'paused_at_utc': time.pausedAtUtc?.toIso8601String(),
          'accumulated_paused_microseconds':
              time.accumulatedPausedDuration.inMicroseconds,
          'last_transition_at_utc': time.lastTransitionAtUtc.toIso8601String(),
        },
        'canonical_session_id': canonicalSessionId?.value,
        'canonical_revision': canonicalRevision,
        'workout_title': workoutTitle,
        'description': description,
        'workout_at_utc': workoutAtUtc?.toIso8601String(),
        'workout_utc_offset_minutes': workoutUtcOffsetMinutes,
        'selected_duration_seconds': selectedDurationSeconds,
        'gym_name': gymName,
        'activity_type': activityType,
        'overall_rpe': overallRpe,
        'active_rest': activeRest?.toJson(),
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      };

  factory ActiveWorkoutDraft.fromJson(Map<String, dynamic> json) {
    if (json['version'] != schemaVersion) {
      throw const FormatException('Unsupported ActiveWorkoutDraft version.');
    }
    try {
      final timeJson = Map<String, dynamic>.from(json['time'] as Map);
      DateTime? optionalUtc(Object? value) =>
          value == null ? null : DateTime.parse(value as String).toUtc();
      return ActiveWorkoutDraft(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        saveRequestId: json['save_request_id'] as String,
        revision: json['revision'] as int,
        time: WorkoutTime(
          startedAtUtc:
              DateTime.parse(timeJson['started_at_utc'] as String).toUtc(),
          pausedAtUtc: optionalUtc(timeJson['paused_at_utc']),
          accumulatedPausedDuration: Duration(
            microseconds: timeJson['accumulated_paused_microseconds'] as int,
          ),
          lastTransitionAtUtc:
              DateTime.parse(timeJson['last_transition_at_utc'] as String)
                  .toUtc(),
        ),
        canonicalSessionId: json['canonical_session_id'] == null
            ? null
            : WorkoutSessionId(json['canonical_session_id'] as String),
        canonicalRevision: json['canonical_revision'] as int?,
        workoutTitle: json['workout_title'] as String?,
        description: json['description'] as String?,
        workoutAtUtc: optionalUtc(json['workout_at_utc']),
        workoutUtcOffsetMinutes: json['workout_utc_offset_minutes'] as int?,
        selectedDurationSeconds: json['selected_duration_seconds'] as int?,
        gymName: json['gym_name'] as String?,
        activityType: json['activity_type'] as String?,
        overallRpe: (json['overall_rpe'] as num?)?.toDouble(),
        activeRest: json['active_rest'] == null
            ? null
            : ActiveWorkoutDraftRest.fromJson(
                Map<String, dynamic>.from(json['active_rest'] as Map),
              ),
        exercises: (json['exercises'] as List)
            .map((entry) => ActiveWorkoutDraftExercise.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ))
            .toList(),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid ActiveWorkoutDraft payload.');
    }
  }
}

final class ActiveWorkoutDraftExercise {
  ActiveWorkoutDraftExercise({
    required String id,
    required this.exerciseRef,
    required String displayName,
    this.exerciseType,
    this.thumbnailUrl,
    this.hasRestOverride = false,
    this.restPreset = const RoutineRestTimerPreset(),
    List<ActiveWorkoutDraftSet> sets = const [],
  })  : id = _uuid(id),
        displayName = displayName.trim(),
        sets = List.unmodifiable(sets) {
    if (this.displayName.isEmpty) {
      throw ArgumentError('Exercise name is blank.');
    }
    if (sets.length > RoutineCompositionLimits.maxSetsPerExercise) {
      throw ArgumentError('Too many draft sets.');
    }
    if (sets.map((set) => set.id).toSet().length != sets.length) {
      throw ArgumentError('Duplicate set ID.');
    }
  }

  final String id;
  final ExerciseRef exerciseRef;
  final String displayName;
  final ExerciseType? exerciseType;
  final Uri? thumbnailUrl;
  final bool hasRestOverride;
  final RoutineRestTimerPreset restPreset;
  final List<ActiveWorkoutDraftSet> sets;

  ActiveWorkoutDraftExercise copyWith({
    List<ActiveWorkoutDraftSet>? sets,
    RoutineRestTimerPreset? restPreset,
    bool? hasRestOverride,
  }) =>
      ActiveWorkoutDraftExercise(
        id: id,
        exerciseRef: exerciseRef,
        displayName: displayName,
        exerciseType: exerciseType,
        thumbnailUrl: thumbnailUrl,
        hasRestOverride: hasRestOverride ?? this.hasRestOverride,
        restPreset: restPreset ?? this.restPreset,
        sets: sets ?? this.sets,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'exercise_ref': exerciseRef.value,
        'display_name': displayName,
        'exercise_type': exerciseType?.storageValue,
        'thumbnail_url': thumbnailUrl?.toString(),
        'has_rest_override': hasRestOverride,
        'rest_normal_seconds': restPreset.normalRestSeconds,
        'rest_warm_up_seconds': restPreset.warmUpRestSeconds,
        'sets': sets.map((set) => set.toJson()).toList(),
      };

  factory ActiveWorkoutDraftExercise.fromJson(Map<String, dynamic> json) {
    try {
      return ActiveWorkoutDraftExercise(
        id: json['id'] as String,
        exerciseRef: ExerciseRef.parse(json['exercise_ref'] as String),
        displayName: json['display_name'] as String,
        exerciseType: json['exercise_type'] == null
            ? null
            : ExerciseType.fromStorageValue(json['exercise_type'] as String),
        thumbnailUrl: json['thumbnail_url'] == null
            ? null
            : Uri.parse(json['thumbnail_url'] as String),
        hasRestOverride: json['has_rest_override'] as bool? ?? false,
        restPreset: RoutineRestTimerPreset(
          normalRestSeconds: json['rest_normal_seconds'] as int?,
          warmUpRestSeconds: json['rest_warm_up_seconds'] as int?,
        ),
        sets: (json['sets'] as List)
            .map((entry) => ActiveWorkoutDraftSet.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ))
            .toList(),
      );
    } catch (_) {
      throw const FormatException('Invalid draft exercise.');
    }
  }
}

final class ActiveWorkoutDraftSet {
  ActiveWorkoutDraftSet({
    required String id,
    required this.prescription,
    this.reps,
    this.loadKg,
    this.durationSeconds,
    this.distanceMeters,
    this.rpe,
    this.loggedAtUtc,
    this.isSkipped = false,
  }) : id = _uuid(id) {
    if (reps != null && reps! < 0 ||
        loadKg != null && (!loadKg!.isFinite || loadKg! < 0) ||
        durationSeconds != null && durationSeconds! < 0 ||
        distanceMeters != null &&
            (!distanceMeters!.isFinite || distanceMeters! < 0) ||
        rpe != null && (!rpe!.isFinite || rpe! < 0 || rpe! > 10) ||
        loggedAtUtc != null && !loggedAtUtc!.isUtc) {
      throw ArgumentError('Invalid performed set values.');
    }
    if (loggedAtUtc == null &&
        (reps != null ||
            loadKg != null ||
            durationSeconds != null ||
            distanceMeters != null ||
            isSkipped)) {
      throw ArgumentError('Unlogged set has performed values.');
    }
  }

  final String id;
  final SetPrescription prescription;
  final int? reps;
  final double? loadKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final double? rpe;
  final DateTime? loggedAtUtc;
  final bool isSkipped;

  ActiveWorkoutDraftSet copyWith({
    SetPrescription? prescription,
    Object? reps = _unchanged,
    Object? loadKg = _unchanged,
    Object? durationSeconds = _unchanged,
    Object? distanceMeters = _unchanged,
    Object? rpe = _unchanged,
    Object? loggedAtUtc = _unchanged,
    bool? isSkipped,
  }) =>
      ActiveWorkoutDraftSet(
        id: id,
        prescription: prescription ?? this.prescription,
        reps: identical(reps, _unchanged) ? this.reps : reps as int?,
        loadKg: identical(loadKg, _unchanged) ? this.loadKg : loadKg as double?,
        durationSeconds: identical(durationSeconds, _unchanged)
            ? this.durationSeconds
            : durationSeconds as int?,
        distanceMeters: identical(distanceMeters, _unchanged)
            ? this.distanceMeters
            : distanceMeters as double?,
        rpe: identical(rpe, _unchanged) ? this.rpe : rpe as double?,
        loggedAtUtc: identical(loggedAtUtc, _unchanged)
            ? this.loggedAtUtc
            : loggedAtUtc as DateTime?,
        isSkipped: isSkipped ?? this.isSkipped,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'prescription': {
          'reps': prescription.reps,
          'reps_max': prescription.repsMax,
          'set_type': prescription.setType.wireValue,
          'load_kg': prescription.loadKg,
          'distance_meters': prescription.distanceMeters,
          'duration_seconds': prescription.durationSeconds,
          'rest_seconds': prescription.restSeconds,
        },
        'reps': reps,
        'load_kg': loadKg,
        'duration_seconds': durationSeconds,
        'distance_meters': distanceMeters,
        'rpe': rpe,
        'logged_at_utc': loggedAtUtc?.toIso8601String(),
        'is_skipped': isSkipped,
      };

  factory ActiveWorkoutDraftSet.fromJson(Map<String, dynamic> json) {
    try {
      final p = Map<String, dynamic>.from(json['prescription'] as Map);
      return ActiveWorkoutDraftSet(
        id: json['id'] as String,
        prescription: SetPrescription(
          reps: p['reps'] as int?,
          repsMax: p['reps_max'] as int?,
          setType: RoutineSetType.fromWire(p['set_type'] as String),
          loadKg: (p['load_kg'] as num?)?.toDouble(),
          distanceMeters: (p['distance_meters'] as num?)?.toDouble(),
          durationSeconds: p['duration_seconds'] as int?,
          restSeconds: p['rest_seconds'] as int?,
        ),
        reps: json['reps'] as int?,
        loadKg: (json['load_kg'] as num?)?.toDouble(),
        durationSeconds: json['duration_seconds'] as int?,
        distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
        rpe: (json['rpe'] as num?)?.toDouble(),
        loggedAtUtc: json['logged_at_utc'] == null
            ? null
            : DateTime.parse(json['logged_at_utc'] as String).toUtc(),
        isSkipped: json['is_skipped'] as bool? ?? false,
      );
    } catch (_) {
      throw const FormatException('Invalid draft set.');
    }
  }
}

/// A configured rest countdown, derived from an absolute UTC deadline.
final class ActiveWorkoutDraftRest {
  ActiveWorkoutDraftRest({
    required this.targetAtUtc,
    required this.totalDurationSeconds,
    required String exerciseId,
    required String setId,
  })  : exerciseId = _uuid(exerciseId),
        setId = _uuid(setId) {
    if (!targetAtUtc.isUtc || totalDurationSeconds <= 0) {
      throw ArgumentError('Invalid draft rest timer.');
    }
  }

  final DateTime targetAtUtc;
  final int totalDurationSeconds;
  final String exerciseId;
  final String setId;

  Duration remaining(DateTime nowUtc) {
    final value = targetAtUtc.difference(nowUtc.toUtc());
    return value.isNegative ? Duration.zero : value;
  }

  Map<String, Object?> toJson() => {
        'target_at_utc': targetAtUtc.toIso8601String(),
        'total_duration_seconds': totalDurationSeconds,
        'exercise_id': exerciseId,
        'set_id': setId,
      };

  factory ActiveWorkoutDraftRest.fromJson(Map<String, dynamic> json) {
    try {
      return ActiveWorkoutDraftRest(
        targetAtUtc: DateTime.parse(json['target_at_utc'] as String).toUtc(),
        totalDurationSeconds: json['total_duration_seconds'] as int,
        exerciseId: json['exercise_id'] as String,
        setId: json['set_id'] as String,
      );
    } catch (_) {
      throw const FormatException('Invalid draft rest timer.');
    }
  }
}

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

String _uuid(String value) {
  if (!_uuidPattern.hasMatch(value)) {
    throw ArgumentError.value(value, 'id', 'must be a canonical UUID');
  }
  return value.toLowerCase();
}
