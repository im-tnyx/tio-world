import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

/// One canonical Routine rendered as a standalone Core card.
///
/// The primary card tap and the Routine action sheet are independent.
/// Expanded Library cards remain read-only unless real owner capabilities
/// are supplied; there is no second Routine source of truth.
class RoutineMetadataCard extends StatelessWidget {
  const RoutineMetadataCard({
    required this.routine,
    super.key,
    this.supportingText,
    this.onTap,
    this.onEdit,
    this.onMove,
    this.onDelete,
  });

  final Routine routine;
  final String? supportingText;
  final VoidCallback? onTap;

  /// Only supply actions backed by a real owner-verified capability.
  final VoidCallback? onEdit;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;

  Future<void> _openActions(BuildContext context) async {
    final selected = await showModalBottomSheet<_RoutineAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TioPalette.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: TioSheet(
          key: ValueKey('routine-actions-sheet-${routine.id.value}'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                routine.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                      color: sheetContext.tioColors.textPrimary,
                    ),
              ),
              const SizedBox(height: TioSpacing.lg),
              TioGroupCard(
                children: [
                  if (onEdit != null)
                    TioSettingsNavigationRow(
                      key: ValueKey('routine-edit-${routine.id.value}'),
                      leading: const TioSettingsLeadingIcon(
                        icon: Icons.edit_outlined,
                      ),
                      title: 'Edit Routine',
                      supportingText: 'Edit name, exercises and sets',
                      showChevron: false,
                      onTap: () => Navigator.of(sheetContext)
                          .pop(_RoutineAction.edit),
                    ),
                  if (onMove != null)
                    TioSettingsNavigationRow(
                      key: ValueKey('routine-move-${routine.id.value}'),
                      leading: const TioSettingsLeadingIcon(
                        icon: Icons.drive_file_move_outlined,
                      ),
                      title: 'Move Routine',
                      supportingText: 'Choose another Program',
                      showChevron: false,
                      onTap: () => Navigator.of(sheetContext)
                          .pop(_RoutineAction.move),
                    ),
                  if (onDelete != null)
                    TioSettingsNavigationRow(
                      key: ValueKey('routine-delete-${routine.id.value}'),
                      leading: const TioSettingsLeadingIcon(
                        icon: Icons.delete_outline,
                        color: sheetContext.tioColors.danger,
                      ),
                      title: 'Delete Routine',
                      supportingText: 'Permanently remove this Routine',
                      titleColor: sheetContext.tioColors.danger,
                      showChevron: false,
                      onTap: () => Navigator.of(sheetContext)
                          .pop(_RoutineAction.delete),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Close the options route before entering the selected workflow.
    // A dismissed sheet or removed owner card never dispatches an action.
    if (!context.mounted) return;
    switch (selected) {
      case _RoutineAction.edit:
        onEdit?.call();
      case _RoutineAction.move:
        onMove?.call();
      case _RoutineAction.delete:
        onDelete?.call();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.fitness_center_outlined, color: colors.textSecondary),
          const SizedBox(width: TioSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: TioFontSize.size15,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
                if (supportingText != null)
                  Text(
                    supportingText!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size12,
                    ),
                  ),
              ],
            ),
          ),
          if (onEdit != null || onMove != null || onDelete != null)
            Semantics(
              key: ValueKey('routine-menu-${routine.id.value}'),
              button: true,
              label: 'Routine options',
              onTap: () => _openActions(context),
              child: ExcludeSemantics(
                child: IconButton(
                  tooltip: 'Routine options',
                  onPressed: () => _openActions(context),
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

enum _RoutineAction { edit, move, delete }
