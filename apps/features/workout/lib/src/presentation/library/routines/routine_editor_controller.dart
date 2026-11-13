import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/models/routine_composition_limits.dart';
import '../../../domain/models/routine_rest_timer_preset.dart';
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

RoutineCompositionEntry _editorEntryWithSuperset(
  RoutineCompositionEntry entry,
  String? supersetId,
) =>
    RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      supersetId: supersetId,
      sets: entry.sets,
    );

/// Feature-owned immutable view of a *draft*, never a second persisted truth.
final class RoutineEditorState {
  RoutineEditorState({
    required this.status,
    required List<RoutineCompositionEntry> entries,
    List<RoutineSupersetGroup> supersets = const [],
    this.revision,
    this.name = '',
    this.dirty = false,
    this.message,
  })  : entries = List.unmodifiable(entries),
        supersets = List.unmodifiable(supersets);

  final RoutineEditorStatus status;
  final List<RoutineCompositionEntry> entries;
  final List<RoutineSupersetGroup> supersets;
  final int? revision;
  final String name;
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

  /// Name-only updates never rewrite or validate historical Set rows.
  bool get updateExceedsSetLimit => _compositionDirty && exceedsSetLimit;

  /// Whether any Exercise in the draft currently violates the Warm-up ordering invariant.
  bool get hasInvalidSetOrder => _draft.any(
      (entry) => !RoutineCompositionLimits.hasValidSetOrder(
            entry.sets.map((s) => s.prescription),
          ));

  /// Name-only updates never rewrite or validate historical Set rows.
  bool get updateHasInvalidSetOrder => _compositionDirty && hasInvalidSetOrder;

  List<RoutineCompositionEntry> _baseline = const [];
  List<RoutineCompositionEntry> _draft = const [];
  List<RoutineSupersetGroup> _baselineSupersets = const [];
  List<RoutineSupersetGroup> _draftSupersets = const [];
  String _baselineName = '';
  String _draftName = '';
  // Selected Custom definition per newly added/replaced entry. Historical
  // entries have no such snapshot: validate their stored target shape.
  final Map<String, ExerciseType?> _pickedCustomTypes = {};
  final Map<String, RoutineRestTimerPreset> _restPresets = {};
  int _revision = 0;
  RoutineCompositionSave? _uncertainCommand;
  RoutineAggregateUpdate? _uncertainAggregateCommand;
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

