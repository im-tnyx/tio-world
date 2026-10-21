import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/models/routine_composition_limits.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/my_program_routine_create_repository.dart';
import '../../../domain/repositories/program_repository.dart';
import '../../../domain/repositories/routine_create_repository.dart';
import '../../../domain/repositories/routine_repository.dart';

enum RoutineCreateStatus { ready, verifying, saving, outcomeUnknown, saved }

final class RoutineCreateState {
  RoutineCreateState({
    required this.status,
    required this.name,
    required List<RoutineCompositionEntry> entries,
    this.message,
  }) : entries = List.unmodifiable(entries);

  final RoutineCreateStatus status;
  final String name;
  final List<RoutineCompositionEntry> entries;
  final String? message;

  bool get canSave =>
      status == RoutineCreateStatus.ready &&
      name.trim().isNotEmpty &&
      entries.isNotEmpty &&
      entries.every((entry) => entry.sets.isNotEmpty);
}

/// One in-memory Program-owned draft; no metadata-only persistence path.
/// Every selected Exercise immediately owns an identified Set; numeric targets
/// remain genuinely unspecified until the user chooses to prescribe them.
final class RoutineCreateController extends ChangeNotifier {
  RoutineCreateController({
    required this.program,
    required String initialName,
    required this.repository,
    this.userExercises,
    this.canWrite,
    this.onDefiniteFailure,
    String Function()? newUuid,
  })  : myProgramRepository = null,
        onMyProgramDefiniteFailure = null,
        _name = initialName,
        _newUuid = newUuid ?? (() => const Uuid().v4()) {
    _publish();
  }

  /// Reuse this exact composer for a direct Library Create without inventing
  /// a temporary ProgramId. Only the atomic default resolver owns persistence.
  RoutineCreateController.forMyProgram({
    required String initialName,
    required MyProgramRoutineCreateRepository this.myProgramRepository,
    this.userExercises,
    this.canWrite,
    this.onMyProgramDefiniteFailure,
    String Function()? newUuid,
  })  : program = null,
        repository = null,
        onDefiniteFailure = null,
        _name = initialName,
        _newUuid = newUuid ?? (() => const Uuid().v4()) {
    _publish();
  }

  final Program? program;
  final RoutineCreateRepository? repository;
  final MyProgramRoutineCreateRepository? myProgramRepository;
  /// Definite server rejections release only the frozen programless command.
  final ValueChanged<MyProgramRoutineCreateCommand>?
      onMyProgramDefiniteFailure;
  final UserExerciseRepository? userExercises;
  final bool Function()? canWrite;
  /// The rejected command can outlive a revoked/disposed Create route.
  /// This callback never transfers session capabilities or draft content.
  final ValueChanged<RoutineCreateCommand>? onDefiniteFailure;
  final String Function() _newUuid;
  String _name;
  List<RoutineCompositionEntry> _entries = const [];
  // One selected Custom measurement contract per *entry* (not per Exercise
  // ref: duplicate refs may be added independently to a Routine).
  final Map<String, ExerciseType?> _pickedCustomTypes = {};
  RoutineCreateStatus _status = RoutineCreateStatus.ready;
  RoutineCreateCommand? _attempt;
  MyProgramRoutineCreateCommand? _myProgramAttempt;
  /// The exact uncertain mutation, for owner-scoped recovery on route exit.
  RoutineCreateCommand? get unconfirmedAttempt =>
      _status == RoutineCreateStatus.outcomeUnknown ? _attempt : null;
  MyProgramRoutineCreateCommand? get unconfirmedMyProgramAttempt =>
      _status == RoutineCreateStatus.outcomeUnknown
          ? _myProgramAttempt : null;
  /// Capturable only once the atomic write is actually dispatched, before
  /// its network Future can outlive an auth-revoked Create route.
  RoutineCreateCommand? get inFlightAttempt =>
      _status == RoutineCreateStatus.saving ? _attempt : null;
  MyProgramRoutineCreateCommand? get inFlightMyProgramAttempt =>
      _status == RoutineCreateStatus.saving ? _myProgramAttempt : null;
  String? _message;
  bool _disposed = false;

  late RoutineCreateState _state;
  RoutineCreateState get state => _state;

  bool get _authorized {
    if (_disposed) return false;
    try {
      return canWrite?.call() ?? true;
    } catch (_) {
      return false;
    }
  }

