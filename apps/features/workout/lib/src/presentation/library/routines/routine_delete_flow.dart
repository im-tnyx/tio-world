import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_delete_repository.dart';

/// One feature-owned confirmation workflow, shared by both Routine surfaces.
/// Business outcomes stay here, not in the app-shell router or Core sheet.
final class RoutineDeleteFlow {
  final Set<RoutineId> _opening = <RoutineId>{};

  /// True means the current owner list should be re-read, including when a
  /// dispatched RPC has an UNKNOWN outcome. It never implies success.
  Future<bool> run({
    required BuildContext context,
    required Program program,
    required Routine routine,
    required RoutineDeleteRepository repository,
    required bool Function() canWrite,
  }) async {
    if (routine.programId != program.id || !canWrite() ||
        !_opening.add(routine.id)) {
      return false;
    }
    var attempted = false;
    try {
      final target = await repository.inspect(
        programId: program.id, routineId: routine.id,
      );
      if (!context.mounted || !canWrite()) return false;
      if (target == null || target.programId != program.id ||
          target.routineId != routine.id) {
        _show(context, 'This Routine is no longer available. Refresh the list.');
        return true;
      }
      final confirmed = await showTioConfirmationBottomSheet(
        context: context,
        title: 'Delete Routine?',
        message: 'Delete "${target.name}" and its saved Exercises and Sets? '
            'This cannot be undone.',
        confirmLabel: 'Delete Routine',
        cancelLabel: 'Cancel',
        intent: TioConfirmationIntent.destructive,
        cardKey: ValueKey('confirm-delete-routine-${routine.id.value}'),
      );
      // The owner/login cycle may change while inspection or the sheet awaits.
      if (confirmed != true || !context.mounted || !canWrite()) return false;
      attempted = true;
      final result = await repository.delete(target);
      if (!context.mounted || !canWrite()) return false;
      if (result == RoutineDeleteResult.confirmed) {
        _show(context, 'Routine deleted.');
        return true;
      }
      return false;
    } on RoutineDeleteOutcomeUnknown {
      if (context.mounted && canWrite()) {
        _show(context,
            'Delete status is unconfirmed. Checking your Routines; do not retry.');
        return true;
      }
      return false;
    } on RoutineDeleteException catch (error) {
      if (!context.mounted || !canWrite()) return false;
      switch (error.kind) {
        case RoutineDeleteFailureKind.unauthorized:
        case RoutineDeleteFailureKind.forbidden:
          _show(context, 'Your session changed. Sign in again to manage Routines.');
        case RoutineDeleteFailureKind.inProgress:
          _show(context, 'Another Delete is still in progress.');
        case RoutineDeleteFailureKind.revisionConflict:
        case RoutineDeleteFailureKind.staleTarget:
        case RoutineDeleteFailureKind.notFound:
          _show(context, 'This Routine changed. Refresh the list before trying again.');
        default:
          _show(context, 'Could not delete this Routine. Please try again later.');
      }
      return attempted;
    } catch (_) {
      // Never expose raw provider or database errors in product UI.
      if (context.mounted && canWrite()) {
        _show(context, 'Could not verify this Routine. Please try again later.');
      }
      return attempted && context.mounted && canWrite();
    } finally {
      _opening.remove(routine.id);
    }
  }

  void _show(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
