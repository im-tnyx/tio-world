import 'package:tio_shared/shared.dart';

/// Stable keyset position in the completed-session timeline.
final class WorkoutHistoryCursor {
  const WorkoutHistoryCursor(this.completedAtUtc, this.sessionId);

  final DateTime completedAtUtc;
  final WorkoutSessionId sessionId;
}

final class WorkoutHistoryExercise {
  const WorkoutHistoryExercise({
    required this.ref,
    required this.name,
    required this.setCount,
  });

  final ExerciseRef ref;
  final String name;
  final int setCount;
}

/// Read-only completed workout summary.
final class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({
    required this.sessionId,
    required this.completedAtUtc,
    required this.displayAt,
    required this.title,
    required this.duration,
    required this.exercises,
    this.volumeKg,
    this.description,
    this.gymName,
  });

  final WorkoutSessionId sessionId;
  final DateTime completedAtUtc;
  final DateTime displayAt;
  final String title;
  final Duration duration;

  /// Recorded external-load volume from completed performed sets, when known.
  final double? volumeKg;
  final String? description;
  final String? gymName;
  final List<WorkoutHistoryExercise> exercises;

  int get remainingExerciseCount =>
      exercises.length > 5 ? exercises.length - 5 : 0;
}

/// Actual completed sets for one frozen exercise occurrence.
final class WorkoutHistoryDetailExercise {
  const WorkoutHistoryDetailExercise({
    required this.ref,
    required this.name,
    required this.exerciseType,
    required this.sets,
  });

  final ExerciseRef ref;
  final String name;
  final ExerciseType? exerciseType;
  final List<PerformedSet> sets;
}

/// Read-only detail of a canonical completed WorkoutSession.
final class WorkoutHistoryDetail {
  const WorkoutHistoryDetail({required this.summary, required this.exercises});

  final WorkoutHistoryEntry summary;
  final List<WorkoutHistoryDetailExercise> exercises;

  int get performedSetCount =>
      exercises.fold(0, (count, exercise) => count + exercise.sets.length);
}

final class WorkoutHistoryPageResult {
  const WorkoutHistoryPageResult({
    required this.entries,
    required this.hasMore,
    this.nextCursor,
  });

  final List<WorkoutHistoryEntry> entries;
  final bool hasMore;
  final WorkoutHistoryCursor? nextCursor;
}
