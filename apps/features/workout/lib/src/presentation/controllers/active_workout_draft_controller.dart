import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/active_workout_draft.dart';
import '../../domain/models/routine_composition_limits.dart';
import '../../domain/models/routine_rest_timer_preset.dart';
import '../../domain/repositories/active_workout_draft_store.dart';
import '../library/exercises/exercises_controller.dart';

/// One durable device-local source of truth for a new Save-only workout.
/// It never calls the online W7B session repository before Save.
final class ActiveWorkoutDraftController extends ChangeNotifier {
  ActiveWorkoutDraftController({
    required ActiveWorkoutDraftStore store,
    required String ownerId,
    DateTime Function()? clock,
    String Function()? newUuid,
  })  : _store = store,
        _ownerId = ownerId,
        _clock = clock ?? DateTime.timestamp,
        _newUuid = newUuid ?? const Uuid().v4;

  final ActiveWorkoutDraftStore _store;
  final String _ownerId;
  final DateTime Function() _clock;
  final String Function() _newUuid;
  ActiveWorkoutDraft? _draft;
  bool _busy = false;
  bool _disposed = false;
  Object? _error;

  ActiveWorkoutDraft? get draft => _draft;
  bool get isBusy => _busy;
  Object? get error => _error;
  DateTime _nowUtc() => _clock().toUtc();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> restoreOrStart() async {
    if (_busy || _disposed) return false;
    _busy = true;
    _error = null;
    _notify();
    try {
      final restored = await _store.load();
      if (restored != null && restored.ownerId != _ownerId) {
        throw StateError('Workout draft belongs to another account.');
      }
      final candidate = restored ??
          ActiveWorkoutDraft(
            id: _newUuid(),
            ownerId: _ownerId,
            saveRequestId: _newUuid(),
            time: WorkoutTime.start(startedAtUtc: _nowUtc()),
          );
      if (restored == null) await _store.save(candidate);
      if (_disposed) return false;
      _draft = candidate;
      return true;
    } catch (error) {
      if (!_disposed) _error = error;
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<bool> _change(
    ActiveWorkoutDraft Function(ActiveWorkoutDraft draft) transform,
  ) async {
    final current = _draft;
    if (_busy || _disposed || current == null) return false;
    _busy = true;
    _error = null;
    _notify();
    try {
      final candidate =
          transform(current).copyWith(revision: current.revision + 1);
      await _store.save(candidate);
      if (_disposed) return false;
      _draft = candidate;
      return true;
    } catch (error) {
      if (!_disposed) _error = error;
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<bool> pause() =>
      _change((draft) => draft.copyWith(time: draft.time.pause(_nowUtc())));

  Future<bool> resume() =>
      _change((draft) => draft.copyWith(time: draft.time.resume(_nowUtc())));

  Future<bool> addExercises(List<Exercise> selected) => _change((draft) {
        if (selected.isEmpty) throw ArgumentError('No exercises selected.');
        final next = [...draft.exercises];
        for (final exercise in selected) {
          if (!RoutineCompositionLimits.supportsExerciseType(
              exercise.exerciseType)) {
            throw ArgumentError('Exercise execution type is unsupported.');
          }
          next.add(ActiveWorkoutDraftExercise(
            id: _newUuid(),
            exerciseRef: exercise.ref,
            displayName: exercise.displayName,
            exerciseType: exercise.exerciseType,
            thumbnailUrl: ExercisesController.thumbnailUrlFor(exercise),
            sets: [
              ActiveWorkoutDraftSet(
                id: _newUuid(),
                prescription: SetPrescription(),
              ),
            ],
          ));
        }
        return draft.copyWith(exercises: next);
      });

  Future<bool> removeExercise(String exerciseId) => _change((draft) {
        final next = draft.exercises.where((e) => e.id != exerciseId).toList();
        if (next.length == draft.exercises.length) {
          throw StateError('Exercise occurrence is missing.');
        }
        return draft.copyWith(
          exercises: next,
          activeRest: draft.activeRest?.exerciseId == exerciseId
              ? null
              : draft.activeRest,
        );
      });

  Future<bool> replaceExercise(String exerciseId, Exercise replacement) =>
      _change((draft) {
        if (!RoutineCompositionLimits.supportsExerciseType(
            replacement.exerciseType)) {
          throw ArgumentError('Exercise execution type is unsupported.');
        }
        final next = [...draft.exercises];
        final index = next.indexWhere((e) => e.id == exerciseId);
        if (index < 0) throw StateError('Exercise occurrence is missing.');
        next[index] = ActiveWorkoutDraftExercise(
          id: _newUuid(),
          exerciseRef: replacement.ref,
          displayName: replacement.displayName,
          exerciseType: replacement.exerciseType,
          thumbnailUrl: ExercisesController.thumbnailUrlFor(replacement),
          sets: [
            ActiveWorkoutDraftSet(
              id: _newUuid(),
              prescription: SetPrescription(),
            ),
          ],
        );
        return draft.copyWith(
          exercises: next,
          activeRest: draft.activeRest?.exerciseId == exerciseId
              ? null
              : draft.activeRest,
        );
      });

  Future<bool> addSet(String exerciseId) =>
      _editExercise(exerciseId, (exercise) {
        if (exercise.sets.length >=
            RoutineCompositionLimits.maxSetsPerExercise) {
          throw StateError('Set limit reached.');
        }
        return exercise.copyWith(sets: [
          ...exercise.sets,
          ActiveWorkoutDraftSet(
            id: _newUuid(),
            prescription: SetPrescription(),
          ),
        ]);
      });

  Future<bool> removeSet(String exerciseId, String setId) => _change((draft) {
        final next = [...draft.exercises];
        final index = next.indexWhere((e) => e.id == exerciseId);
        if (index < 0) throw StateError('Exercise occurrence is missing.');
        final remaining = next[index].sets.where((s) => s.id != setId).toList();
        if (remaining.length == next[index].sets.length) {
          throw StateError('Set is missing.');
        }
        next[index] = next[index].copyWith(sets: remaining);
        return draft.copyWith(
          exercises: next,
          activeRest:
              draft.activeRest?.setId == setId ? null : draft.activeRest,
        );
      });

  Future<bool> setType(String exerciseId, String setId, RoutineSetType type) =>
      _editSet(exerciseId, setId, (set) {
        final p = set.prescription;
        return set.copyWith(
          prescription: SetPrescription(
            reps: p.reps,
            repsMax: p.repsMax,
            setType: type,
            loadKg: p.loadKg,
            distanceMeters: p.distanceMeters,
            durationSeconds: p.durationSeconds,
            restSeconds: p.restSeconds,
          ),
        );
      });

  Future<bool> setRpe(String exerciseId, String setId, double? rpe) =>
      _editSet(exerciseId, setId, (set) => set.copyWith(rpe: rpe));

  Future<bool> setRestPreset(
    String exerciseId,
    RoutineRestTimerPreset preset,
  ) =>
      _editExercise(
        exerciseId,
        (exercise) => exercise.copyWith(
          restPreset: preset,
          hasRestOverride: true,
        ),
      );

  /// Keeps Save-screen edits local until the atomic backend submission is
  /// confirmed. Title resolution belongs to the Save command, not editing.
  Future<bool> updateSaveMetadata({
    required String? title,
    required String? description,
    required DateTime workoutAtUtc,
    required int workoutUtcOffsetMinutes,
    required int selectedDurationSeconds,
    required String? gymName,
    required String? activityType,
    required double? overallRpe,
  }) =>
      _change((draft) => draft.copyWith(
            workoutTitle: title,
            description: description,
            workoutAtUtc: workoutAtUtc,
            workoutUtcOffsetMinutes: workoutUtcOffsetMinutes,
            selectedDurationSeconds: selectedDurationSeconds,
            gymName: gymName,
            activityType: activityType,
            overallRpe: overallRpe,
          ));

  Future<bool> toggleLogged(
    String exerciseId,
    String setId, {
    int? reps,
    double? loadKg,
    int? durationSeconds,
    double? distanceMeters,
    bool isSkipped = false,
  }) =>
      _change((draft) {
        final next = [...draft.exercises];
        final exerciseIndex = next.indexWhere((e) => e.id == exerciseId);
        if (exerciseIndex < 0) {
          throw StateError('Exercise occurrence is missing.');
        }
        final exercise = next[exerciseIndex];
        final sets = [...exercise.sets];
        final setIndex = sets.indexWhere((set) => set.id == setId);
        if (setIndex < 0) throw StateError('Set is missing.');
        final set = sets[setIndex];
        ActiveWorkoutDraftRest? rest = draft.activeRest;
        if (set.loggedAtUtc != null) {
          sets[setIndex] = set.copyWith(
            reps: null,
            loadKg: null,
            durationSeconds: null,
            distanceMeters: null,
            loggedAtUtc: null,
            isSkipped: false,
          );
          if (rest?.setId == setId) rest = null;
        } else {
          sets[setIndex] = set.copyWith(
            reps: reps,
            loadKg: loadKg,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            loggedAtUtc: _nowUtc(),
            isSkipped: isSkipped,
          );
          final restSeconds = exercise.hasRestOverride
              ? exercise.restPreset.effectiveRestFor(set.prescription.setType)
              : set.prescription.restSeconds;
          rest = restSeconds == null || restSeconds <= 0
              ? null
              : ActiveWorkoutDraftRest(
                  targetAtUtc: _nowUtc().add(Duration(seconds: restSeconds)),
                  totalDurationSeconds: restSeconds,
                  exerciseId: exerciseId,
                  setId: setId,
                );
        }
        next[exerciseIndex] = exercise.copyWith(sets: sets);
        return draft.copyWith(exercises: next, activeRest: rest);
      });

  Future<bool> skipRest() =>
      _change((draft) => draft.copyWith(activeRest: null));

  Future<bool> adjustRest(int seconds) => _change((draft) {
        final rest = draft.activeRest;
        if (rest == null) throw StateError('No active rest timer.');
        final total = rest.totalDurationSeconds + seconds;
        if (total <= 0) return draft.copyWith(activeRest: null);
        return draft.copyWith(
          activeRest: ActiveWorkoutDraftRest(
            targetAtUtc: rest.targetAtUtc.add(Duration(seconds: seconds)),
            totalDurationSeconds: total,
            exerciseId: rest.exerciseId,
            setId: rest.setId,
          ),
        );
      });

  Future<bool> _editExercise(
    String exerciseId,
    ActiveWorkoutDraftExercise Function(ActiveWorkoutDraftExercise) edit,
  ) =>
      _change((draft) {
        final next = [...draft.exercises];
        final index = next.indexWhere((e) => e.id == exerciseId);
        if (index < 0) throw StateError('Exercise occurrence is missing.');
        next[index] = edit(next[index]);
        return draft.copyWith(exercises: next);
      });

  Future<bool> _editSet(
    String exerciseId,
    String setId,
    ActiveWorkoutDraftSet Function(ActiveWorkoutDraftSet) edit,
  ) =>
      _editExercise(exerciseId, (exercise) {
        final next = [...exercise.sets];
        final index = next.indexWhere((set) => set.id == setId);
        if (index < 0) throw StateError('Set is missing.');
        next[index] = edit(next[index]);
        return exercise.copyWith(sets: next);
      });

  Future<bool> discard() async {
    if (_busy || _disposed || _draft == null) return false;
    _busy = true;
    _error = null;
    _notify();
    try {
      await _store.delete();
      if (_disposed) return false;
      _draft = null;
      return true;
    } catch (error) {
      if (!_disposed) _error = error;
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _draft = null;
    super.dispose();
  }
}
