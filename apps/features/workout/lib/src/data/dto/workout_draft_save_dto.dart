import 'package:tio_shared/shared.dart';

import '../../domain/models/active_workout_draft.dart';
import '../../domain/repositories/workout_draft_save_repository.dart';
import 'workout_session_dtos.dart';

abstract final class WorkoutDraftSaveDto {
  static Map<String, dynamic> payload(ActiveWorkoutDraft draft) {
    final completedAtUtc = draft.submittedAtUtc;
    final title = draft.submittedTitle;
    final workoutAtUtc = draft.workoutAtUtc;
    final offset = draft.workoutUtcOffsetMinutes;
    if (completedAtUtc == null ||
        title == null ||
        workoutAtUtc == null ||
        offset == null ||
        !draft.time.isPaused) {
      throw StateError('Workout draft has no frozen Save submission.');
    }
    final completedTime = draft.time.finish(completedAtUtc);
    final performed = <Map<String, dynamic>>[];
    final exercises = <Map<String, dynamic>>[];
    for (var exerciseIndex = 0;
        exerciseIndex < draft.exercises.length;
        exerciseIndex++) {
      final exercise = draft.exercises[exerciseIndex];
      final sets = <Map<String, dynamic>>[];
      for (var setIndex = 0; setIndex < exercise.sets.length; setIndex++) {
        final set = exercise.sets[setIndex];
        final p = set.prescription;
        sets.add({
          'set_type': p.setType.wireValue,
          if (p.reps != null) 'reps': p.reps,
          if (p.repsMax != null) 'reps_max': p.repsMax,
          if (p.loadKg != null) 'load_kg': p.loadKg,
          if (p.distanceMeters != null) 'distance_meters': p.distanceMeters,
          if (p.durationSeconds != null) 'duration_seconds': p.durationSeconds,
          if (p.restSeconds != null) 'rest_seconds': p.restSeconds,
          if (set.rpe != null) 'performed_rpe': set.rpe,
        });
        if (set.loggedAtUtc != null) {
          performed.add({
            'exercise_ref': exercise.exerciseRef.value,
            'exercise_index': exerciseIndex,
            'set_index': setIndex,
            if (set.reps != null) 'reps': set.reps,
            if (set.loadKg != null) 'load_kg': set.loadKg,
            if (set.durationSeconds != null)
              'duration_seconds': set.durationSeconds,
            if (set.distanceMeters != null)
              'distance_meters': set.distanceMeters,
            'completed_at_utc': set.loggedAtUtc!.toIso8601String(),
            'is_skipped': set.isSkipped,
          });
        }
      }
      exercises.add({
        'exercise_ref': exercise.exerciseRef.value,
        'display_name': exercise.displayName,
        if (exercise.exerciseType != null)
          'exercise_type': exercise.exerciseType!.storageValue,
        'occurrence_index': exerciseIndex,
        'prescribed_sets': sets,
      });
    }
    if (performed.isEmpty) throw StateError('Workout has no logged sets.');
    if (exercises.any((exercise) {
      final sets = exercise['prescribed_sets'] as List;
      return sets.isEmpty;
    })) {
      throw StateError('Workout has an exercise with no sets.');
    }
    final payload = <String, dynamic>{
      'started_at_utc': draft.time.startedAtUtc.toIso8601String(),
      'completed_at_utc': completedAtUtc.toIso8601String(),
      'workout_title': title.trim(),
      'workout_at_utc': workoutAtUtc.toIso8601String(),
      'workout_utc_offset_minutes': offset,
      // SQL completion stores blank notes as NULL; keep payload/readback aligned.
      'description': _nullableTrimmed(draft.description),
      'activity_type': _nullableTrimmed(draft.activityType),
      'gym_name': _nullableTrimmed(draft.gymName),
      'overall_rpe': draft.overallRpe,
      'selected_duration_seconds': draft.selectedDurationSeconds ??
          draft.time.elapsedActiveDuration(completedAtUtc).inSeconds,
      'routine_snapshot': {
        'schema_version': 2,
        'origin': 'ad_hoc',
        'captured_at_utc': draft.time.startedAtUtc.toIso8601String(),
        'exercises': exercises,
      },
      'performed_sets': performed,
    };
    // Linked legacy sessions reject a non-null pause field in the Save RPC.
    if (draft.canonicalSessionId == null) {
      payload['accumulated_paused_microseconds'] =
          completedTime.accumulatedPausedDuration.inMicroseconds;
    }
    return payload;
  }

