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
    this.onEdit,
    this.onMove,
    this.onDelete,
    this.actionSheetGuard,
  });

  final Routine routine;
  final String? supportingText;
  final VoidCallback? onTap;

  /// The caller must supply only live, owner-verified capabilities.
  final VoidCallback? onEdit;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;
  /// Optional app-owned auth-cycle guard for the separate options modal.
  /// Sheet ownership remains here; account identity never enters Workout.
  final Widget Function(BuildContext, Widget)? actionSheetGuard;

  @override
  State<RoutineMetadataCard> createState() => _RoutineMetadataCardState();
}

class _RoutineMetadataCardState extends State<RoutineMetadataCard> {
  bool _openingActions = false;

  Future<void> _openActions() async {
    if (_openingActions) return;
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
                  onTap: () => Navigator.of(sheetContext)
                      .pop(_RoutineAction.edit),
                ),
                const SizedBox(height: TioSpacing.sm),
              ],
              if (widget.onMove != null) ...[
                _RoutineActionOption(
                  key: ValueKey('routine-move-${openingId.value}'),
                  label: 'Move Routine',
                  icon: Icons.swap_horiz_rounded,
                  onTap: () => Navigator.of(sheetContext)
                      .pop(_RoutineAction.move),
                ),
                const SizedBox(height: TioSpacing.sm),
              ],
              if (widget.onDelete != null)
                _RoutineActionOption(
                  key: ValueKey('routine-delete-${openingId.value}'),
                  label: 'Delete Routine',
                  icon: Icons.delete_outline,
                  destructive: true,
                  onTap: () => Navigator.of(sheetContext)
                      .pop(_RoutineAction.delete),
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
          widget.routine.id != openingId ||
          widget.routine.programId != openingProgramId) {
        return;
      }
      switch (selected) {
        case _RoutineAction.edit:
          widget.onEdit?.call();
        case _RoutineAction.move:
          widget.onMove?.call();
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
          if (widget.onEdit != null ||
              widget.onMove != null ||
              widget.onDelete != null)
            Semantics(
              key: ValueKey('routine-menu-${widget.routine.id.value}'),
              // Keep overflow independently focusable from the card's
              // primary navigation tap, with one semantic tap target.
              container: true,
              button: true,
              label: 'Routine options',
              onTap: _openActions,
              child: ExcludeSemantics(
                child: IconButton(
                  tooltip: 'Routine options',
                  onPressed: _openActions,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: TioSize.dp48,
                    height: TioSize.dp48,
                  ),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: TioSize.dp24,
                    color: colors.textPrimary,
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
