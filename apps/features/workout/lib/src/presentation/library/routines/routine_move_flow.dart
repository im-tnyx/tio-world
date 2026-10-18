import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/repositories/program_repository.dart';
import '../../../domain/repositories/routine_move_repository.dart';
import 'routine_move_destination_controller.dart';
import '../programs/programs_controller.dart';
import '../programs/programs_surface.dart';

/// The future server-atomic Create+Move capability. This slice does not wire
/// one into the app; the New Program action stays hidden without it.
typedef RoutineCreateMoveCallback = Future<RoutineMoveResult> Function({
  required RoutineMoveTarget target,
  required ProgramId newProgramId,
  required String newProgramName,
  required String mutationId,
});

enum _MoveDestinationChoice { newProgram }

/// Feature-owned Move workflow shared by the two Routine card surfaces.
///
/// Returning true requests a caller-guarded, current-owner list refresh,
/// including an UNKNOWN RPC outcome; it is not proof that the Move committed.
/// Once a write was dispatched, a later auth switch or widget disposal must
/// suppress feedback, never erase the refresh/reconciliation signal.
/// Destination eligibility, cancellation and the sole confirmed RPC dispatch
/// stay in [RoutineMoveDestinationController], not in this modal flow.
final class RoutineMoveFlow {
  RoutineMoveFlow({String Function()? newMutationId})
      : _newMutationId = newMutationId ?? _uuidV4;

  final String Function() _newMutationId;
  final Set<RoutineId> _opening = <RoutineId>{};

  static String _uuidV4() => const Uuid().v4();