  static SavedWorkoutDraftRecord record(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> setRows,
  ) {
    if (row['status'] != 'completed' || row['save_request_id'] == null) {
      throw const FormatException('Not a completed Save-only workout.');
    }
    final snapshot = Map<String, dynamic>.from(row['routine_snapshot'] as Map);
    final isAdHoc = row['program_id'] == null && row['routine_id'] == null;
    if (isAdHoc) {
      if (snapshot['schema_version'] != 2 || snapshot['origin'] != 'ad_hoc') {
        throw const FormatException('Not an ad-hoc workout snapshot.');
      }
    } else if (snapshot['schema_version'] != 1 &&
        snapshot['schema_version'] != 2) {
      throw const FormatException('Unsupported linked workout snapshot.');
    }
    return SavedWorkoutDraftRecord(
      sessionId: WorkoutSessionId(row['id'] as String),
      ownerId: row['user_id'] as String,
      saveRequestId: row['save_request_id'] as String,
      revision: (row['revision'] as num).toInt(),
      title: row['workout_title'] as String,
      workoutAtUtc: DateTime.parse(row['workout_at_utc'] as String).toUtc(),
      utcOffsetMinutes: (row['workout_utc_offset_minutes'] as num).toInt(),
      localDate: row['local_date'] as String,
      description: row['notes'] as String?,
      activityType: row['workout_activity_type'] as String?,
      gymName: row['gym_name'] as String?,
      overallRpe: (row['workout_rpe'] as num?)?.toDouble(),
      durationSeconds: (row['workout_duration_seconds'] as num).toInt(),
      snapshot: snapshot,
      performedSets: List.unmodifiable(setRows.map(
        (row) => WorkoutPerformedSetRowDto.fromJson(row).toDomain(),
      )),
    );
  }

  static bool matches(
    SavedWorkoutDraftRecord record,
    ActiveWorkoutDraft draft,
    Map<String, dynamic> payload,
  ) {
    final expectedSets = payload['performed_sets'] as List;
    final wall =
        record.workoutAtUtc.add(Duration(minutes: record.utcOffsetMinutes));
    final localDate =
        '${wall.year.toString().padLeft(4, '0')}-${wall.month.toString().padLeft(2, '0')}-${wall.day.toString().padLeft(2, '0')}';
    if (record.ownerId.toLowerCase() != draft.ownerId ||
        record.saveRequestId.toLowerCase() != draft.saveRequestId ||
        record.title != payload['workout_title'] ||
        record.workoutAtUtc.toIso8601String() != payload['workout_at_utc'] ||
        record.utcOffsetMinutes != payload['workout_utc_offset_minutes'] ||
        record.localDate != localDate ||
        record.description != _nullableTrimmed(payload['description'] as String?) ||
        record.activityType !=
            _nullableTrimmed(payload['activity_type'] as String?) ||
        record.gymName != _nullableTrimmed(payload['gym_name'] as String?) ||
        record.overallRpe != payload['overall_rpe'] ||
        record.durationSeconds != payload['selected_duration_seconds'] ||
        !_deepEquals(record.snapshot, payload['routine_snapshot']) ||
        record.performedSets.length != expectedSets.length) {
      return false;
    }
    for (var index = 0; index < expectedSets.length; index++) {
      final expected = expectedSets[index] as Map;
      final actual = record.performedSets[index];
      if (actual.exerciseRef.value != expected['exercise_ref'] ||
          actual.sessionExerciseIndex != expected['exercise_index'] ||
          actual.setIndex != expected['set_index'] ||
          actual.reps != expected['reps'] ||
          actual.loadKg != expected['load_kg'] ||
          actual.durationSeconds != expected['duration_seconds'] ||
          actual.distanceMeters != expected['distance_meters'] ||
          actual.isSkipped != expected['is_skipped'] ||
          actual.completedAtUtc?.toIso8601String() !=
              expected['completed_at_utc']) {
        return false;
      }
    }
    return true;
  }

  static String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static bool _deepEquals(Object? a, Object? b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }
}
