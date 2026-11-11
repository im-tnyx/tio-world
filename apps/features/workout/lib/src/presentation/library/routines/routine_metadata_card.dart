import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

/// One canonical Program-owned Routine card, reused in Program Detail and
/// expanded Library. The option sheet only dispatches real owner capabilities.
class RoutineMetadataCard extends StatefulWidget {
  const RoutineMetadataCard({
    required this.routine,
    super.key,
    this.supportingText,
    this.onTap,
    this.onStartRoutinePressed,
    this.onEdit,
    this.onMove,
    this.onDelete,
    this.actionSheetGuard,
    this.actionsEnabled = true,
    this.startEnabled = true,
  });

  final Routine routine;
  final String? supportingText;
  final VoidCallback? onTap;

  /// The caller supplies a current owner/session-verified start capability.
  final Future<void> Function()? onStartRoutinePressed;

  /// The caller must supply only live, owner-verified capabilities.
  final VoidCallback? onEdit;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

  /// Keep action geometry while a same-owner verification read is in flight.
  /// Only the action menu is disabled; read-only Routine navigation remains.
  final bool actionsEnabled;

  /// Keeps the play affordance visible while a Routine list refreshes.
  final bool startEnabled;

  /// Optional app-owned auth-cycle guard for the separate options modal.
  /// Sheet ownership remains here; account identity never enters Workout.
  final Widget Function(BuildContext, Widget)? actionSheetGuard;

  @override
  State<RoutineMetadataCard> createState() => _RoutineMetadataCardState();
}

class _RoutineMetadataCardState extends State<RoutineMetadataCard> {
  bool _openingActions = false;
  bool _startingRoutine = false;

