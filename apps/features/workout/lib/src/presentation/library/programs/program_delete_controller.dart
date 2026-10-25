import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../../../data/repositories/routine_move_delete_attempt_gate.dart';
import '../../../data/repositories/supabase_program_delete_repository.dart';
import '../../../domain/repositories/program_delete_repository.dart';
import '../../../domain/repositories/program_repository.dart';
import '../../../domain/repositories/routine_repository.dart';
import '../routines/routine_pending_create_gate.dart';

enum ProgramDeleteOperationStatus {
  idle,
  preparing,
  ready,
  inFlight,
  confirmed,
  definitelyRejected,
  unknown,
}

final class ProgramDeleteRefreshRequest {
  const ProgramDeleteRefreshRequest({
    required this.ownerId,
    required this.loginCycleId,
    required this.sourceProgramId,
    required this.destinationProgramId,
  });

  final String ownerId;
  final String loginCycleId;
  final ProgramId sourceProgramId;
  final ProgramId? destinationProgramId;
}

typedef ProgramDeleteRefresh = Future<void> Function(
  ProgramDeleteRefreshRequest request,
);

final class ProgramDeleteControllerState {
  const ProgramDeleteControllerState({
    required this.status,
    this.program,
    this.target,
    this.result,
    this.failure,
    this.unknown,
    this.refreshFailed = false,
  });

  const ProgramDeleteControllerState.idle()
      : this(status: ProgramDeleteOperationStatus.idle);

  final ProgramDeleteOperationStatus status;
  final Program? program;
  final ProgramDeleteTarget? target;
  final ProgramDeleteResult? result;
  final ProgramDeleteException? failure;
  final ProgramDeleteOutcomeUnknown? unknown;
  final bool refreshFailed;

  bool get canConfirm =>
      status == ProgramDeleteOperationStatus.ready && target != null;
}

/// Explicit, dormant D2B orchestration for a future confirmed Delete action.
///
/// This controller owns only preparation, session arbitration and read
/// invalidation. The D2A repository remains the sole RPC/UNKNOWN boundary and
/// the existing ProgramsController/ProgramRoutinesController remain the
/// authoritative list readers.
final class ProgramDeleteController extends ChangeNotifier {
  ProgramDeleteController({
    required ProgramRepository programs,
    required RoutineVersionedRenameRepository routines,
    required ProgramDeleteRepository deleteRepository,
    required ProgramDeleteAttemptGate attemptGate,
    required RoutinePendingCreateGate pendingCreateGate,
    required RoutineMoveDeleteAttemptGate routineOperationGate,
    required ProgramDeleteRefresh refresh,
  })  : _programs = programs,
        _routines = routines,
        _deleteRepository = deleteRepository,
        _attemptGate = attemptGate,
        _pendingCreateGate = pendingCreateGate,
        _routineOperationGate = routineOperationGate,
        _refresh = refresh;

  final ProgramRepository _programs;
  final RoutineVersionedRenameRepository _routines;
  final ProgramDeleteRepository _deleteRepository;
  final ProgramDeleteAttemptGate _attemptGate;
  final RoutinePendingCreateGate _pendingCreateGate;
  final RoutineMoveDeleteAttemptGate _routineOperationGate;
  final ProgramDeleteRefresh _refresh;

  ProgramDeleteControllerState _state =
      const ProgramDeleteControllerState.idle();
  ProgramDeleteControllerState get state => _state;

  ({String owner, String cycle})? _preparedSession;
  var _disposed = false;

