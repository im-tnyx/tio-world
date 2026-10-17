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
    Widget Function(BuildContext dialogContext, Widget content)? confirmationGuard,
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
      final confirmed = await _showRoutineDeleteDialog(
        context: context,
        routineId: routine.id,
        routineName: target.name,
        confirmationGuard: confirmationGuard,
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

/// A one-off Routine Delete confirmation surface: only the placement and
/// compact visual geometry differ from the shared Core bottom-sheet presenter.
/// All colours, card styling and button intent remain Core-owned.
Future<bool?> _showRoutineDeleteDialog({
  required BuildContext context,
  required RoutineId routineId,
  required String routineName,
  Widget Function(BuildContext dialogContext, Widget content)? confirmationGuard,
}) => showDialog<bool>(
  context: context,
  builder: (dialogContext) {
    final theme = Theme.of(dialogContext);
    final colors = dialogContext.tioColors;
    // Locally reduce ONLY this confirmation's visual button minimum.
    // The themed padded Material tap target and text scaling are retained.
    const compactMinSize = WidgetStatePropertyAll<Size>(
      Size(TioButtonTokens.minimumWidth, TioSize.dp38),
    );
    final compactTheme = theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
          minimumSize: compactMinSize,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (theme.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          minimumSize: compactMinSize,
        ),
      ),
    );

    final dialog = Dialog(
      key: ValueKey('confirm-delete-routine-${routineId.value}'),
      backgroundColor: TioPalette.transparent,
      elevation: TioElevation.none,
      insetPadding: const EdgeInsets.all(TioSpacing.lg),
      // Tight visual width rather than an internal max-width only: Dialog's
      // own measured surface must be compact, not the entire viewport.
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
                  'Delete Routine?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
                const SizedBox(height: TioSpacing.sm),
                Text(
                  'Delete "$routineName" and its saved Exercises and Sets? '
                      'This cannot be undone.',
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
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          expand: true,
                        ),
                      ),
                      const SizedBox(width: TioSpacing.sm),
                      Expanded(
                        child: TioButton.destructive(
                          label: 'Delete',
                          onPressed: () => Navigator.of(dialogContext).pop(true),
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
    // The app composition may watch the live owner/login cycle around this
    // modal and synchronously redact its private content on revocation.
    return confirmationGuard?.call(dialogContext, dialog) ?? dialog;
  },
);
