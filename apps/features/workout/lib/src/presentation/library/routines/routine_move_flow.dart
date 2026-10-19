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
enum _MoveSheetAbort { stale, noDestinations }

typedef _MoveSheetChoice = ({
  RoutineMoveSelection selection,
  Object choice,
});

final class _MoveSheetError {
  const _MoveSheetError(this.error);
  final Object error;
}

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
      // Push the sheet immediately. The authenticated owner-scoped reads
      // continue inside its content; no destination is shown/selectable until
      // BOTH the Routine header and Program list pass controller validation.
      Future<({RoutineMoveSelection? selection, Object? error})>
          readSelection() async {
        try {
          return (
            selection: await controller.inspect(
              sourceProgramId: sourceProgram.id,
              routineId: routine.id,
            ),
            error: null,
          );
        } catch (error) {
          // A canceled sheet must never leave an unhandled read failure.
          return (selection: null, error: error);
        }
      }

      final inspection = readSelection();
      var dismissalScheduled = false;
      final picked = await showTioEditorSheet<Object>(
        context: context,
        useSafeArea: true,
        builder: (sheetContext) {
          // Match the previous fail-closed snackbar/refetch semantics after
          // an invalid/failed read, without leaving a stuck empty picker.
          void dismissAfterFrame(Object reason) {
            if (dismissalScheduled) return;
            dismissalScheduled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // A stale async read must never pop the screen *under* an
              // already-dismissed selector or a newly opened modal.
              if (sheetContext.mounted &&
                  ModalRoute.of(sheetContext)?.isCurrent == true) {
                Navigator.of(sheetContext).pop(reason);
              }
            });
          }

          final sheet = TioEditorSheet(
            key: ValueKey('routine-move-destinations-${routine.id.value}'),
            title: 'Select Program',
            content: FutureBuilder<
                ({RoutineMoveSelection? selection, Object? error})>(
              future: inspection,
              builder: (bodyContext, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    key: ValueKey('routine-move-destinations-loading'),
                    height: TioSize.dp48,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final error = snapshot.data?.error;
                if (error != null) {
                  dismissAfterFrame(_MoveSheetError(error));
                  return const SizedBox.shrink();
                }
                if (!canWrite()) return const SizedBox.shrink();
                final selection = snapshot.data?.selection;
                if (selection == null ||
                    selection.target.routineId != routine.id ||
                    selection.target.sourceProgramId != sourceProgram.id) {
                  dismissAfterFrame(_MoveSheetAbort.stale);
                  return const SizedBox.shrink();
                }

                // Keep all eligibility and owner validation in the
                // controller: the UI only renders its verified snapshot.
                final destinations = selection.destinations;
                if (destinations.isEmpty && createAndMove == null) {
                  dismissAfterFrame(_MoveSheetAbort.noDestinations);
                  return const SizedBox.shrink();
                }

                void choose(Object choice) {
                  if (!canWrite()) return;
                  final _MoveSheetChoice result =
                      (selection: selection, choice: choice);
                  Navigator.of(sheetContext).pop(result);
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (createAndMove != null)
                      ListTile(
                        key: const ValueKey('routine-move-new-program'),
                        title: const Text('New Program'),
                        leading: const Icon(Icons.add_rounded),
                        onTap: () => choose(_MoveDestinationChoice.newProgram),
                      ),
                    if (createAndMove != null && destinations.isNotEmpty)
                      const Divider(
                        key: ValueKey('routine-move-program-divider'),
                      ),
                    for (final program in destinations)
                      ListTile(
                        key: ValueKey(
                            'routine-move-destination-${program.id.value}'),
                        title: Text(program.name, maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => choose(program.id),
                      ),
                  ],
                );
              },
            ),
          );
          return modalGuard?.call(sheetContext, sheet) ?? sheet;
        },
      );

      if (!context.mounted || !canWrite()) return false;
      if (picked is _MoveSheetError) throw picked.error;
      if (picked == _MoveSheetAbort.stale) {
        _show(context, 'This Routine changed. Refresh the list.');
        return true;
      }
      if (picked == _MoveSheetAbort.noDestinations) {
        _show(context, 'Create another Program before moving this Routine.');
        return false;
      }
      if (picked is! _MoveSheetChoice) return false;
      final selection = picked.selection;
      final chosen = picked.choice;
      final target = selection.target;
      final destinations = selection.destinations;
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
          _show(context, 'Preview only · No changes', preview: true);
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
        _show(context, 'Preview only · No changes', preview: true);
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
      // The original write may have committed despite a lost response.
      // Only the optional same-cycle read-only mutation receipt can confirm
      // that exact request. Never replay either Move RPC or infer success
      // from destination membership / a later unrelated mutation.
      var confirmedByReadback = false;
      if (attempted && context.mounted && canWrite() &&
          repository is RoutineMoveUnknownVerifier) {
        try {
          final readback = await repository.verifyUnknown(
            routineId: routine.id,
          );
          confirmedByReadback =
              readback.kind == RoutineMoveReadbackKind.confirmedLatestMutation;
        } catch (_) {
          // A failed, unsupported or stale-session read is not a receipt.
          // Retain the original UNKNOWN message and caller refresh signal.
        }
      }
      // A read may complete after widget disposal or account/cycle switch.
      if (attempted && context.mounted && canWrite()) {
        if (confirmedByReadback) {
          _show(context, 'Routine moved.', confirmed: true);
        } else {
          _show(context,
              'Move status is unconfirmed. Refresh Programs; do not retry.');
        }
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
      final theme = Theme.of(dialogContext);
      // Only this confirmation card uses the owner-approved compact visual
      // button height. Preserve Core button intent, colours, radius and padded
      // accessible tap target; global TioButtonTokens.height stays 46dp.
      const compactMinimum = WidgetStatePropertyAll<Size>(
        Size(TioButtonTokens.minimumWidth, TioSize.dp42),
      );
      final compactButtonsTheme = theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: theme.filledButtonTheme.style?.copyWith(
            minimumSize: compactMinimum,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: theme.outlinedButtonTheme.style?.copyWith(
            minimumSize: compactMinimum,
          ),
        ),
      );
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
                  Theme(
                    data: compactButtonsTheme,
                    child: Row(
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

  void _show(BuildContext context, String message, {
    bool confirmed = false,
    bool preview = false,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    // Match the existing Delete feedback pill. Preview is an explicit
    // no-write state; its Undo action only dismisses the visual preview.
    // A real reverse Move needs its own protected server-side contract.
    final pill = confirmed || preview;
    messenger?.showSnackBar(SnackBar(
      key: confirmed
          ? const ValueKey('routine-move-confirmed-feedback')
          : preview
              ? const ValueKey('routine-move-preview-feedback')
              : null,
      duration: Duration(seconds: pill ? 5 : 4),
      // Snackbar actions persist by default on current Flutter. Preview must
      // still close after five seconds even when Undo is not pressed.
      persist: preview ? false : null,
      behavior: pill ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      shape: pill ? const StadiumBorder() : null,
      content: pill
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  confirmed
                      ? Icons.swap_horiz_rounded
                      : Icons.visibility_outlined,
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
                const SizedBox(width: TioSpacing.sm),
                Flexible(child: Text(message)),
              ],
            )
          : Text(message),
      action: preview
          ? SnackBarAction(
              label: 'Undo',
              // A filled contrasting action capsule inside the dark floating
              // pill; all colours are from the active Material colour scheme.
              backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
              textColor: Theme.of(context).colorScheme.inverseSurface,
              onPressed: () => messenger.hideCurrentSnackBar(),
            )
          : null,
    ));
  }
}