      // The authenticated adapter brackets this Name with the aggregate
      // revision. Historical test mocks can fall back to the owner listing.
      final ownerRoutine = ownerRoutines.singleWhere((item) => item.id == routine.id);
      _baselineName = current.name ?? ownerRoutine.name;
      _draftName = _baselineName;
      _baseline = current.entries;
      _draft = current.entries;
      _baselineSupersets = current.supersets;
      _draftSupersets = current.supersets;
      _pickedCustomTypes.clear();
      _restPresets.clear();
      for (final entry in current.entries) {
        final prescriptions = entry.sets.map((s) => s.prescription).toList();
        final preset = RoutineRestTimerPreset.fromPrescriptions(prescriptions);
        final allRestOff = prescriptions.every(
          (prescription) =>
              prescription.restSeconds == null ||
              prescription.restSeconds! <= 0,
        );
        if (!preset.isOff || allRestOff) {
          _restPresets[entry.id] = preset;
        }
      }
      _revision = current.revision;
      _uncertainCommand = null;
      _uncertainAggregateCommand = null;
      _publish(_ready());
    } catch (_) {
      if (_disposed || epoch != _epoch) return;
      _baseline = const [];
      _draft = const [];
      _baselineSupersets = const [];
      _draftSupersets = const [];
      _baselineName = '';
      _draftName = '';
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.loadFailed,
        entries: const [],
        message: 'Could not load Routine for editing. Try again.',
      ));
    }
  }

  /// Adds an Exercise selected from the verified catalog/owner picker.
  /// Repeated canonical refs are distinct persisted entry identities.
  String? addPickedExercise(
    Exercise exercise, {
    RoutineRestTimerPreset initialRestPreset = const RoutineRestTimerPreset(),
  }) {
    if (!_state.canEdit || exercise.status != ExerciseStatus.active ||
        !RoutineCompositionLimits.supportsExerciseType(exercise.exerciseType)) {
      return null;
    }
    final id = _newUuid();
    _restPresets[id] = initialRestPreset;
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
    _restPresets.remove(entryId);
    if (exercise.ref is UserCreatedExerciseRef) {
      _pickedCustomTypes[newId] = exercise.exerciseType;
    }
    _replaceEntry(index, RoutineCompositionEntry(
      id: newId,
      exercise: exercise.ref,
      supersetId: _draft[index].supersetId,
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
    if (!_state.canEdit) return false;
    final removed = _draft.where((e) => e.id == entryId).firstOrNull;
    if (removed == null) return false;
    _setDraft(_draft.where((e) => e.id != entryId).toList());
    if (removed.supersetId != null) {
      final remaining = _draft
          .where((entry) => entry.supersetId == removed.supersetId)
          .toList();
      if (remaining.length < 2) {
        _draft = List.unmodifiable([
          for (final entry in _draft)
            if (entry.supersetId == removed.supersetId)
              _editorEntryWithSuperset(entry, null)
            else
              entry,
        ]);
        _draftSupersets = _draftSupersets
            .where((group) => group.id != removed.supersetId)
            .toList();
        _publish(_ready());
      }
    }
    _pickedCustomTypes.remove(entryId);
    _restPresets.remove(entryId);
    return true;
  }

  bool moveExercise(int from, int to) {
    if (!_state.canEdit ||
        from < 0 || to < 0 ||
        from >= _draft.length || to >= _draft.length ||
        from == to) {
      return false;
    }
    final moving = _draft[from];
    final movingGroup = moving.supersetId;
    final sourceIndexes = movingGroup == null
        ? [from]
        : [
            for (var i = 0; i < _draft.length; i++)
              if (_draft[i].supersetId == movingGroup) i,
          ];
    final sourceStart = sourceIndexes.first;
    final sourceEnd = sourceIndexes.last + 1;
    if (to >= sourceStart && to < sourceEnd) {
      if (to > from) {
        if (sourceEnd >= _draft.length) return false;
        to = sourceEnd;
      } else {
        if (sourceStart == 0) return false;
        to = sourceStart - 1;
      }
    }
    final block = _draft.sublist(sourceStart, sourceEnd);
    final next = [..._draft]..removeRange(sourceStart, sourceEnd);
    var target = to > sourceStart ? to - block.length + 1 : to;
    target = target.clamp(0, next.length);
    if (target < next.length && next[target].supersetId != null) {
      final targetGroup = next[target].supersetId;
      final first = next.indexWhere((e) => e.supersetId == targetGroup);
      final last = next.lastIndexWhere((e) => e.supersetId == targetGroup) + 1;
      target = from < to ? last : first;
    }
    next.insertAll(target, block);
    _setDraft(next);
    return true;
  }

  bool createSuperset(String initiatingEntryId, String memberEntryId) {
    if (!_state.canEdit || initiatingEntryId == memberEntryId) return false;
    final first = _draft.indexWhere((e) => e.id == initiatingEntryId);
    final second = _draft.indexWhere((e) => e.id == memberEntryId);
    if (first < 0 || second < 0 ||
        _draft[first].supersetId != null ||
        _draft[second].supersetId != null) return false;
    final id = _newUuid();
    final ordered = [first, second]..sort();
    final members = [
      _editorEntryWithSuperset(_draft[ordered[0]], id),
      _editorEntryWithSuperset(_draft[ordered[1]], id),
    ];
    final next = [..._draft]..removeAt(ordered[1])..removeAt(ordered[0]);
    next.insertAll(ordered[0], members);
    _draftSupersets = [
      ..._draftSupersets,
      RoutineSupersetGroup(
        id: id,
        restPreset: getExerciseRestPreset(initiatingEntryId),
      ),
    ];
    _setDraft(next);
    return true;
  }

  bool addSupersetMember(String groupId, String entryId) {
    if (!_state.canEdit ||
        !_draftSupersets.any((group) => group.id == groupId) ||
        _draft.where((entry) => entry.supersetId == groupId).length >= 3) {
      return false;
    }
    final index = _draft.indexWhere((entry) => entry.id == entryId);
    if (index < 0 || _draft[index].supersetId != null) return false;
    final next = [..._draft]..removeAt(index);
    final last = next.lastIndexWhere((entry) => entry.supersetId == groupId);
    next.insert(last + 1, _editorEntryWithSuperset(_draft[index], groupId));
    _setDraft(next);
    return true;
  }

  bool removeFromSuperset(String entryId) {
    if (!_state.canEdit) return false;
    final index = _draft.indexWhere((entry) => entry.id == entryId);
    if (index < 0) return false;
    final groupId = _draft[index].supersetId;
    if (groupId == null) return false;
    final members = _draft.where((entry) => entry.supersetId == groupId).length;
    if (members <= 2) {
      _draft = List.unmodifiable([
        for (final entry in _draft)
          if (entry.supersetId == groupId)
            _editorEntryWithSuperset(entry, null)
          else
            entry,
      ]);
      _draftSupersets = _draftSupersets.where((group) => group.id != groupId).toList();
      _publish(_ready());
    } else {
      final next = [..._draft]..[index] = _editorEntryWithSuperset(_draft[index], null);
      _setDraft(next);
    }
    return true;
  }

  RoutineSupersetGroup? supersetForEntry(String entryId) {
    final entry = _draft.where((item) => item.id == entryId).firstOrNull;
    final groupId = entry?.supersetId;
    if (groupId == null) return null;
    return _draftSupersets.where((group) => group.id == groupId).firstOrNull;
  }

  bool configureSupersetRestTimer(
    String groupId, {
    required int? normalRestSeconds,
    required int? warmUpRestSeconds,
  }) {
    if (!_state.canEdit) return false;
    final index = _draftSupersets.indexWhere((group) => group.id == groupId);
    if (index < 0) return false;
    final next = [..._draftSupersets];
    next[index] = RoutineSupersetGroup(
      id: groupId,
      restPreset: RoutineRestTimerPreset(
        normalRestSeconds: normalRestSeconds,
        warmUpRestSeconds: warmUpRestSeconds,
      ),
    );
    _draftSupersets = next;
    _publish(_ready());
    return true;
  }

  RoutineRestTimerPreset getExerciseRestPreset(String entryId) {
    final group = supersetForEntry(entryId);
    if (group != null) return group.restPreset;
    return _restPresets[entryId] ?? const RoutineRestTimerPreset();
  }

  bool configureExerciseRestTimer(
    String entryId, {
    required int? normalRestSeconds,
    required int? warmUpRestSeconds,
  }) {
    if (!_state.canEdit) return false;
    final index = _draft.indexWhere((e) => e.id == entryId);
    if (index < 0) return false;
    final entry = _draft[index];
    if (entry.supersetId != null) {
      return configureSupersetRestTimer(
        entry.supersetId!,
        normalRestSeconds: normalRestSeconds,
        warmUpRestSeconds: warmUpRestSeconds,
      );
    }
    final preset = RoutineRestTimerPreset(
      normalRestSeconds: normalRestSeconds,
      warmUpRestSeconds: warmUpRestSeconds,
    );
    _restPresets[entryId] = preset;

    final updatedSets = [
      for (final s in entry.sets)
        RoutineCompositionSet(
          id: s.id,
          prescription: SetPrescription(
            reps: s.prescription.reps,
            repsMax: s.prescription.repsMax,
            setType: s.prescription.setType,
            loadKg: s.prescription.loadKg,
            distanceMeters: s.prescription.distanceMeters,
            durationSeconds: s.prescription.durationSeconds,
            restSeconds: _restPresets.containsKey(entry.id)
                ? preset.effectiveRestFor(s.prescription.setType)
                : s.prescription.restSeconds,
          ),
        ),
    ];

    _replaceEntry(
      index,
      RoutineCompositionEntry(
        id: entry.id,
        exercise: entry.exercise,
        supersetId: entry.supersetId,
        sets: updatedSets,
      ),
    );
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
    final preset = _restPresets[current.id] ?? const RoutineRestTimerPreset();
    final effectiveRest =
        _restPresets.containsKey(entryId) || !preset.isOff
            ? preset.effectiveRestFor(prescription.setType)
            : prescription.restSeconds;
    final initial = SetPrescription(
      reps: prescription.reps,
      repsMax: range ? (prescription.repsMax ?? prescription.reps) : null,
      setType: prescription.setType,
      loadKg: prescription.loadKg,
      distanceMeters: prescription.distanceMeters,
      durationSeconds: prescription.durationSeconds,
      restSeconds: effectiveRest,
    );
    final newSet = RoutineCompositionSet(id: id, prescription: initial);
    final nextSets = [...current.sets];
    if (initial.setType == RoutineSetType.warmUp) {
      final lastWarmUp = nextSets.lastIndexWhere(
        (s) => s.prescription.setType == RoutineSetType.warmUp,
      );
      final insertIndex = lastWarmUp == -1 ? 0 : lastWarmUp + 1;
      nextSets.insert(insertIndex, newSet);
    } else {
      nextSets.add(newSet);
    }
    _replaceEntry(index, RoutineCompositionEntry(
      id: current.id,
      exercise: current.exercise,
      supersetId: current.supersetId,
      sets: nextSets,
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
    final current = entry.sets[setIndex];

    final updated = RoutineCompositionSet(
      id: setId,
      prescription: prescription,
    );

    final wasWarmUp = current.prescription.setType == RoutineSetType.warmUp;
    final isWarmUp = prescription.setType == RoutineSetType.warmUp;

    final nextSets = [...entry.sets];
    if (wasWarmUp == isWarmUp) {
      nextSets[setIndex] = updated;
    } else {
      nextSets.removeAt(setIndex);
      final lastWarmUp = nextSets.lastIndexWhere(
        (s) => s.prescription.setType == RoutineSetType.warmUp,
      );
      final insertIndex = lastWarmUp == -1 ? 0 : lastWarmUp + 1;
      nextSets.insert(insertIndex, updated);
    }

    _replaceEntry(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      supersetId: entry.supersetId,
      sets: nextSets,
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
      supersetId: entry.supersetId,
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
      supersetId: entry.supersetId,
      sets: entry.sets.where((s) => s.id != setId).toList(),
    ));
    return true;
  }

  /// Classification belongs to an identified Set; preserves target values and
  /// maintains the Warm-up ordering invariant (all Warm-up sets must precede
  /// non-Warm-up sets).
  bool changeSetType(String entryId, String setId, RoutineSetType type) {
    if (!_state.canEdit) return false;
    final index = _draft.indexWhere((entry) => entry.id == entryId);
    if (index < 0) return false;
    final entry = _draft[index];
    final currentSetIndex = entry.sets.indexWhere((set) => set.id == setId);
    if (currentSetIndex < 0) return false;
    final current = entry.sets[currentSetIndex];
    final p = current.prescription;
    if (p.setType == type) return true;

    final preset = _restPresets[entryId] ?? const RoutineRestTimerPreset();
    final int? newRestSeconds;
    if (_restPresets.containsKey(entryId) || !preset.isOff) {
      newRestSeconds = preset.effectiveRestFor(type);
    } else {
      newRestSeconds = p.restSeconds;
    }

    return editSet(
      entryId,
      setId,
      SetPrescription(
        reps: p.reps,
        repsMax: p.repsMax,
        setType: type,
        loadKg: p.loadKg,
        distanceMeters: p.distanceMeters,
        durationSeconds: p.durationSeconds,
        restSeconds: newRestSeconds,
      ),
    );
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
    if (!RoutineCompositionLimits.hasValidSetOrder(
      reordered.map((s) => s.prescription),
    )) {
      return false;
    }
    _replaceEntry(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      supersetId: entry.supersetId,
      sets: reordered,
    ));
    return true;
  }

  /// Saved Routine Name lives in the same controller draft as its Sets.
  void rename(String value) {
    if (!_state.canEdit) return;
    _draftName = value;
    _publish(_ready());
  }

  bool get compositionDirty =>
      !listEquals(_baseline, _draft) ||
      !listEquals(_baselineSupersets, _draftSupersets);
  bool get _compositionDirty => compositionDirty;
  bool get _nameDirty => _draftName.trim() != _baselineName;

  /// Return true only if no write was needed or the RPC confirmed it.
  /// Do not re-send an unknown mutation with a freshly generated token.
  Future<bool> update() async {
    if (!_state.canEdit || !_authorized) return false;
    if (_draftName.trim().isEmpty) {
      _publish(_ready(message: 'Enter a Routine name before Update.'));
      return false;
    }
    if (_compositionDirty && exceedsSetLimit) {
      _publish(_ready(message: 'Reduce each Exercise to at most 8 Sets before Update.'));
      return false;
    }
    if (_compositionDirty && hasInvalidSetOrder) {
      _publish(_ready(
        message: 'Warm-up sets must appear at the beginning of each Exercise.',
      ));
      return false;
    }
    if (!_state.dirty) {
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.saved,
        entries: _draft,
        supersets: _draftSupersets,
        revision: _revision,
      ));
      return true;
    }
    // Revalidate Custom refs against the owner's current ACTIVE + ARCHIVED
    // definitions. This is still only a preflight; the #534 Save RPC locks
    // rows atomically against an archive racing after this read.
    final customRefs = (_compositionDirty ? _draft : const <RoutineCompositionEntry>[])
        .map((entry) => entry.exercise)
        .whereType<UserCreatedExerciseRef>()
        .toSet();
    final expectedCustomTypes = <String, ExerciseType?>{};
    if (customRefs.isNotEmpty) {
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.verifying,
        entries: _draft,
        supersets: _draftSupersets,
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
        expectedCustomTypes[entry.id] = live.exerciseType;
      }
    }
    // Auth may change while Custom source preflight awaits. Route removal
    // runs on a Flutter frame, so disposal alone is not a write capability.
    if (!_authorized) return false;
    final compositionDirty = _compositionDirty;
    if (compositionDirty) {
      for (final entry in _draft) {
        if (!RoutineCompositionLimits.hasValidSetOrder(
          entry.sets.map((s) => s.prescription),
        )) {
          _publish(_ready(
            message: 'Warm-up sets must appear at the beginning of each Exercise.',
          ));
          return false;
        }
      }
    }
    final nameDirty = _nameDirty;
    final mutationId = _newUuid();
    final command = nameDirty
        ? RoutineAggregateUpdate(
            routineId: routine.id,
            programId: program.id,
            expectedRevision: _revision,
            expectedName: _baselineName,
            mutationId: mutationId,
            name: _draftName.trim(),
            entries: compositionDirty ? _draft : null,
            supersets: compositionDirty ? _draftSupersets : const [],
            expectedCustomTypes: expectedCustomTypes,
          )
        : null;
    final compositionCommand = nameDirty
        ? null
        : RoutineCompositionSave(
            routineId: routine.id,
            expectedRevision: _revision,
            mutationId: mutationId,
            entries: _draft,
            supersets: _draftSupersets,
            expectedCustomTypes: expectedCustomTypes,
          );
    _publish(RoutineEditorState(
      status: RoutineEditorStatus.saving,
      entries: _draft,
      supersets: _draftSupersets,
      revision: _revision,
      dirty: true,
    ));
    try {
      final revision = command == null
          ? await compositions.save(compositionCommand!)
          : await (() async {
              final adapter = compositions;
              if (adapter is! RoutineAggregateUpdateRepository) {
                throw const RoutineCompositionException(
                    RoutineCompositionFailureKind.unavailable);
              }
              return (adapter as RoutineAggregateUpdateRepository).updateAggregate(command);
            })();
      if (_disposed || !_authorized) return false;
      _revision = revision;
      _baseline = _draft;
      _baselineSupersets = _draftSupersets;
      _baselineName = _draftName.trim();
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.saved,
        entries: _draft,
        supersets: _draftSupersets,
        revision: revision,
      ));
      return true;
    } on RoutineCompositionSaveOutcomeUnknown {
      if (_disposed) return false;
      _uncertainCommand = compositionCommand;
      _uncertainAggregateCommand = command;
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.outcomeUnknown,
        entries: _draft,
        supersets: _draftSupersets,
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
          supersets: _draftSupersets,
          revision: _revision,
          dirty: true,
          message: 'This Routine changed elsewhere. Reload before editing.',
        ));
      } else if (error.kind == RoutineCompositionFailureKind.unauthorized ||
          error.kind == RoutineCompositionFailureKind.forbidden ||
          error.kind == RoutineCompositionFailureKind.notFound) {
        _draft = const [];
        _baseline = const [];
        _draftSupersets = const [];
        _baselineSupersets = const [];
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
      _uncertainCommand = compositionCommand;
      _uncertainAggregateCommand = command;
      _publish(RoutineEditorState(
        status: RoutineEditorStatus.outcomeUnknown,
        entries: _draft,
        supersets: _draftSupersets,
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
    final aggregate = _uncertainAggregateCommand;
    if (_disposed ||
        (command == null && aggregate == null) ||
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
        _draftSupersets = const [];
        _baselineSupersets = const [];
        _uncertainCommand = null;
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.notFound,
          entries: const [],
        ));
        return false;
      }
      final mutationId = aggregate?.mutationId ?? command!.mutationId;
      final expectedRevision = aggregate?.expectedRevision ?? command!.expectedRevision;
      if (current.lastMutationId == mutationId) {
        final matches = aggregate != null
            ? aggregate.matches(current)
            : current.hasSameContent(command!);
        if (!matches || current.revision != expectedRevision + 1) {
          _publish(RoutineEditorState(
            status: RoutineEditorStatus.revisionConflict,
            entries: _draft,
            supersets: _draftSupersets,
            revision: current.revision,
            dirty: true,
            message: 'Saved content differs. Reload before editing.',
          ));
          return false;
        }
        _revision = current.revision;
        _baseline = current.entries;
        _draft = current.entries;
        _baselineSupersets = current.supersets;
        _draftSupersets = current.supersets;
        _uncertainCommand = null;
        _uncertainAggregateCommand = null;
        _baselineName = current.name ?? _baselineName;
        _draftName = _baselineName;
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.saved,
          entries: _draft,
          supersets: _draftSupersets,
          revision: _revision,
        ));
        return true;
      }
      if (current.revision > expectedRevision) {
        _publish(RoutineEditorState(
          status: RoutineEditorStatus.revisionConflict,
          entries: _draft,
          supersets: _draftSupersets,
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
    supersets: _draftSupersets,
    revision: _revision,
    name: _draftName,
    dirty: _compositionDirty || _nameDirty,
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
