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

  final Widget child;

  @override
  Widget build(BuildContext context) => TioAnchoredPopup(
        anchorKey: anchorKey,
        isOpen: isOpen,
        onDismiss: onDismiss,
        dismissSemanticLabel: 'Dismiss meal type picker',
        popupKey: const ValueKey('meal-category-picker-popup'),
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
        // width of its own. Rows of differing widths read as a broken list,
        // and stretching instead would put the card back at its full cap.
        child: IntrinsicWidth(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final option in widget.options)
              Padding(
                padding: const EdgeInsets.only(bottom: TioSpacing.xs),
                child: TioSelectableCard(
                  key: ValueKey('meal-category-option-${option.id}'),
                  selected: option.id == widget.selectedId,
                  semanticLabel: option.label,
                  // Choosing is the whole interaction: no Done, no Apply.
                  onTap: () => widget.onSelected(option.id),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          option.label,
                          // A custom name can be longer than any default, and
                          // at a large text scale it wraps rather than being
                          // cut off.
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: TioFontWeight.w700,
                            fontSize: TioFontSize.size15,
                          ),
                        ),
                      ),
                      if (option.id == widget.selectedId) ...[
                        const SizedBox(width: TioSpacing.sm),
                        // The card already tints and outlines the chosen
                        // option; the tick says the same thing again for a
                        // reader who cannot rely on that difference alone.
                        Icon(
                          Icons.check_rounded,
                          key: ValueKey('meal-category-check-${option.id}'),
                          size: TioSize.dp20,
                          color: colors.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }
}
