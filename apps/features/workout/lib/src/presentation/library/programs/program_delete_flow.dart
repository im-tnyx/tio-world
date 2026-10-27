import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/repositories/program_delete_repository.dart';
import 'program_delete_controller.dart';

/// Explanatory message that clarifies what happens to saved Routines on deletion.
String programDeleteExplanation({
  required String programName,
  required int? routineCount,
}) {
  if (routineCount == null) {
    return 'Delete "$programName"? Any saved Routines will be moved to My Program. '
        'This cannot be undone.';
  }
  if (routineCount == 0) {
    return 'Delete "$programName"? This Program has no saved Routines. '
        'This cannot be undone.';
  }
  if (routineCount == 1) {
    return 'Delete "$programName"? Its 1 saved Routine will be moved to My Program. '
        'This cannot be undone.';
  }
  return 'Delete "$programName"? All $routineCount saved Routines will be moved to My Program. '
      'This cannot be undone.';
}

/// A compact, centered confirmation dialog for Program deletion.
///
/// Follows the design-system tokens and matches the Routine Delete confirmation UI.
Future<bool?> showProgramDeleteDialog({
  required BuildContext context,
  required ProgramId programId,
  required String programName,
  int? routineCount,
  Widget Function(BuildContext dialogContext, Widget content)?
      confirmationGuard,
}) =>
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colors = dialogContext.tioColors;
        const compactMinSize = WidgetStatePropertyAll<Size>(
          Size(TioButtonTokens.minimumWidth, TioSize.dp38),
        );
        final compactTheme = theme.copyWith(
          filledButtonTheme: FilledButtonThemeData(
            style:
                (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
              minimumSize: compactMinSize,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: (theme.outlinedButtonTheme.style ?? const ButtonStyle())
                .copyWith(
              minimumSize: compactMinSize,
            ),
          ),
        );

        final dialog = Dialog(
          key: ValueKey('confirm-delete-program-${programId.value}'),
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
                    Icon(
                      Icons.delete_outline_rounded,
                      size: TioSize.dp24,
                      color: colors.danger,
                    ),
                    const SizedBox(height: TioSpacing.sm),
                    Text(
                      'Delete Program?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.sm),
                    Text(
                      programDeleteExplanation(
                        programName: programName,
                        routineCount: routineCount,
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: TioLineHeight.height140,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.lg),
                    Theme(
                      data: compactTheme,
                      child: Row(
                        children: [
                          Expanded(
                            child: TioButton.secondary(
                              label: 'Cancel',
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              expand: true,
                            ),
                          ),
                          const SizedBox(width: TioSpacing.sm),
                          Expanded(
                            child: TioButton.destructive(
                              label: 'Delete',
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              expand: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        return confirmationGuard?.call(dialogContext, dialog) ?? dialog;
      },
    );

/// Feature-owned confirmation workflow for deleting a non-default Program.
///
/// Keeps Program Delete lifecycle and UI presentation decoupled from the app shell.
/// Remained dormant until server capabilities and authorizations are deployed.
final class ProgramDeleteFlow {
  ProgramDeleteFlow({
    String Function()? newMutationId,
  }) : _newMutationId = newMutationId ?? _uuidV4;

  final String Function() _newMutationId;
  static String _uuidV4() => const Uuid().v4();

  ProgramId? _activeProgramId;

  /// Runs the owner-scoped Program Delete flow.
  ///
  /// Returns `true` if an operation was confirmed or uncertain (meaning
  /// the caller should ensure views are refreshed or aware).
  /// Returns `false` on cancellation, dismissal, or definite rejection before RPC dispatch.
  Future<bool> run({
    required BuildContext context,
    required Program program,
    required ProgramDeleteController controller,
    required bool Function() canWrite,
    Widget Function(BuildContext dialogContext, Widget content)?
        confirmationGuard,
  }) async {
    // Canonical default My Program must NEVER be deleted.
    if (program.isDefault) {
      if (context.mounted && canWrite()) {
        _show(context, 'The default Program cannot be deleted.');
      }
      return false;
    }

    if (!canWrite() || _activeProgramId != null) {
      return false;
    }
    _activeProgramId = program.id;

    var attempted = false;
    try {
      final prepared = await controller.prepare(program.id);
      if (!context.mounted || !canWrite()) return false;

      if (!prepared) {
        final failure = controller.state.failure;
        if (failure != null) {
          _showFailure(context, failure.kind);
          return false;
        }
        if (controller.state.status == ProgramDeleteOperationStatus.confirmed) {
          _show(context, 'This Program was already deleted. Refresh the list.');
          return true;
        }
        if (controller.state.status == ProgramDeleteOperationStatus.unknown) {
          _show(
            context,
            'Delete status is unconfirmed. Checking your Programs; do not retry.',
          );
          return true;
        }
        _show(
            context, 'Could not verify this Program. Please try again later.');
        return false;
      }

      final preparedProgram = controller.state.program;
      final target = controller.state.target;
      if (preparedProgram == null ||
          preparedProgram.id != program.id ||
          target == null ||
          target.sourceProgramId != program.id) {
        _show(context,
            'This Program changed. Refresh the list before trying again.');
        return false;
      }

      final routineCount = target.expectedRoutineIds.length;

      final confirmed = await showProgramDeleteDialog(
        context: context,
        programId: program.id,
        programName: preparedProgram.name,
        routineCount: routineCount,
        confirmationGuard: confirmationGuard,
      );

      if (confirmed != true || !context.mounted || !canWrite()) {
        return false;
      }

      // Verify that controller state is still ready for this exact captured target.
      // Another preparation for the same or different Program must never cause dispatch
      // with a replaced Routine membership snapshot.
      final currentTarget = controller.state.target;
      if (controller.state.status != ProgramDeleteOperationStatus.ready ||
          currentTarget == null ||
          currentTarget.sourceProgramId != target.sourceProgramId ||
          !listEquals(
            currentTarget.expectedRoutineIds,
            target.expectedRoutineIds,
          ) ||
          !identical(currentTarget, target)) {
        _show(context,
            'This Program changed. Refresh the list before trying again.');
        return false;
      }

      attempted = true;
      final mutationId = _newMutationId();
      final endState = await controller.confirm(clientMutationId: mutationId);
      if (!context.mounted || !canWrite()) return false;

      switch (endState.status) {
        case ProgramDeleteOperationStatus.confirmed:
          _show(context, 'Program deleted.', confirmed: true);
          return true;
        case ProgramDeleteOperationStatus.unknown:
          _show(
            context,
            'Delete status is unconfirmed. Checking your Programs; do not retry.',
          );
          return true;
        case ProgramDeleteOperationStatus.definitelyRejected:
          if (endState.failure != null) {
            _showFailure(context, endState.failure!.kind);
          } else {
            _show(context,
                'Could not delete this Program. Please try again later.');
          }
          return attempted;
        default:
          return attempted;
      }
    } catch (_) {
      if (context.mounted && canWrite()) {
        _show(
            context, 'Could not delete this Program. Please try again later.');
      }
      return attempted && context.mounted && canWrite();
    } finally {
      if (_activeProgramId == program.id) {
        _activeProgramId = null;
      }
    }
  }

  void _showFailure(BuildContext context, ProgramDeleteFailureKind kind) {
    switch (kind) {
      case ProgramDeleteFailureKind.unauthorized:
        _show(
            context, 'Your session changed. Sign in again to manage Programs.');
      case ProgramDeleteFailureKind.defaultProtected:
        _show(context, 'The default Program cannot be deleted.');
      case ProgramDeleteFailureKind.inProgress:
        _show(context, 'Another Program operation is still in progress.');
      case ProgramDeleteFailureKind.staleMembership:
      case ProgramDeleteFailureKind.notFound:
        _show(context,
            'This Program changed. Refresh the list before trying again.');
      default:
        _show(
            context, 'Could not delete this Program. Please try again later.');
    }
  }

  void _show(BuildContext context, String message, {bool confirmed = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        key: confirmed
            ? const ValueKey('program-delete-confirmed-feedback')
            : null,
        duration:
            confirmed ? const Duration(seconds: 5) : const Duration(seconds: 4),
        behavior:
            confirmed ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        shape: confirmed ? const StadiumBorder() : null,
        content: confirmed
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Flexible(child: Text(message)),
                ],
              )
            : Text(message),
      ),
    );
  }
}
