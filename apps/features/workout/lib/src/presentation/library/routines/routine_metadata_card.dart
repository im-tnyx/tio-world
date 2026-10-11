import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

/// One canonical Routine rendered as a standalone Core card.
///
/// A Library instance is read-only; Program Detail supplies the real rename
/// action and its supporting label. No second Routine source of truth exists.
class RoutineMetadataCard extends StatelessWidget {
  const RoutineMetadataCard({
    required this.routine,
    super.key,
    this.supportingText,
    this.onTap,
  });

  final Routine routine;
  final String? supportingText;
  final VoidCallback? onTap;

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
          if (onTap != null)
            _RoutineOptionsPopup(
              routineId: routine.id.value,
              onEdit: onTap!,
            ),
        ],
      ),
    );
  }
}


/// Anchors the real Edit action to the Routine's unchanged overflow trigger.
/// Core owns the floating popup card, placement, and outside-tap dismissal.
class _RoutineOptionsPopup extends StatefulWidget {
  const _RoutineOptionsPopup({
    required this.routineId,
    required this.onEdit,
  });

  final String routineId;
  final VoidCallback onEdit;

  @override
  State<_RoutineOptionsPopup> createState() => _RoutineOptionsPopupState();
}

class _RoutineOptionsPopupState extends State<_RoutineOptionsPopup> {
  final _anchorKey = GlobalKey();
  bool _isOpen = false;

  void _toggle() => setState(() => _isOpen = !_isOpen);

  void _dismiss() {
    if (_isOpen) setState(() => _isOpen = false);
  }

  void _edit() {
    _dismiss();
    widget.onEdit();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioAnchoredPopup(
      anchorKey: _anchorKey,
      isOpen: _isOpen,
      onDismiss: _dismiss,
      dismissSemanticLabel: 'Dismiss Routine options',
      popupKey: ValueKey('routine-popup-card-${widget.routineId}'),
      maximumWidth: TioSize.dp200,
      contentPadding: EdgeInsets.zero,
      contentBuilder: (context, maximumHeight) => Material(
        color: TioPalette.transparent,
        child: InkWell(
          key: ValueKey('routine-edit-${widget.routineId}'),
          onTap: _edit,
          borderRadius: BorderRadius.circular(TioRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TioSize.dp48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TioSpacing.lg,
                vertical: TioSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit_outlined,
                    size: TioSize.dp20,
                    color: colors.textPrimary,
                  ),
                  const SizedBox(width: TioSpacing.md),
                  Text(
                    'Edit',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      child: Semantics(
        key: ValueKey('routine-menu-${widget.routineId}'),
        button: true,
        expanded: _isOpen,
        label: 'Routine options',
        onTap: _toggle,
        child: ExcludeSemantics(
          child: IconButton(
            key: _anchorKey,
            tooltip: 'Routine options',
            onPressed: _toggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: TioSize.dp48,
              height: TioSize.dp48,
            ),
            icon: const Icon(Icons.more_vert_rounded, size: TioSize.dp24),
          ),
        ),
      ),
    );
  }
}