  @override
  void didUpdateWidget(covariant RoutineMetadataCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routine.id != widget.routine.id ||
        oldWidget.routine.programId != widget.routine.programId) {
      _startingRoutine = false;
    }
  }

  Future<void> _startRoutine() async {
    final start = widget.onStartRoutinePressed;
    if (_startingRoutine || !widget.startEnabled || start == null) return;
    final openingId = widget.routine.id;
    final openingProgramId = widget.routine.programId;
    setState(() => _startingRoutine = true);
    try {
      await start();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Could not start this Routine. Please try again.'),
        ),
      );
    } finally {
      if (mounted &&
          widget.routine.id == openingId &&
          widget.routine.programId == openingProgramId) {
        setState(() => _startingRoutine = false);
      }
    }
  }

  Future<void> _openActions() async {
    if (_openingActions || !widget.actionsEnabled) return;
    final openingId = widget.routine.id;
    final openingProgramId = widget.routine.programId;
    _openingActions = true;
    try {
      // Match the canonical Select Set Type picker: one Core editor sheet
      // owns its accessible drag handle, header, viewport and insets.
      // The outlined option surfaces retain the exact Set Type dimensions.
      final selected = await showTioEditorSheet<_RoutineAction>(
        context: context,
        useSafeArea: true,
        builder: (sheetContext) {
          final sheet = TioEditorSheet(
            key: ValueKey('routine-actions-sheet-${openingId.value}'),
            title: widget.routine.name,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onEdit != null) ...[
                  _RoutineActionOption(
                    key: ValueKey('routine-edit-${openingId.value}'),
                    label: 'Edit Routine',
                    icon: Icons.edit_outlined,
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_RoutineAction.edit),
                  ),
                  const SizedBox(height: TioSpacing.sm),
                ],
                if (widget.onMove != null) ...[
                  _RoutineActionOption(
                    key: ValueKey('routine-move-${openingId.value}'),
                    label: 'Move Routine',
                    icon: Icons.swap_horiz_rounded,
                    onTap: () {
                      // Begin the owner-guarded destination read while this
                      // sheet animates out, rather than waiting for its reverse
                      // transition and then starting network I/O. The app
                      // callback still rechecks live Auth and Routine ownership.
                      Navigator.of(sheetContext).pop(_RoutineAction.move);
                      if (mounted &&
                          widget.actionsEnabled &&
                          widget.routine.id == openingId &&
                          widget.routine.programId == openingProgramId) {
                        widget.onMove?.call();
                      }
                    },
                  ),
                  const SizedBox(height: TioSpacing.sm),
                ],
                if (widget.onDelete != null)
                  _RoutineActionOption(
                    key: ValueKey('routine-delete-${openingId.value}'),
                    label: 'Delete Routine',
                    icon: Icons.delete_outline,
                    destructive: true,
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_RoutineAction.delete),
                  ),
              ],
            ),
          );
          return widget.actionSheetGuard?.call(sheetContext, sheet) ?? sheet;
        },
      );

      // The sheet can outlive a parent rebuild, session transition or a card
      // reassignment. Dispatch through the CURRENT widget, not callbacks
      // captured before the await. Keep this a presentation-only boundary:
      // the app shell independently rechecks the owner and login cycle.
      if (!mounted ||
          !widget.actionsEnabled ||
          widget.routine.id != openingId ||
          widget.routine.programId != openingProgramId) {
        return;
      }
      switch (selected) {
        case _RoutineAction.edit:
          widget.onEdit?.call();
        case _RoutineAction.move:
          // Already begun at the user's tap, during sheet dismissal.
          // Do not dispatch a second Move after the reverse animation.
          break;
        case _RoutineAction.delete:
          widget.onDelete?.call();
        case null:
          break;
      }
    } finally {
      _openingActions = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioCard(
      onTap: widget.onTap,
      // Keep the leading inset. The menu sits on the card's trailing edge.
      padding: const EdgeInsetsDirectional.fromSTEB(
        TioSpacing.lg,
        TioSpacing.lg,
        TioSpacing.xs,
        TioSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center_outlined, color: colors.textSecondary),
          const SizedBox(width: TioSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.routine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: TioFontSize.size15,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
                if (widget.supportingText != null)
                  Text(
                    widget.supportingText!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size12,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.onStartRoutinePressed != null) ...[
            Semantics(
              key: ValueKey('routine-start-${widget.routine.id.value}'),
              container: true,
              button: true,
              enabled: widget.startEnabled && !_startingRoutine,
              label: _startingRoutine
                  ? 'Starting ${widget.routine.name}'
                  : 'Start ${widget.routine.name}',
              onTap: widget.startEnabled && !_startingRoutine
                  ? _startRoutine
                  : null,
              child: ExcludeSemantics(
                child: GestureDetector(
                  // Keep a disabled child target from activating the card.
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.startEnabled && !_startingRoutine
                      ? _startRoutine
                      : () {},
                  child: IconButton(
                    key: ValueKey(
                      'routine-start-button-${widget.routine.id.value}',
                    ),
                    tooltip: 'Start Routine',
                    onPressed: widget.startEnabled && !_startingRoutine
                        ? _startRoutine
                        : null,
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      foregroundColor: colors.primary,
                      disabledForegroundColor: colors.textSecondary,
                      shape: const CircleBorder(),
                      side: BorderSide(
                        color: widget.startEnabled && !_startingRoutine
                            ? colors.primary
                            : colors.outlineStrong,
                        width: TioStroke.width2,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(TioSize.dp56, TioSize.dp56),
                      fixedSize: const Size(TioSize.dp56, TioSize.dp56),
                    ),
                    icon: _startingRoutine
                        ? const SizedBox(
                            width: TioSize.dp16,
                            height: TioSize.dp16,
                            child: CircularProgressIndicator(
                              strokeWidth: TioStroke.width2,
                            ),
                          )
                        : const Icon(
                            Icons.play_arrow_rounded,
                            size: TioSize.dp32,
                          ),
                  ),
                ),
              ),
            ),
            if (widget.onEdit != null ||
                widget.onMove != null ||
                widget.onDelete != null)
              const SizedBox(width: TioSpacing.xs),
          ],
          if (widget.onEdit != null ||
              widget.onMove != null ||
              widget.onDelete != null)
            Semantics(
              key: ValueKey('routine-menu-${widget.routine.id.value}'),
              // Keep overflow independently focusable from the card's
              // primary navigation tap, with one semantic tap target.
              container: true,
              button: true,
              enabled: widget.actionsEnabled,
              label: 'Routine options',
              onTap: widget.actionsEnabled ? _openActions : null,
              child: ExcludeSemantics(
                child: GestureDetector(
                  // Keep a child tap recognizer during refresh so the
                  // disabled overflow press cannot reach the parent card.
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.actionsEnabled ? _openActions : () {},
                  child: IconButton(
                    tooltip: 'Routine options',
                    onPressed: widget.actionsEnabled ? _openActions : null,
                    // The 32dp target stays on the card's trailing edge.
                    // Center the mark so the press highlight surrounds it.
                    alignment: Alignment.center,
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      fixedSize: const Size(TioSize.dp32, TioSize.dp32),
                      alignment: Alignment.center,
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: TioSize.dp32,
                      height: TioSize.dp32,
                    ),
                    icon: SizedBox(
                      width: TioSize.dp16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Match the Program more_horiz glyph ink (16.03dp
                          // inside the default 24dp icon). Bottom stays
                          // shorter. Both bars keep physical right edges.
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: TioSize.dp16,
                              height: TioStroke.width2,
                              decoration: BoxDecoration(
                                color: colors.textPrimary,
                                borderRadius:
                                    BorderRadius.circular(TioRadius.full),
                              ),
                            ),
                          ),
                          const SizedBox(height: TioSpacing.xs),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: TioSize.dp10,
                              height: TioStroke.width2,
                              decoration: BoxDecoration(
                                color: colors.textPrimary,
                                borderRadius:
                                    BorderRadius.circular(TioRadius.full),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Matches the existing Set Type option treatment, without duplicating a
/// sheet, theme token or navigation behavior in the two Routine locations.
class _RoutineActionOption extends StatelessWidget {
  const _RoutineActionOption({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final danger = context.tioColors.danger;
    return Semantics(
      container: true,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: TioCard(
        variant: TioCardVariant.outlined,
        outlinedBorderWidth: TioCardTokens.borderThin,
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.md,
          vertical: TioSpacing.sm,
        ),
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: TioSize.dp38,
              height: TioSize.dp38,
              child: Center(
                child: Icon(
                  icon,
                  color: destructive ? danger : context.tioColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: destructive ? danger : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RoutineAction { edit, move, delete }
