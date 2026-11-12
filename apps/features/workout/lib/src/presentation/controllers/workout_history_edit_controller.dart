import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/active_workout_draft.dart';
import '../../domain/models/routine_composition_limits.dart';
import '../../domain/models/workout_history_entry.dart';

/// Ephemeral completed-workout edit state. No Active Workout draft is created.
final class WorkoutHistoryEditController extends ChangeNotifier {
  WorkoutHistoryEditController(this.source) {
    final snapshot = source.snapshot;
    if (snapshot == null ||
        source.revision == null ||
        source.rawSnapshot == null) {
      throw StateError('Completed workout cannot be edited from this read.');
    }
    final performed = <(int, int), PerformedSet>{
      for (final set in source.allPerformedSets)
        (set.sessionExerciseIndex, set.setIndex): set,
    };
    _exercises = [
      for (final exercise in snapshot.exercises)
        ActiveWorkoutDraftExercise(
          id: const Uuid().v4(),
          exerciseRef: exercise.exerciseRef,
          displayName: exercise.displayName,
          exerciseType: exercise.exerciseType,
          sets: [
            for (final (index, prescription) in exercise.prescribedSets.indexed)
              ActiveWorkoutDraftSet(
                id: performed[(exercise.occurrenceIndex, index)]?.id ??
                    const Uuid().v4(),
                prescription: prescription,
                reps: performed[(exercise.occurrenceIndex, index)]?.reps,
                loadKg: performed[(exercise.occurrenceIndex, index)]?.loadKg,
                durationSeconds: performed[(exercise.occurrenceIndex, index)]
                    ?.durationSeconds,
                distanceMeters: performed[(exercise.occurrenceIndex, index)]
                    ?.distanceMeters,
                loggedAtUtc: performed[(exercise.occurrenceIndex, index)]
                    ?.completedAtUtc,
                isSkipped: performed[(exercise.occurrenceIndex, index)]
                            ?.completedAtUtc !=
                        null &&
                    (performed[(exercise.occurrenceIndex, index)]?.isSkipped ??
                        false),
                rpe: (((source.rawSnapshot!['exercises']
                                as List)[exercise.occurrenceIndex]
                            ['prescribed_sets'] as List)[index]['performed_rpe']
                        as num?)
                    ?.toDouble(),
              ),
          ],
        ),
    ];
  }

  final WorkoutHistoryDetail source;
  late List<ActiveWorkoutDraftExercise> _exercises;
  List<ActiveWorkoutDraftExercise> get exercises =>
      List.unmodifiable(_exercises);

  int get completedSetCount => _exercises.fold(
      0,
      (count, exercise) =>
          count +
          exercise.sets
              .where((set) => set.loggedAtUtc != null && !set.isSkipped)
              .length);

  double get volumeKg {
    var sum = 0.0;
    for (final exercise in _exercises) {
      for (final set in exercise.sets) {
        if (set.loggedAtUtc != null &&
            !set.isSkipped &&
            set.reps != null &&
            set.loadKg != null) {
          sum += set.reps! * set.loadKg!;
        }
      }
    }
    return sum;
  }

  bool get hasMeasuredVolume =>
      _exercises.any((exercise) => exercise.sets.any((set) =>
          set.loggedAtUtc != null &&
          !set.isSkipped &&
          set.reps != null &&
          set.loadKg != null));

  bool get canUpdate =>
      _exercises.isNotEmpty &&
      _exercises.length <= 100 &&
      completedSetCount > 0 &&
      _exercises.every((exercise) =>
          exercise.sets.isNotEmpty &&
          exercise.sets.length <= RoutineCompositionLimits.maxSetsPerExercise &&
          exercise.sets
              .any((set) => set.loggedAtUtc != null && !set.isSkipped));