  /// Reads the complete owner-scoped source snapshot but never dispatches an
  /// RPC. A future confirmed action must call [confirm] explicitly.
  Future<bool> prepare(ProgramId sourceProgramId) async {
    if (_disposed ||
        _state.status == ProgramDeleteOperationStatus.preparing ||
        _state.status == ProgramDeleteOperationStatus.inFlight ||
        _state.status == ProgramDeleteOperationStatus.confirmed ||
        _state.status == ProgramDeleteOperationStatus.unknown) {
      return false;
    }

    final session = _session();
    if (session == null) {
      _reject(const ProgramDeleteException(
        ProgramDeleteFailureKind.unauthorized,
      ));
      return false;
    }
    if (_attemptGate.isUnknown(session.owner, sourceProgramId)) {
      _publish(const ProgramDeleteControllerState(
        status: ProgramDeleteOperationStatus.unknown,
        unknown: ProgramDeleteOutcomeUnknown(),
      ));
      return false;
    }
    if (_attemptGate.isCommitted(session.owner, sourceProgramId)) {
      _publish(const ProgramDeleteControllerState(
        status: ProgramDeleteOperationStatus.confirmed,
      ));
      return false;
    }
    if (_attemptGate.isInFlight(session.owner, sourceProgramId)) {
      _publish(const ProgramDeleteControllerState(
        status: ProgramDeleteOperationStatus.inFlight,
      ));
      return false;
    }

    _publish(const ProgramDeleteControllerState(
      status: ProgramDeleteOperationStatus.preparing,
    ));
    try {
      final programs = await _programs.list();
      _requireSession(session);
      final matches = programs
          .where((program) => program.id == sourceProgramId)
          .toList(growable: false);
      if (matches.length != 1) {
        _reject(
            const ProgramDeleteException(ProgramDeleteFailureKind.notFound));
        return false;
      }
      final program = matches.single;
      if (program.isDefault) {
        _reject(
          const ProgramDeleteException(
              ProgramDeleteFailureKind.defaultProtected),
          program: program,
        );
        return false;
      }
      if (_pendingCreateGate.hasPendingForOwnerProgram(
        owner: session.owner,
        programId: sourceProgramId,
      )) {
        _reject(
          const ProgramDeleteException(
              ProgramDeleteFailureKind.staleMembership),
          program: program,
        );
        return false;
      }

      final snapshots = await _routines.listVersioned(sourceProgramId);
      _requireSession(session);
      final target = ProgramDeleteTarget.fromVersionedRoutines(
        sourceProgramId: sourceProgramId,
        routines: snapshots,
        ownerId: session.owner,
        loginCycleId: session.cycle,
      );
      if (target.expectedRoutineIds.any(
        (routineId) =>
            _routineOperationGate.inFlight(session.owner, routineId) ||
            _routineOperationGate.uncertain(session.owner, routineId),
      )) {
        _reject(
          const ProgramDeleteException(
              ProgramDeleteFailureKind.staleMembership),
          program: program,
        );
        return false;
      }

      _preparedSession = session;
      _publish(ProgramDeleteControllerState(
        status: ProgramDeleteOperationStatus.ready,
        program: program,
        target: target,
      ));
      return true;
    } on ProgramDeleteException catch (error) {
      _reject(error);
      return false;
    } on StateError {
      _reject(const ProgramDeleteException(
        ProgramDeleteFailureKind.unauthorized,
      ));
      return false;
    } on FormatException {
      _reject(const ProgramDeleteException(
        ProgramDeleteFailureKind.malformedData,
      ));
      return false;
    } catch (_) {
      _reject(const ProgramDeleteException(
        ProgramDeleteFailureKind.unavailable,
      ));
      return false;
    }
  }

