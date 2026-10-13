import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/exercises/user_exercise_repository.dart';
import '../../../domain/repositories/routine_composition_repository.dart';
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
      entries.isNotEmpty;
}

/// One in-memory Program-owned draft; no metadata-only persistence path.
/// UI can add Exercises without requiring extra set input because Set 1 is
/// created with the minimum valid prescription (one rep, no load/rest target).
final class RoutineCreateController extends ChangeNotifier {
  RoutineCreateController({
    required this.program,
    required String initialName,
    required this.repository,
    this.userExercises,
    this.canWrite,
    String Function()? newUuid,
  })  : _name = initialName,
        _newUuid = newUuid ?? (() => const Uuid().v4()) {
    _publish();
  }

  final Program program;
  final RoutineCreateRepository repository;
  final UserExerciseRepository? userExercises;
  final bool Function()? canWrite;
  final String Function() _newUuid;
  String _name;
  List<RoutineCompositionEntry> _entries = const [];
  RoutineCreateStatus _status = RoutineCreateStatus.ready;
  RoutineCreateCommand? _attempt;
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
    if (!_editable || exercise.status != ExerciseStatus.active) return null;
    final entryId = _newUuid();
    final setId = _newUuid();
    _entries = [
      ..._entries,
      RoutineCompositionEntry(
        id: entryId,
        exercise: exercise.ref,
        sets: [
          RoutineCompositionSet(
            id: setId,
            prescription: SetPrescription(reps: 1),
          ),
        ],
      ),
    ];
    _publish();
    return entryId;
  }

  bool removeExercise(String entryId) {
    if (!_editable || !_entries.any((e) => e.id == entryId)) return false;
    _entries = _entries.where((e) => e.id != entryId).toList();
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
    final id = _newUuid();
    final entry = _entries[index];
    _replace(index, RoutineCompositionEntry(
      id: entry.id,
      exercise: entry.exercise,
      sets: [...entry.sets,
        RoutineCompositionSet(id: id, prescription: prescription)],
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

  bool removeSet(String entryId, String setId) {
    if (!_editable) return false;
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index < 0) return false;
    final entry = _entries[index];
    if (!entry.sets.any((s) => s.id == setId)) return false;
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
      if (!active.containsAll(customRefs)) {
        _status = RoutineCreateStatus.ready;
        _publish('A selected Custom Exercise is no longer active.');
        return false;
      }
    }
    if (!_authorized) return false;
    final command = _attempt ??= RoutineCreateCommand(
      routine: Routine(
        id: RoutineId(_newUuid()),
        programId: program.id,
        name: _name.trim(),
      ),
      mutationId: _newUuid(),
      entries: _entries,
    );
    _status = RoutineCreateStatus.saving;
    _publish();
    try {
      final revision = await repository.create(command);
      if (!_authorized) return false;
      if (revision != 1) throw const FormatException('Invalid Create revision.');
      _status = RoutineCreateStatus.saved;
      _publish();
      return true;
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
    required RoutineRepository routines,
    required RoutineCompositionRepository compositions,
  }) async {
    final attempted = _attempt;
    if (_disposed || attempted == null ||
        _status != RoutineCreateStatus.outcomeUnknown || !_authorized) {
      return false;
    }
    try {
      final owned = await routines.list(program.id);
      if (!_authorized) return false;
      final found = owned.where((r) => r.id == attempted.routine.id).toList();
      if (found.length != 1 ||
          found.single.programId != program.id ||
          found.single.name != attempted.routine.name) return false;
      final snapshot = await compositions.read(attempted.routine.id);
      if (!_authorized) return false;
      final frozen = RoutineCompositionSave(
        routineId: attempted.routine.id,
        expectedRevision: 0,
        mutationId: attempted.mutationId,
        entries: attempted.entries,
      );
      if (snapshot == null || snapshot.revision != 1 ||
          snapshot.lastMutationId != attempted.mutationId ||
          !snapshot.hasSameContent(frozen)) return false;
      _status = RoutineCreateStatus.saved;
      _publish();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