  void addExercises(List<Exercise> selected) {
    if (_exercises.length + selected.length > 100) {
      throw StateError('Exercise limit reached.');
    }
    final next = [..._exercises];
    for (final exercise in selected) {
      if (!RoutineCompositionLimits.supportsExerciseType(
          exercise.exerciseType)) {
        throw StateError('This exercise type cannot be logged.');
      }
      next.add(_newExercise(exercise));
    }
    _exercises = next;
    notifyListeners();
  }

  void replaceExercise(int index, Exercise replacement) {
    if (!RoutineCompositionLimits.supportsExerciseType(
        replacement.exerciseType)) {
      throw StateError('This exercise type cannot be logged.');
    }
    final next = [..._exercises];
    next[index] = _newExercise(replacement);
    _exercises = next;
    notifyListeners();
  }

  void removeExercise(int index) {
    final next = [..._exercises]..removeAt(index);
    _exercises = next;
    notifyListeners();
  }

  void addSet(int exerciseIndex) {
    final exercise = _exercises[exerciseIndex];
    if (exercise.sets.length >= RoutineCompositionLimits.maxSetsPerExercise) {
      throw StateError('Set limit reached.');
    }
    _replaceExercise(
        exerciseIndex,
        exercise.copyWith(sets: [
          ...exercise.sets,
          ActiveWorkoutDraftSet(
              id: const Uuid().v4(), prescription: SetPrescription()),
        ]));
  }

  void removeSet(int exerciseIndex, int setIndex) {
    final exercise = _exercises[exerciseIndex];
    final nextSets = [...exercise.sets]..removeAt(setIndex);
    if (nextSets.isEmpty) {
      removeExercise(exerciseIndex);
    } else {
      _replaceExercise(exerciseIndex, exercise.copyWith(sets: nextSets));
    }
  }

  void changePrescription(
      int exerciseIndex, int setIndex, SetPrescription value) {
    _replaceSet(exerciseIndex, setIndex,
        _exercises[exerciseIndex].sets[setIndex].copyWith(prescription: value));
  }

  void toggleLogged(
    int exerciseIndex,
    int setIndex, {
    int? reps,
    double? loadKg,
    int? durationSeconds,
    double? distanceMeters,
  }) {
    final set = _exercises[exerciseIndex].sets[setIndex];
    if (set.loggedAtUtc != null && !set.isSkipped) {
      _replaceSet(
          exerciseIndex,
          setIndex,
          set.copyWith(
            loggedAtUtc: null,
            reps: null,
            loadKg: null,
            durationSeconds: null,
            distanceMeters: null,
          ));
      return;
    }
    _replaceSet(
        exerciseIndex,
        setIndex,
        set.copyWith(
          loggedAtUtc: source.allPerformedSets
                  .where((old) => old.id == set.id)
                  .firstOrNull
                  ?.completedAtUtc ??
              source.summary.completedAtUtc,
          reps: reps,
          loadKg: loadKg,
          durationSeconds: durationSeconds,
          distanceMeters: distanceMeters,
          isSkipped: false,
        ));
  }

  void _replaceSet(
      int exerciseIndex, int setIndex, ActiveWorkoutDraftSet value) {
    final exercise = _exercises[exerciseIndex];
    final nextSets = [...exercise.sets]..[setIndex] = value;
    _replaceExercise(exerciseIndex, exercise.copyWith(sets: nextSets));
  }

  void _replaceExercise(int index, ActiveWorkoutDraftExercise value) {
    final next = [..._exercises]..[index] = value;
    _exercises = next;
    notifyListeners();
  }

  static ActiveWorkoutDraftExercise _newExercise(Exercise exercise) =>
      ActiveWorkoutDraftExercise(
        id: const Uuid().v4(),
        exerciseRef: exercise.ref,
        displayName: exercise.displayName,
        exerciseType: exercise.exerciseType,
        sets: [
          ActiveWorkoutDraftSet(
            id: const Uuid().v4(),
            prescription: SetPrescription(),
          )
        ],
      );
}
