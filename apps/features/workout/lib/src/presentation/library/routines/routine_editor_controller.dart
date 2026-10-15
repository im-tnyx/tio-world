import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/models/routine_composition_limits.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/routine_repository.dart';

enum RoutineEditorStatus {
  loading,
  ready,
  notFound,
  loadFailed,
  verifying,
  saving,
  saved,
  revisionConflict,
  outcomeUnknown,
}

/// Feature-owned immutable view of a *draft*, never a second persisted truth.
final class RoutineEditorState {
  RoutineEditorState({
    required this.status,
    required List<RoutineCompositionEntry> entries,
    this.revision,
    this.dirty = false,
    this.message,
  }) : entries = List.unmodifiable(entries);

  final RoutineEditorStatus status;
  final List<RoutineCompositionEntry> entries;
  final int? revision;
  final bool dirty;
  final String? message;

  bool get canEdit => status == RoutineEditorStatus.ready;
}

/// Manages one Program-owned Routine draft without writing until Update.
///
/// This controller never bypasses the existing owner RLS + atomic RPC.
/// The future picker must supply only canonical catalog or *current-owner*
/// active Custom Exercise results; the RPC remains the authority for writes.
final class RoutineEditorController extends ChangeNotifier {
  RoutineEditorController({
    required this.program,
    required this.routine,
    required this.routines,
    required this.compositions,
    this.userExercises,
    this.canWrite,
    String Function()? newUuid,
  }) : _newUuid = newUuid ?? _uuidV4;

  final Program program;
  final Routine routine;
  final RoutineRepository routines;
  final RoutineCompositionRepository compositions;
  final UserExerciseRepository? userExercises;
  /// Live opening-session gate. Rechecked after async preflight and before RPC.
  final bool Function()? canWrite;
  final String Function() _newUuid;

  bool get _authorized {
    if (_disposed) return false;
    try {
      return canWrite?.call() ?? true;
    } catch (_) {
      return false;
    }
  }

  static String _uuidV4() => const Uuid().v4();

  RoutineEditorState _state = RoutineEditorState(
    status: RoutineEditorStatus.loading,
    entries: const [],
  );
  RoutineEditorState get state => _state;

  /// Historical rows remain readable/editable, but a full-snapshot Update
  /// must not submit more than the current eight-Set server policy.
  bool get exceedsSetLimit => _draft.any((entry) =>
      entry.sets.length > RoutineCompositionLimits.maxSetsPerExercise);

  List<RoutineCompositionEntry> _baseline = const [];
  List<RoutineCompositionEntry> _draft = const [];
  // Selected Custom definition per newly added/replaced entry. Historical
  // entries have no such snapshot: validate their stored target shape.
  final Map<String, ExerciseType?> _pickedCustomTypes = {};
  int _revision = 0;
  RoutineCompositionSave? _uncertainCommand;
  int _epoch = 0;
  bool _disposed = false;