  Future<bool> run({
    required BuildContext context,
    required Program sourceProgram,
    required Routine routine,
    required ProgramRepository programs,
    required RoutineMoveRepository repository,
    required bool Function() canWrite,
    RoutineCreateMoveCallback? createAndMove,
    /// Development-only visual preview: never dispatch either Move RPC.
    bool previewOnly = false,
    Widget Function(BuildContext dialogContext, Widget content)? modalGuard,
  }) async {
    if (routine.programId != sourceProgram.id || !canWrite() ||
        !_opening.add(routine.id)) {
      return false;
    }

    final controller = RoutineMoveDestinationController(
      moves: repository, programs: programs, canWrite: canWrite,
    );
    var attempted = false;
    try {
      final selection = await controller.inspect(
        sourceProgramId: sourceProgram.id,
        routineId: routine.id,
      );
      if (!context.mounted || !canWrite()) return false;
      if (selection == null ||
          selection.target.routineId != routine.id ||
          selection.target.sourceProgramId != sourceProgram.id) {
        _show(context, 'This Routine changed. Refresh the list.');
        return true;
      }
      // Controller owns the one-use, owner-scoped destination eligibility.
      // Do not infer My Program by its mutable display name.
      final target = selection.target;
      final destinations = selection.destinations;
      if (destinations.isEmpty && createAndMove == null) {
        _show(context, 'Create another Program before moving this Routine.');
        return false;
      }

      final chosen = await showTioEditorSheet<Object>(
        context: context,
        useSafeArea: true,
        builder: (sheetContext) {
          final sheet = TioEditorSheet(
            key: ValueKey('routine-move-destinations-${routine.id.value}'),
            title: 'Move Routine',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (createAndMove != null) ...[
                  ListTile(
                    key: const ValueKey('routine-move-new-program'),
                    title: const Text('+ New Program'),
                    leading: const Icon(Icons.add_rounded),
                    onTap: () => Navigator.of(sheetContext)
                        .pop(_MoveDestinationChoice.newProgram),
                  ),
                  if (destinations.isNotEmpty)
                    const SizedBox(height: TioSpacing.sm),
                ],
                if (destinations.isNotEmpty) ...[
                  const Text('Select an existing destination Program'),
                  const SizedBox(height: TioSpacing.sm),
                ],
                for (final program in destinations)
                  ListTile(
                    key: ValueKey('routine-move-destination-${program.id.value}'),
                    title: Text(program.name, maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(program.id),
                  ),
              ],
            ),
          );
          return modalGuard?.call(sheetContext, sheet) ?? sheet;
        },
      );

      if (!context.mounted || !canWrite() || chosen == null) return false;
      if (chosen == _MoveDestinationChoice.newProgram) {
        if (createAndMove == null) return false;
        final proposedName = await promptCreateProgramName(
          context: context,
          initialName: suggestProgramName([sourceProgram, ...destinations]),
          modalGuard: modalGuard,
        );
        if (!context.mounted || !canWrite() || proposedName == null) {
          return false;
        }

        // A proposed ID is frozen once per explicitly confirmed attempt.
        // No ProgramRepository.create and no fallback two-RPC transaction.
        final proposed = Program(
          id: ProgramId(_uuidV4()),
          name: proposedName,
        );
        final confirmed = await _confirm(
          context: context,
          routineName: target.name,
          destination: proposed,
          modalGuard: modalGuard,
          createProgram: true,
        );
        if (confirmed != true || !context.mounted || !canWrite()) return false;
        // Preview is a real owner-scoped, read-only UI flow. Never create a
        // Program or send the atomic Create+Move command even after confirm.
        if (previewOnly) {
          _show(context, 'Preview only. No Program or Routine was changed.');
          return false;
        }

        // Re-check the owner-scoped source after the confirmation; server CAS
        // is still the final ownership, revision and atomicity authority.
        final current = await programs.list();
        if (!context.mounted || !canWrite()) return false;
        if (current.map((p) => p.id).toSet().length != current.length ||
            current.any((p) => p.name.trim().isEmpty) ||
            !current.any((p) => p.id == sourceProgram.id)) {
          _show(context, 'Could not verify Programs. Refresh and try again.');
          return false;
        }
        attempted = true;
        final result = await createAndMove(
          target: target,
          newProgramId: proposed.id,
          newProgramName: proposed.name,
          mutationId: _newMutationId(),
        );
        // The atomic write may have committed before auth/widget changed.
        // Preserve the caller's refresh signal without showing old-user data.
        if (!context.mounted || !canWrite()) return attempted;
        if (result == RoutineMoveResult.confirmed) {
          _show(context, 'Routine moved.', confirmed: true);
        }
        return true;
      }
      if (chosen is! ProgramId) return false;
      Program? destination;
      for (final item in destinations) {
        if (item.id == chosen) {
          destination = item;
          break;
        }
      }
      if (destination == null || destination.id == target.sourceProgramId) {
        // Never trust an invented or stale destination ID from a modal.
        return false;
      }

      final confirmed = await _confirm(
        context: context,
        routineName: target.name,
        destination: destination,
        modalGuard: modalGuard,
      );
      if (confirmed != true || !context.mounted || !canWrite()) return false;
      // Preview must not reach the existing Program Move RPC either. False
      // means no write occurred and no success/refresh may be reported.
      if (previewOnly) {
        _show(context, 'Preview only. No Program or Routine was changed.');
        return false;
      }
      attempted = true;

      final result = await controller.dispatchConfirmed(
        selection: selection,
        destinationProgramId: destination.id,
        mutationId: _newMutationId(),
      );
      // The existing-Program RPC has the same post-dispatch uncertainty.
      if (!context.mounted || !canWrite()) return attempted;
      if (result == RoutineMoveResult.confirmed) {
        _show(context, 'Routine moved.', confirmed: true);
        return true;
      }
      return true;
    } on RoutineMoveOutcomeUnknown {
      if (attempted && context.mounted && canWrite()) {
        _show(context,
            'Move status is unconfirmed. Refresh Programs; do not retry.');
      }
      return attempted;
    } on RoutineMoveException catch (error) {
      if (!context.mounted || !canWrite()) return attempted;
      switch (error.kind) {
        case RoutineMoveFailureKind.unauthorized:
        case RoutineMoveFailureKind.forbidden:
          _show(context, 'Your session changed. Sign in again to move Routines.');
        case RoutineMoveFailureKind.inProgress:
          _show(context, 'Another Move is still in progress.');
        case RoutineMoveFailureKind.notFound:
        case RoutineMoveFailureKind.revisionConflict:
        case RoutineMoveFailureKind.mutationConflict:
        case RoutineMoveFailureKind.staleTarget:
          _show(context, 'This Routine changed. Refresh Programs and try again.');
        case RoutineMoveFailureKind.malformedData:
          _show(context, 'Could not verify Programs. Refresh and try again.');
        default:
          _show(context, 'Could not move this Routine. Try again later.');
      }
      return attempted;
    } catch (_) {
      if (context.mounted && canWrite()) {
        _show(context, 'Could not verify the Move. Try again later.');
      }
      return attempted;
    } finally {
      controller.abandon();
      _opening.remove(routine.id);
    }
  }

  Future<bool?> _confirm({
    required BuildContext context,
    required String routineName,
    required Program destination,
    Widget Function(BuildContext, Widget)? modalGuard,
    bool createProgram = false,
  }) => showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final card = Dialog(
        key: const ValueKey('routine-move-confirmation'),
        backgroundColor: TioPalette.transparent,
        elevation: TioElevation.none,
        insetPadding: const EdgeInsets.all(TioSpacing.lg),
        child: SizedBox(
          width: TioSize.dp320,
          child: SingleChildScrollView(
            child: TioCard(
              variant: TioCardVariant.elevated,
              padding: const EdgeInsets.all(TioSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      size: TioSize.dp24,
                      color: dialogContext.tioColors.textPrimary),
                  const SizedBox(height: TioSpacing.sm),
                  Text(createProgram
                      ? 'Create Program & Move Routine?' : 'Move Routine?',
                      style: Theme.of(dialogContext).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: TioSpacing.sm),
                  Text(createProgram
                      ? 'Create "${destination.name}" and move "$routineName"?'
                      : 'Move "$routineName" to "${destination.name}"?',
                      textAlign: TextAlign.center,
                      style: Theme.of(dialogContext).textTheme.bodyMedium),
                  const SizedBox(height: TioSpacing.lg),
                  Row(
                    children: [
                      Expanded(child: TioButton.secondary(
                        label: 'Cancel',
                        expand: true,
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                      )),
                      const SizedBox(width: TioSpacing.sm),
                      Expanded(child: TioButton.primary(
                        label: createProgram ? 'Create & Move' : 'Move',
                        expand: true,
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return modalGuard?.call(dialogContext, card) ?? card;
    },
  );

  void _show(BuildContext context, String message, {bool confirmed = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(
      key: confirmed ? const ValueKey('routine-move-confirmed-feedback') : null,
      duration: Duration(seconds: confirmed ? 5 : 4),
      behavior: confirmed ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      content: Text(message),
    ));
  }
}
