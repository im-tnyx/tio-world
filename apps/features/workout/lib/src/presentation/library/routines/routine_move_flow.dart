import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/repositories/program_repository.dart';
import '../../../domain/repositories/routine_move_repository.dart';
import 'routine_move_destination_controller.dart';
import '../programs/programs_controller.dart';
import '../programs/programs_surface.dart';
/// Frozen receipt from a server-confirmed existing-Program Move.
/// Provides exactly the identity needed to dispatch a protected reverse Move.
/// Never carries credentials; login-cycle is re-validated at Undo dispatch.
final class _MoveUndoReceipt {
  const _MoveUndoReceipt({
    required this.routineId,
    required this.routineName,
    required this.originalProgramId,
    required this.originalProgramName,
    required this.destinationProgramId,
    required this.postMoveRevision,
    required this.ownerId,
    required this.loginCycleId,
  });

  /// The moved Routine; must match the server record at Undo time.
  final RoutineId routineId;
  final String routineName;

  /// Program A — where the Routine was before the Move.
  final ProgramId originalProgramId;
  final String originalProgramName;

  /// Program B — where the Routine currently resides after the confirmed Move.
  final ProgramId destinationProgramId;

  /// expectedRevision + 1 from the confirmed Move RPC response.
  /// A fresh inspect at Undo time must observe exactly this revision; any
  /// higher revision means an intervening write has occurred and Undo is unsafe.
  final int postMoveRevision;