  /// Dispatches only after a fresh [prepare] and an explicit confirmed action.
  /// The mutation UUID is supplied by that caller and is never regenerated.
  Future<ProgramDeleteControllerState> confirm({
    required String clientMutationId,
  }) async {
    final current = _state;
    final target = current.target;
    final preparedSession = _preparedSession;
    if (_disposed ||
        current.status != ProgramDeleteOperationStatus.ready ||
        target == null ||
        preparedSession == null) {
      return current;
    }
    if (!_sameSession(preparedSession)) {
      _reject(const ProgramDeleteException(
        ProgramDeleteFailureKind.unauthorized,
      ));
      return _state;
    }
    if (_attemptGate.isUnknown(
      preparedSession.owner,
      target.sourceProgramId,
    )) {
      _publish(const ProgramDeleteControllerState(
        status: ProgramDeleteOperationStatus.unknown,
        unknown: ProgramDeleteOutcomeUnknown(),
      ));
      return _state;
    }
    if (_attemptGate.isCommitted(
      preparedSession.owner,
      target.sourceProgramId,
    )) {
      _publish(ProgramDeleteControllerState(
        status: ProgramDeleteOperationStatus.confirmed,
        program: current.program,
        target: target,
      ));
      return _state;
    }

    _publish(ProgramDeleteControllerState(
      status: ProgramDeleteOperationStatus.inFlight,
      program: current.program,
      target: target,
    ));
    try {
      final result = await _deleteRepository.delete(
        target: target,
        clientMutationId: clientMutationId,
      );
      if (!_sameSession(preparedSession)) {
        _publish(const ProgramDeleteControllerState(
          status: ProgramDeleteOperationStatus.unknown,
          unknown: ProgramDeleteOutcomeUnknown(
            reason: ProgramDeleteUncertainty.sessionChanged,
          ),
        ));
        return _state;
      }
      _publish(ProgramDeleteControllerState(
        status: ProgramDeleteOperationStatus.confirmed,
        program: current.program,
        target: target,
        result: result,
      ));
      await _refreshAfterAttempt(
        preparedSession,
        sourceProgramId: target.sourceProgramId,
        destinationProgramId: result.destinationProgramId,
      );
      return _state;
    } on ProgramDeleteOutcomeUnknown catch (error) {
      _publish(ProgramDeleteControllerState(
        status: ProgramDeleteOperationStatus.unknown,
        program: current.program,
        target: target,
        unknown: error,
      ));
      await _refreshAfterAttempt(
        preparedSession,
        sourceProgramId: target.sourceProgramId,
      );
      return _state;
    } on ProgramDeleteException catch (error) {
      if (error.kind == ProgramDeleteFailureKind.inProgress) {
        _publish(ProgramDeleteControllerState(
          status: ProgramDeleteOperationStatus.inFlight,
          program: current.program,
          target: target,
          failure: error,
        ));
        return _state;
      }
      _reject(error, program: current.program, target: target);
      await _refreshAfterAttempt(
        preparedSession,
        sourceProgramId: target.sourceProgramId,
      );
      return _state;
    } catch (_) {
      const error = ProgramDeleteOutcomeUnknown();
      _publish(ProgramDeleteControllerState(
        status: ProgramDeleteOperationStatus.unknown,
        program: current.program,
        target: target,
        unknown: error,
      ));
      await _refreshAfterAttempt(
        preparedSession,
        sourceProgramId: target.sourceProgramId,
      );
      return _state;
    }
  }

  Future<void> _refreshAfterAttempt(
    ({String owner, String cycle}) session, {
    required ProgramId sourceProgramId,
    ProgramId? destinationProgramId,
  }) async {
    if (!_sameSession(session)) return;
    try {
      await _refresh(ProgramDeleteRefreshRequest(
        ownerId: session.owner,
        loginCycleId: session.cycle,
        sourceProgramId: sourceProgramId,
        destinationProgramId: destinationProgramId,
      ));
    } catch (_) {
      if (!_disposed) {
        final current = _state;
        _publish(ProgramDeleteControllerState(
          status: current.status,
          program: current.program,
          target: current.target,
          result: current.result,
          failure: current.failure,
          unknown: current.unknown,
          refreshFailed: true,
        ));
      }
    }
  }

  ({String owner, String cycle})? _session() {
    final owner = _routines.activeOwnerId?.trim().toLowerCase();
    final cycle = _routines.activeLoginCycleId?.trim();
    if (owner == null || owner.isEmpty || cycle == null || cycle.isEmpty) {
      return null;
    }
    return (owner: owner, cycle: cycle);
  }

  bool _sameSession(({String owner, String cycle}) session) {
    final current = _session();
    return current?.owner == session.owner && current?.cycle == session.cycle;
  }

  void _requireSession(({String owner, String cycle}) session) {
    if (!_sameSession(session)) throw StateError('Session changed.');
  }

  void _reject(
    ProgramDeleteException error, {
    Program? program,
    ProgramDeleteTarget? target,
  }) {
    if (_disposed) return;
    _preparedSession = null;
    _publish(ProgramDeleteControllerState(
      status: ProgramDeleteOperationStatus.definitelyRejected,
      program: program,
      target: target,
      failure: error,
    ));
  }

  void _publish(ProgramDeleteControllerState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _preparedSession = null;
    super.dispose();
  }
}
