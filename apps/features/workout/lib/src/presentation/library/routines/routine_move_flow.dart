import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/repositories/program_repository.dart';
import '../../../domain/repositories/routine_move_repository.dart';

/// Feature-owned Move workflow shared by the two Routine card surfaces.
///
/// Returning true requests an owner-scoped list refresh, including an UNKNOWN
/// RPC outcome; it is not proof that the Move committed.
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
    Widget Function(BuildContext dialogContext, Widget content)? modalGuard,
  }) async {
    if (routine.programId != sourceProgram.id || !canWrite() ||
        !_opening.add(routine.id)) {
      return false;
    }

    var attempted = false;
    try {
      final target = await repository.inspect(
        sourceProgramId: sourceProgram.id,
        routineId: routine.id,
      );
      if (!context.mounted || !canWrite()) return false;
      if (target == null || target.routineId != routine.id ||
          target.sourceProgramId != sourceProgram.id) {
        _show(context, 'This Routine changed. Refresh the list.');
        return true;
      }

      // Only persisted Programs returned by the existing owner-scoped
      // repository can be selected. Do not infer My Program by display name.
      final owned = await programs.list();
      if (!context.mounted || !canWrite()) return false;
      if (owned.map((p) => p.id).toSet().length != owned.length) {
        _show(context, 'Could not verify Programs. Refresh and try again.');
        return false;
      }
      final destinations = [
        for (final program in owned)
          if (program.id != target.sourceProgramId) program,
      ];
      if (destinations.isEmpty) {
        _show(context, 'Create another Program before moving this Routine.');
        return false;
      }

      final chosen = await showTioEditorSheet<ProgramId>(
        context: context,
        useSafeArea: true,
        builder: (sheetContext) {
          final sheet = TioEditorSheet(
            key: ValueKey('routine-move-destinations-${routine.id.value}'),
            title: 'Move Routine',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select an existing destination Program'),
                const SizedBox(height: TioSpacing.sm),
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
      attempted = true;

      final result = await repository.move(
        target: target,
        destinationProgramId: destination.id,
        mutationId: _newMutationId(),
      );
      if (!context.mounted || !canWrite()) return false;
      if (result == RoutineMoveResult.confirmed) {
        _show(context, 'Routine moved.', confirmed: true);
        return true;
      }
      return true;
    } on RoutineMoveOutcomeUnknown {
      if (attempted && context.mounted && canWrite()) {
        _show(context,
            'Move status is unconfirmed. Refresh Programs; do not retry.');
        return true;
      }
      return false;
    } on RoutineMoveException catch (error) {
      if (!context.mounted || !canWrite()) return false;
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
        default:
          _show(context, 'Could not move this Routine. Try again later.');
      }
      return attempted;
    } catch (_) {
      if (context.mounted && canWrite()) {
        _show(context, 'Could not verify the Move. Try again later.');
      }
      return attempted && context.mounted && canWrite();
    } finally {
      _opening.remove(routine.id);
    }
  }

  Future<bool?> _confirm({
    required BuildContext context,
    required String routineName,
    required Program destination,
    Widget Function(BuildContext, Widget)? modalGuard,
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
                  Text('Move Routine?',
                      style: Theme.of(dialogContext).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: TioSpacing.sm),
                  Text('Move "$routineName" to "${destination.name}"?',
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
                        label: 'Move',
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
