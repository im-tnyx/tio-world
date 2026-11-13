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
    List<ActiveWorkoutDraftSuperset> supersets = const [],
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
    this.backgroundedAtUtc,
    this.lastActivityAtUtc,
    this.submittedAtUtc,
    this.submittedTitle,
  })  : id = _uuid(id),
        ownerId = _uuid(ownerId),
        saveRequestId = _uuid(saveRequestId),
        exercises = List.unmodifiable(exercises),
        supersets = List.unmodifiable(supersets) {
    if (backgroundedAtUtc != null &&
        (!backgroundedAtUtc!.isUtc ||
            time.isPaused ||
            backgroundedAtUtc!.isBefore(time.lastTransitionAtUtc))) {
      throw ArgumentError('Invalid workout background timestamp.');
    }
    if (lastActivityAtUtc != null &&
        (!lastActivityAtUtc!.isUtc ||
            lastActivityAtUtc!.isBefore(time.startedAtUtc))) {
      throw ArgumentError('Invalid workout activity timestamp.');
    }
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
    if ((submittedAtUtc == null) != (submittedTitle == null) ||
        submittedAtUtc != null &&
            (!submittedAtUtc!.isUtc ||
                !time.isPaused ||
                submittedAtUtc!.isBefore(time.pausedAtUtc!)) ||
        submittedTitle != null && submittedTitle!.trim().isEmpty) {
      throw ArgumentError('Invalid pending Save submission.');
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
    final groupIds = supersets.map((group) => group.id).toSet();
    if (groupIds.length != supersets.length) {
      throw ArgumentError('Duplicate Superset ID.');
    }
    final members = <String, List<int>>{};
    for (var index = 0; index < exercises.length; index++) {
      final groupId = exercises[index].supersetId;
      if (groupId == null) continue;
      if (!groupIds.contains(groupId)) {
        throw ArgumentError('Draft exercise references a missing Superset.');
      }
      (members[groupId] ??= []).add(index);
    }
    for (final group in supersets) {
      final positions = members[group.id] ?? const <int>[];
      if (positions.length < 2 || positions.length > 3 ||
          positions.last - positions.first + 1 != positions.length) {
        throw ArgumentError('Draft Superset must contain 2–3 contiguous exercises.');
      }
    }
    if (activeRest != null &&
        !exercises.any((exercise) =>
            exercise.id == activeRest!.exerciseId &&
            exercise.sets.any((set) => set.id == activeRest!.setId))) {
      throw ArgumentError('Rest timer references a removed draft set.');
    }
    if (activeRest?.supersetId != null &&
        !groupIds.contains(activeRest!.supersetId)) {
      throw ArgumentError('Rest timer references a missing Superset.');
    }
  }

  static const schemaVersion = 2;
  final String id;
  final String ownerId;
  final String saveRequestId;
  final int revision;
  final WorkoutTime time;
  final List<ActiveWorkoutDraftExercise> exercises;
  final List<ActiveWorkoutDraftSuperset> supersets;
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

  /// Last app background transition while this draft was actively running.
  final DateTime? backgroundedAtUtc;

  /// Last committed draft action, used if the process dies without lifecycle notice.
  final DateTime? lastActivityAtUtc;

  /// Frozen on first Save dispatch so retries use the same owner-scoped key.
  final DateTime? submittedAtUtc;
  final String? submittedTitle;

  ActiveWorkoutDraft copyWith({
    WorkoutTime? time,
    int? revision,
    List<ActiveWorkoutDraftExercise>? exercises,
    List<ActiveWorkoutDraftSuperset>? supersets,
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
    Object? backgroundedAtUtc = _unchanged,
    Object? lastActivityAtUtc = _unchanged,
    Object? submittedAtUtc = _unchanged,
    Object? submittedTitle = _unchanged,
  }) =>
      ActiveWorkoutDraft(
        id: id,
        ownerId: ownerId,
        saveRequestId: saveRequestId,
        time: time ?? this.time,
        revision: revision ?? this.revision,
        exercises: exercises ?? this.exercises,
        supersets: supersets ?? this.supersets,
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
        backgroundedAtUtc: identical(backgroundedAtUtc, _unchanged)
            ? this.backgroundedAtUtc
            : backgroundedAtUtc as DateTime?,
        lastActivityAtUtc: identical(lastActivityAtUtc, _unchanged)
            ? this.lastActivityAtUtc
            : lastActivityAtUtc as DateTime?,
        submittedAtUtc: identical(submittedAtUtc, _unchanged)
            ? this.submittedAtUtc
            : submittedAtUtc as DateTime?,
        submittedTitle: identical(submittedTitle, _unchanged)
            ? this.submittedTitle
            : submittedTitle as String?,
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
        'supersets': supersets.map((group) => group.toJson()).toList(),
        'backgrounded_at_utc': backgroundedAtUtc?.toIso8601String(),
        'last_activity_at_utc': lastActivityAtUtc?.toIso8601String(),
        'submitted_at_utc': submittedAtUtc?.toIso8601String(),
        'submitted_title': submittedTitle,
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      };

  factory ActiveWorkoutDraft.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version != 1 && version != schemaVersion) {
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
        supersets: (json['supersets'] as List? ?? const [])
            .map((entry) => ActiveWorkoutDraftSuperset.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ))
            .toList(),
        backgroundedAtUtc: optionalUtc(json['backgrounded_at_utc']),
        lastActivityAtUtc: optionalUtc(json['last_activity_at_utc']),
        submittedAtUtc: optionalUtc(json['submitted_at_utc']),
        submittedTitle: json['submitted_title'] as String?,
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
    String? supersetId,
    this.hasRestOverride = false,
    this.restPreset = const RoutineRestTimerPreset(),
    List<ActiveWorkoutDraftSet> sets = const [],
  })  : id = _uuid(id),
        supersetId = supersetId == null ? null : _uuid(supersetId),
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
  final String? supersetId;
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
    Object? supersetId = _unchanged,
  }) =>
      ActiveWorkoutDraftExercise(
        id: id,
        exerciseRef: exerciseRef,
        supersetId: identical(supersetId, _unchanged)
            ? this.supersetId
            : supersetId as String?,
        displayName: displayName,
        exerciseType: exerciseType,
        thumbnailUrl: thumbnailUrl,
        hasRestOverride: hasRestOverride ?? this.hasRestOverride,
        restPreset: restPreset ?? this.restPreset,
        sets: sets ?? this.sets,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        if (supersetId != null) 'superset_id': supersetId,
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
        supersetId: json['superset_id'] == null
            ? null
            : json['superset_id'] as String,
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

final class ActiveWorkoutDraftSuperset {
  ActiveWorkoutDraftSuperset({
    required String id,
    required this.restPreset,
  }) : id = _uuid(id) {
    for (final seconds in [
      restPreset.normalRestSeconds,
      restPreset.warmUpRestSeconds,
    ]) {
      if (seconds != null &&
          (seconds < 5 || seconds > 600 || seconds % 5 != 0)) {
        throw ArgumentError('Superset rest must be OFF or 5-second steps up to 600.');
      }
    }
  }

  final String id;
  final RoutineRestTimerPreset restPreset;

  Map<String, Object?> toJson() => {
        'id': id,
        'rest_normal_seconds': restPreset.normalRestSeconds,
        'rest_warm_up_seconds': restPreset.warmUpRestSeconds,
      };

  factory ActiveWorkoutDraftSuperset.fromJson(Map<String, dynamic> json) {
    try {
      return ActiveWorkoutDraftSuperset(
        id: json['id'] as String,
        restPreset: RoutineRestTimerPreset(
          normalRestSeconds: json['rest_normal_seconds'] as int?,
          warmUpRestSeconds: json['rest_warm_up_seconds'] as int?,
        ),
      );
    } catch (_) {
      throw const FormatException('Invalid draft Superset.');
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
    String? supersetId,
    this.roundIndex,
  })  : exerciseId = _uuid(exerciseId),
        setId = _uuid(setId),
        supersetId = supersetId == null ? null : _uuid(supersetId) {
    if (!targetAtUtc.isUtc || totalDurationSeconds <= 0 ||
        (supersetId == null) != (roundIndex == null) ||
        roundIndex != null && roundIndex! < 0) {
      throw ArgumentError('Invalid draft rest timer.');
    }
  }

  final DateTime targetAtUtc;
  final int totalDurationSeconds;
  final String exerciseId;
  final String setId;
  final String? supersetId;
  final int? roundIndex;

  Duration remaining(DateTime nowUtc) {
    final value = targetAtUtc.difference(nowUtc.toUtc());
    return value.isNegative ? Duration.zero : value;
  }

  Map<String, Object?> toJson() => {
        'target_at_utc': targetAtUtc.toIso8601String(),
        'total_duration_seconds': totalDurationSeconds,
        'exercise_id': exerciseId,
        'set_id': setId,
        'superset_id': supersetId,
        'round_index': roundIndex,
      };

  factory ActiveWorkoutDraftRest.fromJson(Map<String, dynamic> json) {
    try {
      return ActiveWorkoutDraftRest(
        targetAtUtc: DateTime.parse(json['target_at_utc'] as String).toUtc(),
        totalDurationSeconds: json['total_duration_seconds'] as int,
        exerciseId: json['exercise_id'] as String,
        setId: json['set_id'] as String,
        supersetId: json['superset_id'] as String?,
        roundIndex: json['round_index'] as int?,
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
