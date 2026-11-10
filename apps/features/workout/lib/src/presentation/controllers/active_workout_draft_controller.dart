import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/active_workout_draft.dart';
import '../../domain/models/routine_composition_limits.dart';
import '../../domain/models/routine_rest_timer_preset.dart';
import '../../domain/models/workout_save_metadata_limits.dart';
import '../../domain/repositories/active_workout_draft_store.dart';
import '../../domain/repositories/workout_draft_save_repository.dart';
import '../library/exercises/exercises_controller.dart';

/// One durable device-local source of truth for a new Save-only workout.
/// It never calls the online W7B session repository before Save.
final class ActiveWorkoutDraftController extends ChangeNotifier {
  static const unattendedLimit = Duration(hours: 2);
  ActiveWorkoutDraftController({
    required ActiveWorkoutDraftStore store,
    required String ownerId,
    WorkoutDraftSaveRepository? saveRepository,
    DateTime Function()? clock,
    String Function()? newUuid,
  })  : _store = store,
        _ownerId = ownerId,
        _saveRepository = saveRepository,
        _clock = clock ?? DateTime.timestamp,
        _newUuid = newUuid ?? const Uuid().v4;

  final ActiveWorkoutDraftStore _store;
  final String _ownerId;
  final WorkoutDraftSaveRepository? _saveRepository;
  final DateTime Function() _clock;
  final String Function() _newUuid;
  ActiveWorkoutDraft? _draft;
  bool _busy = false;
  int _pendingMutations = 0;
  Future<void> _mutationTail = Future<void>.value();
  bool _disposed = false;
  Object? _error;
  /// Backgrounding that arrived while restore had not published a draft yet.
  DateTime? _pendingBackgroundedAtUtc;

  ActiveWorkoutDraft? get draft => _draft;
  bool get isBusy => _busy;
  Object? get error => _error;
  DateTime _nowUtc() => _clock().toUtc();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> restoreOrStart() async {
    await _mutationTail;
    return _restore(createIfMissing: true);
  }

  /// Reads an owner-bound draft without starting a new workout. This allows
  /// offline recovery before the online legacy-session lookup completes.
  Future<bool> restoreExisting() async {
    await _mutationTail;
    return _restore(createIfMissing: false);
  }