  /// Reload discards an ordinary draft, but NEVER erases an unresolved write.
  Future<void> load() async {
    if (_disposed ||
        _state.status == RoutineEditorStatus.saving ||
        _state.status == RoutineEditorStatus.outcomeUnknown) {
      return;
    }
    final epoch = ++_epoch;
    _publish(RoutineEditorState(
      status: RoutineEditorStatus.loading,
      entries: const [],
    ));
    if (routine.programId != program.id) {
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.notFound,
        entries: const [],
      ));
      return;
    }

    try {
      final ownerRoutines = await routines.list(program.id);
      if (ownerRoutines.any((item) => item.programId != program.id) ||
          ownerRoutines.map((item) => item.id).toSet().length !=
              ownerRoutines.length) {
        throw const FormatException('Invalid owner Routine listing.');
      }
      if (_disposed || epoch != _epoch) return;
      if (!ownerRoutines.any((item) => item.id == routine.id)) {
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.notFound,
          entries: const [],
        ));
        return;
      }

      final current = await compositions.read(routine.id);
      if (_disposed || epoch != _epoch) return;
      if (current == null) {
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.notFound,
          entries: const [],
        ));
        return;
      }
      if (current.routineId != routine.id) {
        throw const FormatException('Composition identity mismatch.');
      }

      _baseline = current.entries;
      _draft = current.entries;
      _pickedCustomTypes.clear();
      _revision = current.revision;
      _uncertainCommand = null;
      _publish(_ready());
    } catch (_) {
      if (_disposed || epoch != _epoch) return;
      _baseline = const [];
      _draft = const [];
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.loadFailed,
        entries: const [],
        message: 'Could not load Routine for editing. Try again.',
      ));
    }
  }

  /// Adds an Exercise selected from the verified catalog/owner picker.
  /// Repeated canonical refs are distinct persisted entry identities.
  String? addPickedExercise(Exercise exercise) {
    if (!_state.canEdit || exercise.status != ExerciseStatus.active ||
        !RoutineCompositionLimits.supportsExerciseType(exercise.exerciseType)) {
      return null;
    }
    final id = _newUuid();
    if (exercise.ref is UserCreatedExerciseRef) {
      _pickedCustomTypes[id] = exercise.exerciseType;
    }
    final next = [..._draft, RoutineCompositionEntry(
      id: id,
      exercise: exercise.ref,
    )];
    _setDraft(next);
    return id;
  }

  /// Replacing a draft slot gets fresh Exercise/Set identities and blank
  /// targets; old persisted IDs are retired only by explicit Update.
  String? replacePickedExercise(String entryId, Exercise exercise) {
    if (!_state.canEdit || !_authorized ||
        exercise.status != ExerciseStatus.active ||
        !RoutineCompositionLimits.supportsExerciseType(exercise.exerciseType)) {
      return null;
    }
    final index = _draft.indexWhere((entry) => entry.id == entryId);
    if (index < 0 || _draft[index].exercise == exercise.ref) return null;
    final newId = _newUuid();
    final setId = _newUuid();
    _pickedCustomTypes.remove(entryId);
    if (exercise.ref is UserCreatedExerciseRef) {
      _pickedCustomTypes[newId] = exercise.exerciseType;
    }
    _replaceEntry(index, RoutineCompositionEntry(
      id: newId,
      exercise: exercise.ref,
      sets: [
        RoutineCompositionSet(
          id: setId,
          prescription: SetPrescription(),
        ),
      ],
    ));
    return newId;
  }

  bool removeExercise(String entryId) {
    if (!_state.canEdit || !_draft.any((e) => e.id == entryId)) return false;
    _setDraft(_draft.where((e) => e.id != entryId).toList());
    _pickedCustomTypes.remove(entryId);
    return true;
  }

  bool moveExercise(int from, int to) {
    if (!_state.canEdit ||
        from < 0 || to < 0 ||
        from >= _draft.length || to >= _draft.length ||
        from == to) {
      return false;
    }
    final next = [..._draft];
    next.insert(to, next.removeAt(from));
    _setDraft(next);
    return true;
  }

  String? addSet(String entryId, SetPrescription prescription) {
    if (!_state.canEdit) return null;
    final index = _draft.indexWhere((e) => e.id == entryId);
    if (index < 0) return null;
    final current = _draft[index];
    if (current.sets.length >= RoutineCompositionLimits.maxSetsPerExercise) {
      return null;
    }
    final id = _newUuid();
    final range = current.sets.isNotEmpty &&
        current.sets.first.prescription.isRepRange;
    // Existing-Routine Edit must not introduce a fixed Set into an Exercise
    // containing ranged Sets, which the canonical RPC correctly rejects.
    final initial = SetPrescription(
      reps: prescription.reps,
      repsMax: range ? prescription.reps : null,
      setType: RoutineSetType.normal,
      loadKg: prescription.loadKg,
      distanceMeters: prescription.distanceMeters,
      durationSeconds: prescription.durationSeconds,
      restSeconds: prescription.restSeconds,
    );
    _replaceEntry(index, RoutineCompositionEntry(
      id: current.id,
      exercise: current.exercise,
      sets: [
        ...current.sets,
        RoutineCompositionSet(id: id, prescription: initial),
      ],
    ));
    return id;
  }

  bool editSet(String entryId, String setId, SetPrescription prescription) {
    if (!_state.canEdit) return false;
    final index = _draft.indexWhere((e) => e.id == entryId);
    if (index < 0) return false;
    final entry = _draft[index];
    final setIndex = entry.sets.indexWhere((s) => s.id == setId);
    if (setIndex < 0) return false;
    final next = [...entry.sets];
    next[setIndex] = RoutineCompositionSet(
      id: setId,
      prescription: prescription,
    );
    _replaceEntry(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      sets: next,
    ));
    return true;
  }

  /// Repetition mode belongs to the Routine Exercise. Keep Set identity,
  /// type, kg and rest stable when switching Fixed ↔ Range.
  bool changeRepetitionMode(String entryId, {required bool range}) {
    if (!_state.canEdit) return false;
    final index = _draft.indexWhere((entry) => entry.id == entryId);
    if (index < 0) return false;
    final entry = _draft[index];
    if (entry.sets.isEmpty) return false;
    _replaceEntry(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      sets: [
        for (final set in entry.sets)
          RoutineCompositionSet(
            id: set.id,
            prescription: SetPrescription(
              reps: set.prescription.reps,
              repsMax: range
                  ? (set.prescription.repsMax ?? set.prescription.reps)
                  : null,
              setType: set.prescription.setType,
              loadKg: set.prescription.loadKg,
              distanceMeters: set.prescription.distanceMeters,
              durationSeconds: set.prescription.durationSeconds,
              restSeconds: set.prescription.restSeconds,
            ),
          ),
      ],
    ));
    return true;
  }

  bool removeSet(String entryId, String setId) {
    if (!_state.canEdit) return false;
    final index = _draft.indexWhere((e) => e.id == entryId);
    if (index < 0) return false;
    final entry = _draft[index];
    if (!entry.sets.any((s) => s.id == setId)) return false;
    _replaceEntry(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      sets: entry.sets.where((s) => s.id != setId).toList(),
    ));
    return true;
  }

  bool moveSet(String entryId, int from, int to) {
    if (!_state.canEdit) return false;
    final index = _draft.indexWhere((e) => e.id == entryId);
    if (index < 0) return false;
    final entry = _draft[index];
    if (from < 0 || to < 0 ||
        from >= entry.sets.length || to >= entry.sets.length ||
        from == to) {
      return false;
    }
    final reordered = [...entry.sets];
    reordered.insert(to, reordered.removeAt(from));
    _replaceEntry(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      sets: reordered,
    ));
    return true;
  }

  /// Return true only if no write was needed or the RPC confirmed it.
  /// Do not re-send an unknown mutation with a freshly generated token.
  Future<bool> update() async {
    if (!_state.canEdit || !_authorized) return false;
    if (exceedsSetLimit) {
      _publish(_ready(message: 'Reduce each Exercise to at most 8 Sets before Update.'));
      return false;
    }
    if (!_state.dirty) {
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.saved,
        entries: _draft,
        revision: _revision,
      ));
      return true;
    }
    // Revalidate Custom refs against the owner's current ACTIVE + ARCHIVED
    // definitions. This is still only a preflight; the #534 Save RPC locks
    // rows atomically against an archive racing after this read.
    final customRefs = _draft
        .map((entry) => entry.exercise)
        .whereType<UserCreatedExerciseRef>()
        .toSet();
    if (customRefs.isNotEmpty) {
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.verifying,
        entries: _draft,
        revision: _revision,
        dirty: true,
      ));
      final repository = userExercises;
      if (repository == null) {
        _publish(_ready(
          message: 'Custom Exercises cannot be verified. Try again.',
        ));
        return false;
      }
      List<Exercise> current;
      try {
        current = await repository
            .list(includeArchived: true)
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        if (_disposed) return false;
        _publish(_ready(
          message: 'Could not verify Custom Exercises. Try again.',
        ));
        return false;
      }
      if (!_authorized) return false;
      final currentByRef = <ExerciseRef, Exercise>{};
      for (final exercise in current) {
        if (exercise.ref is! UserCreatedExerciseRef ||
            (exercise.status != ExerciseStatus.active &&
                exercise.status != ExerciseStatus.archived) ||
            currentByRef.containsKey(exercise.ref)) {
          _publish(_ready(
            message: 'Could not verify Custom Exercises. Try again.',
          ));
          return false;
        }
        currentByRef[exercise.ref] = exercise;
      }
      for (final entry in _draft) {
        if (entry.exercise is! UserCreatedExerciseRef) continue;
        final live = currentByRef[entry.exercise];
        if (live == null) {
          _publish(_ready(
            message: 'A Custom Exercise is no longer available.',
          ));
          return false;
        }
        if (live.status == ExerciseStatus.archived) {
          // The DB permits only unchanged historical entry identity and
          // ordered Sets. Entry-level reordering/unrelated edits are fine.
          final unchanged = _baseline.any(
            (original) => original.id == entry.id && original == entry,
          );
          if (!unchanged) {
            _publish(_ready(
              message: 'An archived Custom Exercise cannot be changed. '
                  'Restore its original Sets or remove the Exercise.',
            ));
            return false;
          }
          continue;
        }
        if (!RoutineCompositionLimits.supportsExerciseType(
          live.exerciseType,
        )) {
          _publish(_ready(
            message: 'Steps & Duration Exercises cannot be saved to '
                'Routines yet.',
          ));
          return false;
        }
        if ((_pickedCustomTypes.containsKey(entry.id) &&
                _pickedCustomTypes[entry.id] != live.exerciseType) ||
            !RoutineCompositionLimits.targetsMatchExerciseType(
              live.exerciseType,
              entry.sets.map((set) => set.prescription),
            )) {
          _publish(_ready(
            message: 'A Custom Exercise type changed. '
                'Review or replace it before Update.',
          ));
          return false;
        }
      }
    }
    // Auth may change while Custom source preflight awaits. Route removal
    // runs on a Flutter frame, so disposal alone is not a write capability.
    if (!_authorized) return false;
    final command = RoutineCompositionSave(
      routineId: routine.id,
      expectedRevision: _revision,
      mutationId: _newUuid(),
      entries: _draft,
    );
    _publish(RoutineEditorState(
      status: RoutineEditorStatus.saving,
      entries: _draft,
      revision: _revision,
      dirty: true,
    ));
    try {
      final revision = await compositions.save(command);
      if (_disposed) return false;
      _revision = revision;
      _baseline = _draft;
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.saved,
        entries: _draft,
        revision: revision,
      ));
      return true;
    } on RoutineCompositionSaveOutcomeUnknown {
      if (_disposed) return false;
      _uncertainCommand = command;
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.outcomeUnknown,
        entries: _draft,
        revision: _revision,
        dirty: true,
        message: 'Could not confirm Update. Check saved data before editing again.',
      ));
      return false;
    } on RoutineCompositionException catch (error) {
      if (_disposed) return false;
      if (error.kind == RoutineCompositionFailureKind.revisionConflict ||
          error.kind == RoutineCompositionFailureKind.mutationConflict) {
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.revisionConflict,
          entries: _draft,
          revision: _revision,
          dirty: true,
          message: 'This Routine changed elsewhere. Reload before editing.',
        ));
      } else if (error.kind == RoutineCompositionFailureKind.unauthorized ||
          error.kind == RoutineCompositionFailureKind.forbidden ||
          error.kind == RoutineCompositionFailureKind.notFound) {
        _draft = const [];
        _baseline = const [];
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.notFound,
          entries: const [],
        ));
      } else if (error.kind ==
          RoutineCompositionFailureKind.exerciseUnavailable) {
        // The authoritative #534 RPC may observe an archive that raced
        // after our owner-scoped client preflight. Keep the editable draft.
        _publish(_ready(
          message: 'A Custom Exercise was archived or is unavailable. '
              'Review or remove it before Update.',
        ));
      } else {
        _publish(_ready(message: 'Could not update Routine. Try again.'));
      }
      return false;
    } catch (_) {
      if (_disposed) return false;
      // Unknown unexpected failures are not permission to retry automatically.
      _uncertainCommand = command;
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.outcomeUnknown,
        entries: _draft,
        revision: _revision,
        dirty: true,
        message: 'Could not confirm Update. Check saved data before editing again.',
      ));
      return false;
    }
  }

  /// Read-only reconciliation after an ambiguous RPC; does NOT issue a write.
  Future<bool> reconcileUnknown() async {
    final command = _uncertainCommand;
    if (_disposed ||
        command == null ||
        _state.status != RoutineEditorStatus.outcomeUnknown) {
      return false;
    }
    final epoch = _epoch;
    try {
      final current = await compositions.read(routine.id);
      if (_disposed ||
          epoch != _epoch ||
          _state.status != RoutineEditorStatus.outcomeUnknown) {
      return false;
    }
      if (current == null || current.routineId != routine.id) {
        _draft = const [];
        _baseline = const [];
        _uncertainCommand = null;
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.notFound,
          entries: const [],
        ));
        return false;
      }
      if (current.lastMutationId == command.mutationId) {
        if (!current.hasSameContent(command)) {
          _publish(RoutineEditorState(
            status: RoutineEditorStatus.revisionConflict,
            entries: _draft,
            revision: current.revision,
            dirty: true,
            message: 'Saved content differs. Reload before editing.',
          ));
          return false;
        }
        _revision = current.revision;
        _baseline = current.entries;
        _draft = current.entries;
        _uncertainCommand = null;
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.saved,
          entries: _draft,
          revision: _revision,
        ));
        return true;
      }
      if (current.revision > command.expectedRevision) {
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.revisionConflict,
          entries: _draft,
          revision: current.revision,
          dirty: true,
          message: 'This Routine changed elsewhere. Reload before editing.',
        ));
      }
      // At the original revision, the write is still uncertain; stay blocked.
    } catch (_) {
      // Keep the frozen token and draft; never guess whether the RPC committed.
    }
    return false;
  }

  void _replaceEntry(int index, RoutineCompositionEntry entry) {
    final next = [..._draft];
    next[index] = entry;
    _setDraft(next);
  }

  void _setDraft(List<RoutineCompositionEntry> next) {
    _draft = List.unmodifiable(next);
    _publish(_ready());
  }

  RoutineEditorState _ready({String? message}) => RoutineEditorState(
    status: RoutineEditorStatus.ready,
    entries: _draft,
    revision: _revision,
    dirty: !listEquals(_baseline, _draft),
    message: message,
  );

  void _publish(RoutineEditorState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
