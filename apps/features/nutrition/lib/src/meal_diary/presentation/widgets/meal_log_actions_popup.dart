import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Feature-owned contextual actions for one MealLog card.
///
/// Only actions with a complete product and persistence contract belong here.
/// TNYX-204 activates Edit; later actions must preserve their separately
/// approved ordering without appearing as dead menu rows in this slice.
class MealLogActionsPopup extends StatefulWidget {
  const MealLogActionsPopup({
    required this.entryId,
    required this.onEdit,
    super.key,
  });

  final String entryId;
  final VoidCallback onEdit;

  @override
  State<MealLogActionsPopup> createState() => _MealLogActionsPopupState();
}

class _MealLogActionsPopupState extends State<MealLogActionsPopup> {
  final _anchorKey = GlobalKey();
  var _isOpen = false;

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
    final radius = BorderRadius.circular(TioRadius.md);

    return TioAnchoredPopup(
      anchorKey: _anchorKey,
      isOpen: _isOpen,
      onDismiss: _dismiss,
      dismissSemanticLabel: 'Dismiss meal actions',
      popupKey: ValueKey('meal-log-actions-popup-${widget.entryId}'),
      maximumWidth: TioSize.dp200,
      contentPadding: EdgeInsets.zero,
      contentBuilder: (context, maximumHeight) => Material(
        color: TioPalette.transparent,
        child: InkWell(
          key: ValueKey('meal-log-edit-${widget.entryId}'),
          onTap: _edit,
          borderRadius: radius,
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
        button: true,
        expanded: _isOpen,
        label: 'Meal actions',
        onTap: _toggle,
        child: ExcludeSemantics(
          child: IconButton(
            key: _anchorKey,
            tooltip: 'Meal actions',
            onPressed: _toggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: TioSize.dp48,
              height: TioSize.dp48,
            ),
            icon: const Icon(Icons.more_vert, size: TioSize.dp24),
          ),
        ),
      ),
    );
  }
}