  Future<bool> _restore({required bool createIfMissing}) async {
    if (_busy || _disposed) return false;
    _busy = true;
    _error = null;
    _notify();
    try {
      // tio-workspace style: Play/start is memory-first. Local persist is
      // best-effort and must not block opening Log Workout.
      ActiveWorkoutDraft? restored;
      try {
        restored = await _store.load();
      } catch (error) {
        // Unreadable durable draft is unknown, not empty. Never publish a new
        // in-memory workout while an owner-bound slot may still exist.
        if (!_disposed) _error = error;
        return false;
      }
      if (restored != null && restored.ownerId != _ownerId) {
        throw StateError('Workout draft belongs to another account.');
      }
      if (restored == null && !createIfMissing) {
        // No draft to attach to; drop stale backgrounding so a later fresh
        // Play start cannot inherit an older pending marker.
        _pendingBackgroundedAtUtc = null;
        return true;
      }
      final startedAt = _nowUtc();
      var candidate = restored ??
          ActiveWorkoutDraft(
            id: _newUuid(),
            ownerId: _ownerId,
            saveRequestId: _newUuid(),
            time: WorkoutTime.start(startedAtUtc: startedAt),
            lastActivityAtUtc: startedAt,
          );
      final pendingBackground = _pendingBackgroundedAtUtc;
      _pendingBackgroundedAtUtc = null;
      // Only keep pending backgrounding that belongs to this workout window.
      final usablePending = pendingBackground != null &&
              !pendingBackground.isBefore(candidate.time.startedAtUtc)
          ? pendingBackground
          : null;
      final backgroundedAt = candidate.backgroundedAtUtc ?? usablePending;
      final lastActivity = candidate.lastActivityAtUtc ??
          candidate.exercises
              .expand((exercise) => exercise.sets)
              .map((set) => set.loggedAtUtc)
              .whereType<DateTime>()
              .fold<DateTime>(candidate.time.lastTransitionAtUtc,
                  (latest, logged) => logged.isAfter(latest) ? logged : latest);
      final unattendedSince = backgroundedAt ??
          (restored != null && _draft == null && !candidate.time.isPaused
              ? lastActivity
              : null);
      if (unattendedSince != null) {
        final now = _nowUtc();
        if (!now.isBefore(unattendedSince)) {
          final rawCutoff = unattendedSince.add(unattendedLimit);
          final cutoff = rawCutoff.isBefore(candidate.time.startedAtUtc)
              ? candidate.time.startedAtUtc
              : rawCutoff;
          final shouldPause = !now.isBefore(cutoff);
          if (backgroundedAt != null || shouldPause) {
            candidate = candidate.copyWith(
              time: shouldPause ? candidate.time.pause(cutoff) : candidate.time,
              backgroundedAtUtc: null,
              lastActivityAtUtc: shouldPause ? cutoff : now,
              revision: candidate.revision + 1,
            );
            // Preserve the old marker/activity time on failure for retry.
            await _store.save(candidate);
          }
        }
      }
      // Publish the in-memory draft before durable write so UI can open.
      if (_disposed) return false;
      _draft = candidate;
      _notify();
      if (restored == null) {
        try {
          await _store.save(candidate);
        } catch (_) {
          // Slot may already hold the candidate after an interrupted first
          // commit. Prefer recovering that durable row, then retry once.
          try {
            final recovered = await _store.load();
            if (recovered != null && recovered.ownerId == _ownerId) {
              if (_disposed) return false;
              _draft = recovered;
              return true;
            }
          } catch (_) {}
          try {
            await _store.save(candidate);
          } catch (error) {
            // Keep the in-memory workout alive; durable retry happens on the
            // next mutation. Do not fail Play/start for a persist hiccup.
            if (!_disposed) _error = error;
          }
        }
      }
      return !_disposed;
    } catch (error) {
      if (!_disposed) _error = error;
      return _draft != null && !_disposed;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<bool> _change(
    ActiveWorkoutDraft Function(ActiveWorkoutDraft draft) transform,
  ) {
    if (_disposed || (_busy && _pendingMutations == 0)) {
      return Future<bool>.value(false);
    }
    final result = Completer<bool>();
    _pendingMutations++;
    _busy = true;
    _notify();
    _mutationTail = _mutationTail.then((_) async {
      try {
        final current = _draft;
        if (_disposed || current == null || current.submittedAtUtc != null) {
          result.complete(false);
          return;
        }
        _error = null;
        final transformed = transform(current);
        final now = _nowUtc();
        final previous =
            current.lastActivityAtUtc ?? current.time.lastTransitionAtUtc;
        final lastActivity = [
          now,
          previous,
          transformed.time.lastTransitionAtUtc
        ].reduce((a, b) => a.isAfter(b) ? a : b);
        final candidate = transformed.copyWith(
          revision: current.revision + 1,
          lastActivityAtUtc: lastActivity,
        );
        await _store.save(candidate);
        if (!_disposed) _draft = candidate;
        result.complete(!_disposed);
      } catch (error) {
        // Ambiguous local commits may have advanced the durable revision.
        // Reconcile from storage before surfacing failure.
        try {
          final recovered = await _store.load();
          if (!_disposed &&
              recovered != null &&
              recovered.ownerId == _ownerId) {
            _draft = recovered;
          }
        } catch (_) {}
        if (!_disposed) _error = error;
        result.complete(false);
      } finally {
        _pendingMutations--;
        _busy = _pendingMutations > 0;
        _notify();
      }
    });
    return result.future;
  }

  Future<bool> pause() => _change((draft) => draft.copyWith(
        time: draft.time.pause(_nowUtc()),
        backgroundedAtUtc: null,
      ));

  /// Record an unattended interval before the process can be suspended.
  Future<bool> markBackgrounded() {
    final draft = _draft;
    if (draft == null) {
      // Restore may still be publishing; remember backgrounding so the later
      // unattended pause still applies after the in-memory draft appears.
      _pendingBackgroundedAtUtc ??= _nowUtc();
      return Future<bool>.value(true);
    }
    if (draft.time.isPaused || draft.backgroundedAtUtc != null) {
      return Future<bool>.value(true);
    }
    return _change((current) => current.copyWith(
          backgroundedAtUtc: current.backgroundedAtUtc ?? _nowUtc(),
        ));
  }

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
        // Save snapshot validation requires 1–8 sets per exercise. Removing the
        // last set drops the empty exercise instead of leaving prescribed_sets:[].
        if (remaining.isEmpty) {
          next.removeAt(index);
        } else {
          next[index] = next[index].copyWith(sets: remaining);
        }
        return draft.copyWith(
          exercises: next,
          // Only clear rest when the resting set itself was removed. Dropping a
          // different set on the same exercise must keep an active countdown.
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
    required int? selectedDurationSeconds,
    required String? gymName,
    required String? activityType,
    required double? overallRpe,
  }) {
    final current = _draft;
    if (current?.submittedAtUtc != null) {
      return Future<bool>.value(
        current!.workoutTitle == title &&
            current.description == description &&
            current.workoutAtUtc == workoutAtUtc &&
            current.workoutUtcOffsetMinutes == workoutUtcOffsetMinutes &&
            current.selectedDurationSeconds == selectedDurationSeconds &&
            current.gymName == gymName &&
            current.activityType == activityType &&
            current.overallRpe == overallRpe,
      );
    }
    if (!_isValidSaveMetadata(
      title: title,
      description: description,
      gymName: gymName,
      activityType: activityType,
      requireNonEmptyTitle: false,
    )) {
      return Future<bool>.value(false);
    }
    return _change((draft) => draft.copyWith(
          workoutTitle: title,
          description: description,
          workoutAtUtc: workoutAtUtc,
          workoutUtcOffsetMinutes: workoutUtcOffsetMinutes,
          selectedDurationSeconds: selectedDurationSeconds,
          gymName: gymName,
          activityType: activityType,
          overallRpe: overallRpe,
        ));
  }

  /// Returns true only after the canonical completed row and all performed
  /// sets have been read back and the local draft is logically discarded.
  Future<bool> save({required String resolvedTitle}) {
    final repository = _saveRepository;
    if (repository == null ||
        _disposed ||
        _draft == null ||
        (_busy && _pendingMutations == 0)) {
      return Future<bool>.value(false);
    }
    final result = Completer<bool>();
    _pendingMutations++;
    _busy = true;
    _notify();
    _mutationTail = _mutationTail.then((_) async {
      try {
        var current = _draft;
        if (_disposed || current == null) {
          result.complete(false);
          return;
        }
        if (current.submittedAtUtc == null) {
          // Validate before freeze so an oversize title/description cannot
          // lock the draft into an uneditable rejected submission.
          if (!_isValidSaveMetadata(
            title: resolvedTitle,
            description: current.description,
            gymName: current.gymName,
            activityType: current.activityType,
            requireNonEmptyTitle: true,
          )) {
            result.complete(false);
            return;
          }
          final frozen = current.copyWith(
            submittedAtUtc: _nowUtc(),
            submittedTitle: resolvedTitle,
            revision: current.revision + 1,
          );
          await _store.save(frozen);
          if (_disposed) {
            result.complete(false);
            return;
          }
          _draft = frozen;
          current = frozen;
        } else if (current.submittedTitle != resolvedTitle) {
          result.complete(false);
          return;
        }
        final submitted = current;
        await repository.saveDraft(submitted);
        if (_disposed || !identical(_draft, submitted)) {
          result.complete(false);
          return;
        }
        await _store.delete();
        if (_disposed) {
          result.complete(false);
          return;
        }
        _draft = null;
        _error = null;
        result.complete(true);
      } catch (error) {
        try {
          final recovered = await _store.load();
          if (!_disposed &&
              recovered != null &&
              recovered.ownerId == _ownerId) {
            _draft = recovered;
          }
        } catch (_) {}
        if (!_disposed) _error = error;
        result.complete(false);
      } finally {
        _pendingMutations--;
        _busy = _pendingMutations > 0;
        _notify();
      }
    });
    return result.future;
  }

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

  bool _isValidSaveMetadata({
    required String? title,
    required String? description,
    required String? gymName,
    required String? activityType,
    required bool requireNonEmptyTitle,
  }) {
    final trimmedTitle = title?.trim() ?? '';
    if (requireNonEmptyTitle) {
      if (!WorkoutSaveMetadataLimits.isValidTitle(title)) return false;
    } else if (trimmedTitle.length >
        WorkoutSaveMetadataLimits.maxTitleLength) {
      return false;
    }
    return WorkoutSaveMetadataLimits.isValidDescription(description) &&
        WorkoutSaveMetadataLimits.isValidGymName(gymName) &&
        WorkoutSaveMetadataLimits.isValidActivityType(activityType);
  }

  Future<bool> discard() async {
    if (_busy ||
        _disposed ||
        _draft == null ||
        _draft!.submittedAtUtc != null) {
      return false;
    }
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

  /// Permanently clears any local draft so Play can start a replacement workout.
  /// Unlike [discard], this also clears a frozen/submitted draft and an empty
  /// memory slot that still has durable store state.
  ///
  /// Waits for in-flight mutations first so a late `save()` cannot resurrect
  /// the draft after the durable slot is deleted.
  Future<bool> discardForReplacement() async {
    if (_disposed) return false;
    await _mutationTail;
    if (_busy || _disposed) return false;
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
