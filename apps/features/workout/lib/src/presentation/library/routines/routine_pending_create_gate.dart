import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_composition_repository.dart';
import '../../../domain/repositories/routine_create_repository.dart';
import '../../../domain/repositories/routine_repository.dart';

/// In-memory owner/login-cycle protection for an unconfirmed Create.
/// A dispatched Create can finish after A -> B -> A account switches; retain
/// each owner's opaque command privately, but only expose it in that owner's
/// authenticated login cycle. Never render a former owner's draft to another.
/// Negative reads never prove that the timed-out atomic RPC cannot commit.
final class RoutinePendingCreateGate extends ChangeNotifier {
  String? _owner;
  String? _cycle;
  final Map<String, Map<ProgramId, RoutineCreateCommand>> _pendingByOwner = {};

  Map<ProgramId, RoutineCreateCommand> _forOwner(String owner) =>
      _pendingByOwner.putIfAbsent(owner, () => {});

  void bindSession({required String owner, required String loginCycle}) {
    if (_owner == owner && _cycle == loginCycle) return;
    // The previous owner's already-dispatched write may still commit.
    // Preserve its opaque identity under that owner only; no cross-owner
    // read or write capability is transferred with this session binding.
    // The new login cycle alone can inspect its own owner's pending commands.
    _owner = owner;
    _cycle = loginCycle;
    notifyListeners();
  }

  bool _same(String owner, String cycle) =>
      _owner == owner && _cycle == cycle;

  bool hasPending({
    required String owner, required String loginCycle,
    required ProgramId programId,
  }) => _same(owner, loginCycle) &&
      (_pendingByOwner[owner]?.containsKey(programId) ?? false);

  void retain({
    required String owner, required String loginCycle,
    required RoutineCreateCommand command,
  }) {
    if (!_same(owner, loginCycle)) {
      throw StateError('Unverified Routine Create owner.');
    }
    final id = command.routine.programId;
    final pending = _forOwner(owner);
    final previous = pending[id];
    if (previous != null &&
        (previous.routine.id != command.routine.id ||
         previous.mutationId != command.mutationId)) {
      throw StateError('Unconfirmed Create already exists.');
    }
    pending[id] = command;
    notifyListeners();
  }

  /// Clear only a DEFINITELY failed or acknowledged attempt in its own
  /// opening login cycle. A revoked cycle cannot clear a newer session's gate.
  void release({
    required String owner, required String loginCycle,
    required RoutineCreateCommand command,
  }) {
    if (!_same(owner, loginCycle)) return;
    final programId = command.routine.programId;
    final pending = _pendingByOwner[owner];
    if (identical(pending?[programId], command)) {
      pending!.remove(programId);
      if (pending.isEmpty) _pendingByOwner.remove(owner);
      notifyListeners();
    }
  }

  /// A DEFINITE server rejection proves that this specific Create did not
  /// commit, even if its original screen was removed on same-owner reauth.
  /// Do not use this for timeouts, lost ACKs or other uncertain outcomes.
  void releaseDefiniteForOwner({
    required String owner,
    required RoutineCreateCommand command,
  }) {
    // The old owner's DEFINITE failure may arrive while B is signed in.
    // Clear only A's exact identity, without touching B's active reservation.
    final pending = _pendingByOwner[owner];
    final id = command.routine.programId;
    if (identical(pending?[id], command)) {
      pending!.remove(id);
      if (pending.isEmpty) _pendingByOwner.remove(owner);
      notifyListeners();
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
    final command = _pendingByOwner[owner]?[programId];
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
      final pending = _pendingByOwner[owner];
      if (!identical(pending?[programId], command)) return false;
      pending!.remove(programId);
      if (pending.isEmpty) _pendingByOwner.remove(owner);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
