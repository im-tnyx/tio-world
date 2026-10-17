import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/program_repository.dart';
import '../../../domain/repositories/routine_move_repository.dart';

/// Verified Routine snapshot and selectable owner Program IDs. Not a grant.
final class RoutineMoveSelection {
  RoutineMoveSelection({
    required this.target,
    required List<Program> destinations,
  }) : destinations = List.unmodifiable(destinations);

  final RoutineMoveTarget target;
  final List<Program> destinations;
}

/// Feature-owned, dormant M3B1 selection boundary. The future UI owns the
/// explicit confirmation; this class only dispatches after that confirmation.
/// An app owner/login-cycle guard MUST be injected when the UI is connected.
final class RoutineMoveDestinationController {
  RoutineMoveDestinationController({
    required this.moves,
    required this.programs,
    required this.canWrite,
  });

  final RoutineMoveRepository moves;
  final ProgramRepository programs;
  final bool Function() canWrite;
  RoutineMoveSelection? _prepared;

  /// Do not trust an unversioned Routine card or a guessed My Program name.
  /// MoveRepository.inspect takes a fresh owner-scoped revision snapshot.
  Future<RoutineMoveSelection?> inspect({
    required ProgramId sourceProgramId,
    required RoutineId routineId,
  }) async {
    _prepared = null;
    _requireSession();
    final target = await moves.inspect(
      sourceProgramId: sourceProgramId,
      routineId: routineId,
    );
    _requireSession();
    if (target == null ||
        target.routineId != routineId ||
        target.sourceProgramId != sourceProgramId) {
      return null;
    }
    final rows = await programs.list();
    _requireSession();
    _validatePrograms(rows);
    final selection = RoutineMoveSelection(
      target: target,
      destinations: [
        for (final program in rows)
          if (program.id != sourceProgramId) program,
      ],
    );
    _prepared = selection;
    return selection;
  }

  /// Only call after an explicit UI confirmation naming the destination.
  /// Consumes the selection BEFORE any awaited validation, even on denial.
  /// The existing M1 server RPC remains the atomic CAS/security authority.
  Future<RoutineMoveResult> dispatchConfirmed({
    required RoutineMoveSelection selection,
    required ProgramId destinationProgramId,
    required String mutationId,
  }) async {
    _requireSession();
    if (!identical(selection, _prepared)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    _prepared = null;
    if (destinationProgramId == selection.target.sourceProgramId ||
        !selection.destinations.any((p) => p.id == destinationProgramId)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.invalidRequest);
    }
    final current = await programs.list();
    _requireSession();
    _validatePrograms(current);
    if (!current.any((p) => p.id == destinationProgramId)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.staleTarget);
    }
    final result = await moves.move(
      target: selection.target,
      destinationProgramId: destinationProgramId,
      mutationId: mutationId,
    );
    if (!canWrite()) {
      // The server may have committed before the owner/login-cycle changed.
      throw const RoutineMoveOutcomeUnknown(
        reason: RoutineMoveUncertainty.sessionChanged,
      );
    }
    return result;
  }

  void abandon() => _prepared = null;

  void _requireSession() {
    if (!canWrite()) {
      _prepared = null;
      throw const RoutineMoveException(RoutineMoveFailureKind.unauthorized);
    }
  }

  static void _validatePrograms(List<Program> programs) {
    if (programs.map((p) => p.id).toSet().length != programs.length ||
        programs.any((p) => p.name.trim().isEmpty)) {
      throw const RoutineMoveException(RoutineMoveFailureKind.malformedData);
    }
  }
}