  /// Frozen owner/cycle. A new login invalidates Undo silently; never use
  /// stale identity to dispatch a reverse Move under a different session.
  final String ownerId;
  final String loginCycleId;
}

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
    /// Called after a server-confirmed existing-Program Move and again after a
    /// server-confirmed Undo. Not called for Create & Move, UNKNOWN outcomes,
    /// or Undo failures. The caller must guard with its own owner/session check.
    VoidCallback? onMoveConfirmed,
    /// Called when an existing-Program Undo reverse Move write was dispatched
    /// across the network (including confirmed, UNKNOWN outcome, or post-dispatch
    /// exceptions).
    /// Used by the caller to invalidate and reconcile owner-scoped Program and
    /// Routine lists without treating the signal as confirmed success.
    /// Never called if target inspection fails or the request is rejected before dispatch.
    VoidCallback? onUndoWriteAttempted,
    /// Stable identity predicate for post-dispatch feedback and callbacks:
    /// returns true if the current authenticated owner and login cycle match
    /// the session that initiated the flow.
    /// When omitted, falls back to [canWrite].
    bool Function()? sameAuthenticatedOwner,
  }) async {
    if (routine.programId != sourceProgram.id || !canWrite() ||
        !_opening.add(routine.id)) {
      return false;
    }

    final controller = RoutineMoveDestinationController(
      moves: repository, programs: programs, canWrite: canWrite,
    );
    var attempted = false;
    String? dispatchedMutationId;
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
                  if (!canWrite()) {
                    Navigator.of(sheetContext).pop();
                    return;
                  }
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
        // Preview is a real owner-scoped, read-only UI flow. Never create a
        // Program or send the atomic Create+Move command even after submit.
        if (previewOnly) {
          _show(context, 'Preview only · No changes', preview: true);
          return false;
        }

        // Re-check the owner-scoped source after the name sheet; server CAS
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
        final mutationId = _newMutationId();
        dispatchedMutationId = mutationId;
        final result = await createAndMove(
          target: target,
          newProgramId: proposed.id,
          newProgramName: proposed.name,
          mutationId: mutationId,
        );
        // The atomic write may have committed before auth/widget changed.
        // Preserve the caller's refresh signal without showing old-user data.
        if (!context.mounted || !(sameAuthenticatedOwner ?? canWrite)()) {
          return attempted;
        }
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

      // Preview must not reach the existing Program Move RPC either. False
      // means no write occurred and no success/refresh may be reported.
      if (previewOnly) {
        _show(context, 'Preview only · No changes', preview: true);
        return false;
      }
      attempted = true;
      final mutationId = _newMutationId();
      dispatchedMutationId = mutationId;

      final result = await controller.dispatchConfirmed(
        selection: selection,
        destinationProgramId: destination.id,
        mutationId: mutationId,
      );
      // The existing-Program RPC has the same post-dispatch uncertainty.
      if (!context.mounted || !(sameAuthenticatedOwner ?? canWrite)()) {
        return attempted;
      }
      if (result == RoutineMoveResult.confirmed) {
        final receipt = _MoveUndoReceipt(
          routineId: routine.id,
          routineName: routine.name,
          originalProgramId: target.sourceProgramId,
          originalProgramName: sourceProgram.name,
          destinationProgramId: destination.id,
          postMoveRevision: target.expectedRevision + 1,
          ownerId: target.ownerId,
          loginCycleId: target.loginCycleId,
        );
        _showConfirmedWithUndo(
          context,
          'Moved to ${destination.name}',
          receipt: receipt,
          programs: programs,
          repository: repository,
          canWrite: canWrite,
          sameAuthenticatedOwner: sameAuthenticatedOwner,
          onMoveConfirmed: onMoveConfirmed,
          onUndoWriteAttempted: onUndoWriteAttempted,
        );
        return true;
      }
      return true;
    } on RoutineMoveOutcomeUnknown {
      // The original write may have committed despite a lost response.
      // Only the optional same-cycle read-only mutation receipt can confirm
      // that exact request. Never replay either Move RPC or infer success
      // from destination membership / a later unrelated mutation.
      var confirmedByReadback = false;
      final tokenToVerify = dispatchedMutationId;
      if (attempted && tokenToVerify != null &&
          context.mounted && canWrite() &&
          repository is RoutineMoveUnknownVerifier) {
        try {
          final readback = await (repository as RoutineMoveUnknownVerifier)
              .verifyUnknown(
            routineId: routine.id, mutationId: tokenToVerify,
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

  /// Shows a floating Undo pill after a server-confirmed existing-Program Move.
  /// The pill auto-dismisses after 5 seconds even if the Undo action is visible.
  /// Tapping Undo dispatches [_executeUndo] exactly once.
  void _showConfirmedWithUndo(
    BuildContext context,
    String message, {
    required _MoveUndoReceipt receipt,
    required ProgramRepository programs,
    required RoutineMoveRepository repository,
    required bool Function() canWrite,
    bool Function()? sameAuthenticatedOwner,
    VoidCallback? onMoveConfirmed,
    VoidCallback? onUndoWriteAttempted,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();

    var undoTapped = false;

    final colors = Theme.of(context).colorScheme;
    messenger.showSnackBar(SnackBar(
      key: const ValueKey('routine-move-confirmed-feedback'),
      duration: const Duration(seconds: 5),
      // Auto-dismiss even when the Undo action is present.
      persist: false,
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            color: colors.onInverseSurface,
          ),
          const SizedBox(width: TioSpacing.sm),
          Flexible(child: Text(message)),
        ],
      ),
      action: SnackBarAction(
        label: 'Undo',
        backgroundColor: colors.onInverseSurface,
        textColor: colors.inverseSurface,
        onPressed: () {
          if (undoTapped) return;
          undoTapped = true;
          if (!canWrite()) return;
          messenger.hideCurrentSnackBar();
          if (context.mounted) {
            _executeUndo(
              context,
              receipt: receipt,
              programs: programs,
              repository: repository,
              canWrite: canWrite,
              sameAuthenticatedOwner: sameAuthenticatedOwner,
              onMoveConfirmed: onMoveConfirmed,
              onUndoWriteAttempted: onUndoWriteAttempted,
            );
          }
        },
      ),
    ));
  }

  /// Dispatches a reverse (Undo) Move from destination back to the original
  /// source Program using repository.inspect() + repository.move().
  Future<void> _executeUndo(
    BuildContext context, {
    required _MoveUndoReceipt receipt,
    required ProgramRepository programs,
    required RoutineMoveRepository repository,
    required bool Function() canWrite,
    bool Function()? sameAuthenticatedOwner,
    VoidCallback? onMoveConfirmed,
    VoidCallback? onUndoWriteAttempted,
  }) async {
    // 1. Strict new mutation eligibility check before inspection.
    if (!canWrite()) return;

    RoutineMoveTarget? target;
    try {
      target = await repository.inspect(
        sourceProgramId: receipt.destinationProgramId,
        routineId: receipt.routineId,
      );
    } catch (_) {
      if (context.mounted && (sameAuthenticatedOwner ?? canWrite)()) {
        _show(context, 'Could not restore. Check your Programs.');
      }
      return;
    }

    // 2. Strict new mutation eligibility check before reverse move dispatch.
    if (!context.mounted || !canWrite()) return;

    // Validate the inspected target for safe Undo:
    if (target == null ||
        target.ownerId != receipt.ownerId ||
        target.loginCycleId != receipt.loginCycleId ||
        target.expectedRevision != receipt.postMoveRevision ||
        target.sourceProgramId != receipt.destinationProgramId) {
      // An intervening write occurred or the session changed — Undo is unsafe.
      if (context.mounted && (sameAuthenticatedOwner ?? canWrite)()) {
        _show(context, 'Could not restore. Check your Programs.');
      }
      return;
    }

    // 3. Post-dispatch UI feedback eligibility:
    // Requires mounted context AND stable same authenticated owner + login cycle.
    // When sameAuthenticatedOwner is omitted, falls back to canWrite().
    // Mutable new-write eligibility (pending Create / QA toggle) does NOT suppress
    // feedback for an already-dispatched mutation as long as the session identity matches.
    bool canPresentFeedback() =>
        context.mounted && (sameAuthenticatedOwner ?? canWrite)();

    var reverseWriteAttempted = false;
    RoutineMoveResult? result;
    try {
      reverseWriteAttempted = true;
      result = await repository.move(
        target: target,
        destinationProgramId: receipt.originalProgramId,
        mutationId: _newMutationId(),
      );
    } on RoutineMoveOutcomeUnknown {
      if (context.mounted && canPresentFeedback()) {
        _show(
          context,
          'Restore status unconfirmed. Check your Programs.',
        );
      }
    } on RoutineMoveException {
      if (context.mounted && canPresentFeedback()) {
        _show(context, 'Could not restore. Check your Programs.');
      }
    } catch (_) {
      if (context.mounted && canPresentFeedback()) {
        _show(context, 'Could not restore. Try again later.');
      }
    } finally {
      // The reverse write was dispatched across the network and may have
      // committed on the server. Signal the caller to invalidate and re-read
      // owner-scoped state (without interpreting this signal as confirmed success).
      // Decouple post-dispatch reconciliation from mutable new-write eligibility
      // (e.g. pending-create in source program or QA toggle change).
      // The reconciliation callback is invoked whenever the reverse write was
      // attempted; the caller verifies frozen owner and login-cycle identity
      // before requesting refresh, preventing cross-owner invalidation.
      if (reverseWriteAttempted) {
        onUndoWriteAttempted?.call();
      }
    }

    if (!context.mounted || !canPresentFeedback()) return;

    if (result == RoutineMoveResult.confirmed) {
      _show(context, 'Restored to ${receipt.originalProgramName}');
      onMoveConfirmed?.call();
    } else if (result != null) {
      _show(context, 'Could not restore. Check your Programs.');
    }
  }

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