  void _publish([String? message]) {
    if (_disposed) return;
    _message = message;
    _state = RoutineCreateState(
      status: _status, name: _name, entries: _entries, message: _message,
    );
    notifyListeners();
  }

  bool get _editable => !_disposed && _status == RoutineCreateStatus.ready;

  void rename(String name) {
    if (!_editable) return;
    _name = name;
    _publish();
  }

  String? addPickedExercise(Exercise exercise) {
    if (!_editable || exercise.status != ExerciseStatus.active ||
        !RoutineCompositionLimits.supportsExerciseType(exercise.exerciseType)) {
      return null;
    }
    final entryId = _newUuid();
    final setId = _newUuid();
    if (exercise.ref is UserCreatedExerciseRef) {
      _pickedCustomTypes[entryId] = exercise.exerciseType;
    }
    _entries = [
      ..._entries,
      RoutineCompositionEntry(
        id: entryId,
        exercise: exercise.ref,
        sets: [
          RoutineCompositionSet(
            id: setId,
            prescription: SetPrescription(),
          ),
        ],
      ),
    ];
    _publish();
    return entryId;
  }

  /// Replace in the same ordered slot, but never reuse old Exercise targets.
  /// Fresh entry/Set UUIDs prevent cross-exercise prescription attribution.
  String? replacePickedExercise(String entryId, Exercise exercise) {
    if (!_editable || !_authorized ||
        exercise.status != ExerciseStatus.active ||
        !RoutineCompositionLimits.supportsExerciseType(exercise.exerciseType)) {
      return null;
    }
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index < 0 || _entries[index].exercise == exercise.ref) return null;
    final newId = _newUuid();
    final setId = _newUuid();
    _pickedCustomTypes.remove(entryId);
    if (exercise.ref is UserCreatedExerciseRef) {
      _pickedCustomTypes[newId] = exercise.exerciseType;
    }
    _replace(index, RoutineCompositionEntry(
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
    if (!_editable || !_entries.any((e) => e.id == entryId)) return false;
    _entries = _entries.where((e) => e.id != entryId).toList();
    _pickedCustomTypes.remove(entryId);
    _publish();
    return true;
  }

  bool moveExercise(int from, int to) {
    if (!_editable || from < 0 || to < 0 ||
        from >= _entries.length || to >= _entries.length || from == to) {
      return false;
    }
    final next = [..._entries];
    next.insert(to, next.removeAt(from));
    _entries = next;
    _publish();
    return true;
  }

  String? addSet(String entryId, SetPrescription prescription) {
    if (!_editable) return null;
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index < 0) return null;
    final entry = _entries[index];
    // Guard at the controller boundary, not only the Add Set button. Never
    // allocate an ID or change the draft after reaching the per-entry cap.
    if (entry.sets.length >= RoutineCompositionLimits.maxSetsPerExercise) {
      return null;
    }
    final id = _newUuid();
    // Repetition mode is Exercise-wide. New Set remains Normal in that mode.
    final inRange = entry.sets.isNotEmpty &&
        entry.sets.first.prescription.isRepRange;
    final initial = SetPrescription(
      reps: prescription.reps,
      repsMax: inRange ? prescription.reps : null,
      setType: RoutineSetType.normal,
      loadKg: prescription.loadKg,
      distanceMeters: prescription.distanceMeters,
      durationSeconds: prescription.durationSeconds,
      restSeconds: prescription.restSeconds,
    );
    _replace(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      sets: [...entry.sets,
        RoutineCompositionSet(id: id, prescription: initial)],
    ));
    return id;
  }

  bool editSet(String entryId, String setId, SetPrescription prescription) {
    if (!_editable) return false;
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index < 0) return false;
    final entry = _entries[index];
    if (!entry.sets.any((s) => s.id == setId)) return false;
    _replace(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      sets: [
        for (final set in entry.sets)
          set.id == setId
              ? RoutineCompositionSet(id: setId, prescription: prescription)
              : set,
      ],
    ));
    return true;
  }

  /// Classification belongs to an identified Set; preserves target values.
  bool changeSetType(String entryId, String setId, RoutineSetType type) {
    if (!_editable) return false;
    final e = _entries.where((entry) => entry.id == entryId);
    if (e.length != 1) return false;
    final current = e.single.sets.where((set) => set.id == setId);
    if (current.length != 1) return false;
    final p = current.single.prescription;
    if (p.setType == type) return true;
    return editSet(entryId, setId, SetPrescription(
      reps: p.reps, repsMax: p.repsMax, setType: type,
      loadKg: p.loadKg, distanceMeters: p.distanceMeters,
      durationSeconds: p.durationSeconds, restSeconds: p.restSeconds,
    ));
  }

  /// Exercise-level Reps / Rep Range selector. No second stored mode field.
  bool changeRepetitionMode(String entryId, {required bool range}) {
    if (!_editable) return false;
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index < 0) return false;
    final entry = _entries[index];
    if (entry.sets.isEmpty) return false;
    _replace(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      sets: [
        for (final s in entry.sets)
          RoutineCompositionSet(
            id: s.id,
            prescription: SetPrescription(
              reps: s.prescription.reps,
              repsMax: range
                  ? (s.prescription.repsMax ?? s.prescription.reps)
                  : null,
              setType: s.prescription.setType,
              loadKg: s.prescription.loadKg,
              distanceMeters: s.prescription.distanceMeters,
              durationSeconds: s.prescription.durationSeconds,
              restSeconds: s.prescription.restSeconds,
            ),
          ),
      ],
    ));
    return true;
  }

  bool removeSet(String entryId, String setId) {
    if (!_editable) return false;
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index < 0) return false;
    final entry = _entries[index];
    if (!entry.sets.any((s) => s.id == setId)) return false;
    // Create drafts cannot retain an Exercise after its final Set is removed.
    // This invariant belongs to the controller, not only to swipe UI.
    if (entry.sets.length == 1) return removeExercise(entryId);
    _replace(index, RoutineCompositionEntry(
      id: entry.id, exercise: entry.exercise,
      sets: entry.sets.where((s) => s.id != setId).toList(),
    ));
    return true;
  }

  void _replace(int index, RoutineCompositionEntry entry) {
    final next = [..._entries];
    next[index] = entry;
    _entries = next;
    _publish();
  }

  /// A Custom preflight is a cancellable read, not a network write. The RPC
  /// will check Custom owner/active state atomically only after #536 deploy.
  Future<bool> save() async {
    if (!_state.canSave || !_authorized) return false;
    final customRefs = _entries
        .map((entry) => entry.exercise)
        .whereType<UserCreatedExerciseRef>()
        .toSet();
    if (customRefs.isNotEmpty) {
      _status = RoutineCreateStatus.verifying;
      _publish();
      final source = userExercises;
      if (source == null) {
        _status = RoutineCreateStatus.ready;
        _publish('Custom Exercises cannot be verified.');
        return false;
      }
      List<Exercise> current;
      try {
        current = await source.list().timeout(const Duration(seconds: 10));
      } catch (_) {
        if (_disposed) return false;
        _status = RoutineCreateStatus.ready;
        _publish('Could not verify Custom Exercises. Try again.');
        return false;
      }
      if (!_authorized) return false;
      final active = <UserCreatedExerciseRef>{};
      for (final e in current) {
        if (e.status != ExerciseStatus.active ||
            e.ref is! UserCreatedExerciseRef ||
            !active.add(e.ref as UserCreatedExerciseRef)) {
          _status = RoutineCreateStatus.ready;
          _publish('Could not verify Custom Exercises. Try again.');
          return false;
        }
      }
      // A Custom type may change on another device *after* picker selection.
      // Do not persist reps/load under a newly STEPS/TIME-only definition.
      if (current.any((exercise) =>
          customRefs.contains(exercise.ref) &&
          !RoutineCompositionLimits.supportsExerciseType(exercise.exerciseType))) {
        _status = RoutineCreateStatus.ready;
        _publish('Steps & Duration Exercises cannot be saved to Routines yet.');
        return false;
      }
      if (!active.containsAll(customRefs)) {
        _status = RoutineCreateStatus.ready;
        _publish('A selected Custom Exercise is no longer active.');
        return false;
      }
      final currentByRef = {for (final exercise in current) exercise.ref: exercise};
      for (final entry in _entries) {
        if (entry.exercise is! UserCreatedExerciseRef) continue;
        final live = currentByRef[entry.exercise]!;
        if (!_pickedCustomTypes.containsKey(entry.id) ||
            _pickedCustomTypes[entry.id] != live.exerciseType ||
            !RoutineCompositionLimits.targetsMatchExerciseType(
              live.exerciseType,
              entry.sets.map((set) => set.prescription),
            )) {
          _status = RoutineCreateStatus.ready;
          _publish('A Custom Exercise type changed. Remove and add it again.');
          return false; // Never send old KG/REPS under a KM/TIME definition.
        }
      }
    }
    if (!_authorized) return false;
    RoutineCreateCommand? command;
    MyProgramRoutineCreateCommand? myCommand;
    if (program != null) {
      command = _attempt ??= RoutineCreateCommand(
        routine: Routine(
          id: RoutineId(_newUuid()),
          programId: program!.id,
          name: _name.trim(),
        ),
        mutationId: _newUuid(),
        entries: _entries,
        expectedCustomTypes: _pickedCustomTypes,
      );
    } else {
      myCommand = _myProgramAttempt ??= MyProgramRoutineCreateCommand(
        routineId: RoutineId(_newUuid()),
        name: _name.trim(),
        mutationId: _newUuid(),
        entries: _entries,
        expectedCustomTypes: _pickedCustomTypes,
      );
    }
    _status = RoutineCreateStatus.saving;
    _publish();
    try {
      final revision = myCommand != null
          ? (await myProgramRepository!.createInMyProgram(myCommand))
              .compositionRevision
          : await repository!.create(command!);
      if (!_authorized) return false;
      if (revision != 1) throw const FormatException('Invalid Create revision.');
      _status = RoutineCreateStatus.saved;
      _publish();
      return true;
    } on RoutineCompositionException {
      // The RPC definitively rejected this exact command. Even after this
      // controller was disposed by auth revocation, release the old pending
      // identity through the app's owner-bound gate. Do not notify UI state.
      try {
        if (myCommand != null) {
          onMyProgramDefiniteFailure?.call(myCommand);
        } else {
          onDefiniteFailure?.call(command!);
        }
      } catch (_) {
        // Fail closed: a broken cleanup callback must not turn a rejection
        // into an unhandled error or a new/unknown write attempt.
      }
      if (_disposed || !_authorized) return false;
      // A definite server/auth rejection rolled back the transaction.
      // Keep the editable Exercise/Set draft, but discard the rejected
      // identity+mutation attempt so an explicit Save can try afresh.
      _attempt = null;
      _myProgramAttempt = null;
      _status = RoutineCreateStatus.ready;
      _publish('Could not create Routine. Review Exercises and try again.');
      return false;
    } catch (_) {
      if (_disposed) return false;
      // After the request, a transport error does NOT prove no commit.
      // Keep the exact command and refuse to generate another Routine.
      _status = RoutineCreateStatus.outcomeUnknown;
      _publish('Could not confirm Create. Verify before retrying.');
      return false;
    }
  }

  /// Read-only authoritative confirmation; an unknown outcome is not auto-
  /// retried and does not allow generating a new mutation token.
  Future<bool> reconcileUnknown({
    ProgramRepository? programs,
    required RoutineRepository routines,
    required RoutineCompositionRepository compositions,
  }) async {
    if (_disposed || _status != RoutineCreateStatus.outcomeUnknown ||
        !_authorized) {
      return false;
    }
    try {
      final myCommand = _myProgramAttempt;
      if (myCommand != null) {
        if (programs == null) return false;
        // Match the server-owned is_default identity, not the display name.
        final defaults = (await programs.list())
            .where((p) => p.isDefault).toList();
        if (!_authorized || defaults.length != 1) return false;
        final defaultProgram = defaults.single;
        final rows = await routines.list(defaultProgram.id);
        if (!_authorized) return false;
        final matches = rows.where((r) => r.id == myCommand.routineId &&
            r.programId == defaultProgram.id).toList();
        if (matches.length != 1) return false;
        final snapshot = await compositions.read(myCommand.routineId);
        if (!_authorized || snapshot == null ||
            !myCommand.confirmsPersistedInCanonicalDefault(
              program: defaultProgram,
              routine: matches.single,
              snapshot: snapshot,
            )) {
          return false;
        }
      } else {
        final attempted = _attempt;
        final ownerProgram = program;
        if (attempted == null || ownerProgram == null) return false;
        final owned = await routines.list(ownerProgram.id);
        if (!_authorized) return false;
        final found = owned.where((r) => r.id == attempted.routine.id).toList();
        if (found.length != 1 ||
            found.single.programId != ownerProgram.id) {
          return false;
        }
        final snapshot = await compositions.read(attempted.routine.id);
        if (!_authorized || snapshot == null ||
            !attempted.confirmsPersistedRoutine(snapshot)) {
          return false;
        }
      }
      _status = RoutineCreateStatus.saved;
      _publish();
      return true;
    } catch (_) {
      // Any missing/ambiguous read stays UNKNOWN and cannot trigger a retry.
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
