import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/routine_create_repository.dart';
import '../../../domain/repositories/routine_repository.dart';

/// In-memory owner/login-cycle protection for an unconfirmed Create.
/// Negative reads never prove that the timed-out atomic RPC cannot commit.
final class RoutinePendingCreateGate {
  String? _owner;
  String? _cycle;
  final Map<ProgramId, RoutineCreateCommand> _pending = {};

  void bindSession({required String owner, required String loginCycle}) {
    if (_owner == owner && _cycle == loginCycle) return;
    // A same-owner reauthentication must not erase an atomic Create which
    // was already sent and may still commit. Never carry it across owners.
    // The NEW login cycle alone may verify the previous immutable identity.
    if (_owner != owner) _pending.clear();
    _owner = owner;
    _cycle = loginCycle;
  }

  bool _same(String owner, String cycle) =>
      _owner == owner && _cycle == cycle;

  bool hasPending({
    required String owner, required String loginCycle,
    required ProgramId programId,
  }) => _same(owner, loginCycle) && _pending.containsKey(programId);

  void retain({
    required String owner, required String loginCycle,
    required RoutineCreateCommand command,
  }) {
    if (!_same(owner, loginCycle)) {
      throw StateError('Unverified Routine Create owner.');
    }
    final id = command.routine.programId;
    final previous = _pending[id];
    if (previous != null &&
        (previous.routine.id != command.routine.id ||
         previous.mutationId != command.mutationId)) {
      throw StateError('Unconfirmed Create already exists.');
    }
    _pending[id] = command;
  }

  /// Clear only a DEFINITELY failed or acknowledged attempt in its own
  /// opening login cycle. A revoked cycle cannot clear a newer session's gate.
  void release({
    required String owner, required String loginCycle,
    required RoutineCreateCommand command,
  }) {
    if (!_same(owner, loginCycle)) return;
    final programId = command.routine.programId;
    if (identical(_pending[programId], command)) {
      _pending.remove(programId);
    }
  }

  /// Only positive matching metadata and composition clears the safety gate.
  Future<bool> verify({
    required String owner, required String loginCycle,
    required ProgramId programId,
    required RoutineRepository routines,
    required RoutineCompositionRepository compositions,
    required bool Function() canWrite,
  }) async {
    if (!_same(owner, loginCycle) || !canWrite()) return false;
    final command = _pending[programId];
    if (command == null) return false;
    try {
      final rows = await routines.list(programId);
      if (!_same(owner, loginCycle) || !canWrite()) return false;
      if (rows.where((row) => row.id == command.routine.id &&
          row.programId == programId).length != 1) {
        return false;
      }
      final snapshot = await compositions.read(command.routine.id);
      if (!_same(owner, loginCycle) || !canWrite()) return false;
      if (snapshot == null || !command.confirmsPersistedRoutine(snapshot)) {
        return false;
      }
      if (!identical(_pending[programId], command)) return false;
      _pending.remove(programId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
