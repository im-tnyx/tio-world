import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// One choosable meal category, reduced to what a screen may show.
///
/// An id and a label, and deliberately nothing else. The domain's
/// `MealCategory` also carries `defaultKey`, `active` and `order`, none of
/// which a picker has any business rendering — and the surest way for an
/// internal identity to reach the screen is for it to be in the object the
/// screen is handed.
///
/// [id] is the selection's identity and survives renaming; [label] is what the
/// reader sees and does not.
@immutable
final class MealCategoryOption {
  const MealCategoryOption({required this.id, required this.label});

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is MealCategoryOption && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

/// A reusable anchored Meal Type popup card.
///
/// ```text
///        ┌──────────────────────┐
///        │ Breakfast         ✓  │
///        │ Lunch                │
///        └──────────────────────┘
///        ─────────────────────────
///        Meal type      Date / time     the footer, unmoved
///        [      Log Meal        ]
/// ```
///
/// The same shape as [TioDateTimePickerPopup] beside it, and for the same
/// reason: the footer is a fixed strip, so its second control cannot open
/// something that grows it. The card floats over the body above the anchor and
/// the editor stays visible behind.
///
/// The caller owns the anchor, the open flag and the selection. This widget
/// presents options and reports the id of the one chosen — there is no Done or
/// Apply, because choosing is the whole interaction: a tap selects and closes,
/// and a tap outside closes without changing anything.
class MealCategoryPickerPopup extends StatelessWidget {
  const MealCategoryPickerPopup({
    required this.anchorKey,
    required this.isOpen,
    required this.onDismiss,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    required this.child,
    super.key,
    this.loadError,
    this.onRetry,
    this.passThroughAnchorKey,
  });

  /// A key on the caller's Meal Type control. Presentation-only, with no
  /// feature meaning.
  final GlobalKey anchorKey;
  final bool isOpen;
  final VoidCallback onDismiss;

  /// The categories this log may be filed under, already resolved and ordered
  /// by whoever owns them. This widget never reads a repository and never
  /// learns what makes a category selectable.
  final List<MealCategoryOption> options;

  /// The chosen category's durable id, or null while none is chosen.
  final String? selectedId;

  /// Reports the id the reader chose. The label is never reported: the caller
  /// stores identity, and resolves the text from the source that owns it.
  final ValueChanged<String> onSelected;

  /// Shown instead of the options when the categories could not be loaded.
  final String? loadError;

  /// Reloads from the failure state.
  final Future<void> Function()? onRetry;

  /// A sibling control the dismiss layer leaves reachable while this card is
  /// open, so moving to the card it opens costs one tap rather than two.
  final GlobalKey? passThroughAnchorKey;

  final Widget child;

  @override
  Widget build(BuildContext context) => TioAnchoredPopup(
        anchorKey: anchorKey,
        isOpen: isOpen,
        onDismiss: onDismiss,
        dismissSemanticLabel: 'Dismiss meal type picker',
        popupKey: const ValueKey('meal-category-picker-popup'),
        passThroughAnchorKey: passThroughAnchorKey,
        // Narrower than the date wheel's card on purpose: this is a short list
        // of short names beside one control, not a band across the footer.
        maximumWidth: TioSize.dp200 + TioSize.dp48,
        // No preferred height: the card takes the side with more room, which
        // above a pinned footer is always the body.
        contentBuilder: (context, maximumHeight) => _PopupContent(
          maximumHeight: maximumHeight,
          options: options,
          selectedId: selectedId,
          onSelected: onSelected,
          loadError: loadError,
          onRetry: onRetry,
        ),
        child: child,
      );
}

class _PopupContent extends StatefulWidget {
  const _PopupContent({
    required this.maximumHeight,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    required this.loadError,
    required this.onRetry,
  });

  final double maximumHeight;
  final List<MealCategoryOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String? loadError;
  final Future<void> Function()? onRetry;

  @override
  State<_PopupContent> createState() => _PopupContentState();
}

class _PopupContentState extends State<_PopupContent> {
  bool _retrying = false;

  Future<void> _retry() async {
    final retry = widget.onRetry;
    if (retry == null || _retrying) return;
    setState(() => _retrying = true);
    await retry();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final loadError = widget.loadError;

    if (loadError != null) {
      return Padding(
        key: const ValueKey('meal-category-picker-failure'),
        padding: const EdgeInsets.all(TioSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              // Never a fallback list. Showing the canonical four here would
              // tell the reader their categories are these, which is a claim
              // this screen cannot make after a failed read.
              loadError,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size14,
                height: TioLineHeight.height145,
              ),
            ),
            const SizedBox(height: TioSpacing.md),
            TioButton.secondary(
              key: const ValueKey('meal-category-picker-retry'),
              label: 'Try again',
              loading: _retrying,
              onPressed: widget.onRetry == null ? null : _retry,
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maximumHeight),
      child: SingleChildScrollView(
        // Its own scroll, so eight categories at a large text scale stay
        // reachable instead of being clipped by whatever room the anchor left.
        key: const ValueKey('meal-category-picker-options'),
        // The card sizes to its content, and `IntrinsicWidth` is what makes
        // every row the width of the longest label rather than each row the
        // width of its own. Rows of differing widths read as a broken list.
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in widget.options)
                _OptionRow(
                  key: ValueKey('meal-category-option-${option.id}'),
                  option: option,
                  selected: option.id == widget.selectedId,
                  onTap: () => widget.onSelected(option.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line in the card.
///
/// Deliberately not `TioSelectableCard`. That component is a card — its own
/// outline, its own padding — and a column of them inside the popup's card
/// reads as cards nested in a card, at twice the height a line of text needs.
/// A menu's rows are rows: the chosen one is a soft fill and a tick, and the
/// surface around them belongs to the card.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final MealCategoryOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final radius = BorderRadius.circular(TioRadius.md);

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      // The row below already renders the label; without this the same words
      // would be announced twice.
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? colors.surfaceVariant : TioPalette.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          excludeFromSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: TioSize.dp44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TioSpacing.md,
                vertical: TioSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      option.label,
                      // A custom name can be longer than any default, and at a
                      // large text scale it wraps rather than being cut off.
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                        fontSize: TioFontSize.size15,
                      ),
                    ),
                  ),
                  const SizedBox(width: TioSpacing.md),
                  // The slot is held whether or not this row is the chosen
                  // one, so no label shifts sideways as the selection moves.
                  SizedBox(
                    width: TioSize.dp20,
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            key: ValueKey('meal-category-check-${option.id}'),
                            size: TioSize.dp20,
                            color: colors.textPrimary,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
