import '../../domain/models/routine_composition_limits.dart';
import '../../domain/models/workout_history_entry.dart';
import '../../domain/models/workout_save_metadata_limits.dart';
import '../../domain/repositories/workout_history_edit_repository.dart';

abstract final class WorkoutHistoryEditDto {
  static bool matches(
      WorkoutHistoryDetail detail, Map<String, dynamic> payload) {
    final expected = payload['performed_sets'] as List;
    final actual = detail.allPerformedSets;
    if (detail.summary.title != payload['workout_title'] ||
        detail.summary.description !=
            _nonBlank(payload['description'] as String?) ||
        detail.summary.gymName != _nonBlank(payload['gym_name'] as String?) ||
        detail.workoutAtUtc?.toIso8601String() != payload['workout_at_utc'] ||
        detail.utcOffsetMinutes != payload['workout_utc_offset_minutes'] ||
        detail.summary.duration.inSeconds !=
            payload['selected_duration_seconds'] ||
        detail.activityType != _nonBlank(payload['activity_type'] as String?) ||
        detail.overallRpe != payload['overall_rpe'] ||
        !_deepEqual(detail.rawSnapshot, payload['routine_snapshot']) ||
        actual.length != expected.length) {
      return false;
    }
    for (var i = 0; i < expected.length; i++) {
      final row = expected[i] as Map;
      final set = actual[i];
      if (set.exerciseRef.value != row['exercise_ref'] ||
          set.sessionExerciseIndex != row['exercise_index'] ||
          set.setIndex != row['set_index'] ||
          set.reps != row['reps'] ||
          set.loadKg != row['load_kg'] ||
          set.durationSeconds != row['duration_seconds'] ||
          set.distanceMeters != row['distance_meters'] ||
          set.isSkipped != row['is_skipped'] ||
          set.completedAtUtc?.toIso8601String() != row['completed_at_utc']) {
        return false;
      }
    }
    return true;
  }

  static String? _nonBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static bool _deepEqual(Object? a, Object? b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.keys
              .every((key) => b.containsKey(key) && _deepEqual(a[key], b[key]));
    }
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(a.length, (i) => i)
              .every((i) => _deepEqual(a[i], b[i]));
    }
    return a == b;
  }

  static Map<String, dynamic> payload(WorkoutHistoryEditRequest request) {
    final source = request.source;
    final original = source.rawSnapshot;
    final hasUnsupportedExistingSetCount =
        source.snapshot?.exercises.any((exercise) =>
                exercise.prescribedSets.length >
                RoutineCompositionLimits.maxSetsPerExercise) ==
            true ||
        source.allPerformedSets.any((set) =>
            set.setIndex >= RoutineCompositionLimits.maxSetsPerExercise);
    if (hasUnsupportedExistingSetCount) {
      throw ArgumentError(
          'The existing workout exceeds the supported eight-set editor limit.');
    }
    if (source.revision == null ||
        original == null ||
        !WorkoutSaveMetadataLimits.isValidTitle(request.title) ||
        !WorkoutSaveMetadataLimits.isValidDescription(request.description) ||
        !WorkoutSaveMetadataLimits.isValidGymName(request.gymName) ||
        !WorkoutSaveMetadataLimits.isValidActivityType(request.activityType) ||
        request.durationSeconds < 0 ||
        request.durationSeconds > 2592000 ||
        request.utcOffsetMinutes < -840 ||
        request.utcOffsetMinutes > 840 ||
        !request.workoutAtUtc.isUtc ||
        request.workoutAtUtc.isAfter(source.summary.completedAtUtc) ||
        request.exercises.isEmpty ||
        request.exercises.length > 100) {
      throw ArgumentError('Invalid completed-workout edit.');
    }
    final oldById = {
      for (final set in source.allPerformedSets) set.id: set,
    };
    final snapshot = Map<String, dynamic>.from(original);
    final performed = <Map<String, dynamic>>[];
    final activeSupersetIds = request.exercises
        .map((exercise) => exercise.supersetId)
        .whereType<String>()
        .toSet();
    final originalGroups = (original['superset_groups'] as List? ?? const [])
        .map((group) => Map<String, dynamic>.from(group as Map));
    if (original.containsKey('superset_groups') || activeSupersetIds.isNotEmpty) {
      snapshot['superset_groups'] = [
        for (final group in originalGroups)
          if (activeSupersetIds.contains(group['id'])) group,
      ];
    }
    snapshot['exercises'] = [
      for (final (exerciseIndex, exercise) in request.exercises.indexed)
        {
          'exercise_ref': exercise.exerciseRef.value,
          'display_name': exercise.displayName,
          if (exercise.supersetId != null)
            'superset_id': exercise.supersetId,
          if (exercise.exerciseType != null)
            'exercise_type': exercise.exerciseType!.storageValue,
          'occurrence_index': exerciseIndex,
          'prescribed_sets': [
            for (final set in exercise.sets)
              {
                'set_type': set.prescription.setType.wireValue,
                if (set.prescription.reps != null)
                  'reps': set.prescription.reps,
                if (set.prescription.repsMax != null)
                  'reps_max': set.prescription.repsMax,
                if (set.prescription.loadKg != null)
                  'load_kg': set.prescription.loadKg,
                if (set.prescription.distanceMeters != null)
                  'distance_meters': set.prescription.distanceMeters,
                if (set.prescription.durationSeconds != null)
                  'duration_seconds': set.prescription.durationSeconds,
                if (set.prescription.restSeconds != null)
                  'rest_seconds': set.prescription.restSeconds,
                if (set.rpe != null) 'performed_rpe': set.rpe,
              },
          ],
        },
    ];
    for (final (exerciseIndex, exercise) in request.exercises.indexed) {
      if (exercise.sets.isEmpty ||
          exercise.sets.length > RoutineCompositionLimits.maxSetsPerExercise) {
        throw ArgumentError('Each exercise needs 1–8 sets.');
      }
      for (final (setIndex, set) in exercise.sets.indexed) {
        final old = oldById[set.id];
        final preserveSkipped = set.loggedAtUtc == null &&
            old?.isSkipped == true &&
            old?.completedAtUtc == null;
        if (set.loggedAtUtc == null && !preserveSkipped) continue;
        performed.add({
          if (old != null) 'id': set.id,
          'exercise_ref': exercise.exerciseRef.value,
          'exercise_index': exerciseIndex,
          'set_index': setIndex,
          if (set.reps != null) 'reps': set.reps,
          if (set.loadKg != null) 'load_kg': set.loadKg,
          if (set.durationSeconds != null)
            'duration_seconds': set.durationSeconds,
          if (set.distanceMeters != null) 'distance_meters': set.distanceMeters,
          'completed_at_utc': set.loggedAtUtc?.toIso8601String(),
          'is_skipped': preserveSkipped || set.isSkipped,
        });
      }
    }
    if (performed.isEmpty ||
        performed.length > 500 ||
        !performed.any((set) => set['is_skipped'] == false)) {
      throw ArgumentError('A completed workout needs performed sets.');
    }
    return {
      'workout_title': request.title.trim(),
      'description': request.description?.trim(),
      'workout_at_utc': request.workoutAtUtc.toIso8601String(),
      'workout_utc_offset_minutes': request.utcOffsetMinutes,
      'selected_duration_seconds': request.durationSeconds,
      'gym_name': request.gymName?.trim(),
      'activity_type': request.activityType?.trim(),
      'overall_rpe': request.overallRpe,
      'routine_snapshot': snapshot,
      'performed_sets': performed,
    };
  }
}
