import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// The canonical card that can be chosen from a set of options.
///
/// Distinct from [TioCard], which is a generic container with no notion of
/// being chosen, and from [TioGroupCard], which groups rows and is never
/// selectable. Selection is state, not a fill variant, so it lives here rather
/// than as a flag on the generic card.
///
/// Features supply the content, the current [selected] value and the action.
/// The selected/unselected appearance and the interactive semantics belong to
/// core, because that is exactly what drifted while every surface rebuilt its
/// own `BoxDecoration`.
///
/// Appearance is [TioCardTokens] and nothing else:
///
/// | | selected | unselected |
/// |---|---|---|
/// | fill | `primary` @ `selectedContainerAlpha` | `surface` |
/// | border | `primary` @ `selectedBorderWidth` | `outlineStrong` @ `unselectedOutlineAlpha`, `unselectedBorderWidth` |
///
/// Radius and padding are `TioCardTokens.radius` / `TioCardTokens.padding`.
/// There is deliberately no override for any of these: a caller that can pass
/// its own outline strength is a caller that can drift again.
class TioSelectableCard extends StatelessWidget {
  const TioSelectableCard({
    required this.selected,
    required this.child,
    super.key,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
  });

  /// Whether this option is the chosen one. Drives fill and border together —
  /// they are one appearance, not two independent knobs.
  final bool selected;

  /// The option's content. Composed by the caller so this component never
  /// grows feature-shaped parameters for icons, titles or trailing marks.
  final Widget child;

  /// Chooses this option. Null renders a non-interactive card.
  final VoidCallback? onTap;

  /// Whether the option may be chosen at all. False suppresses the tap and
  /// dims the card, for surfaces that show an option their user cannot pick
  /// yet rather than hiding it.
  final bool enabled;

  /// Accessibility label for the whole option. Null leaves the composed
  /// content to describe itself, so a caller that already renders readable
  /// text is not forced to repeat it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final radius = BorderRadius.circular(TioCardTokens.radius);
    final tappable = enabled ? onTap : null;

    final card = Material(
      color: selected
          ? colors.primary.withValues(
              alpha: TioCardTokens.selectedContainerAlpha,
            )
          : colors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: tappable,
        borderRadius: radius,
        // The wrapping Semantics below owns the button/selected node and its
        // tap action. Without this the ink well contributes a second tappable
        // node, so assistive technology announces one option twice.
        excludeFromSemantics: true,
        child: AnimatedContainer(
          duration: context.tioMotion.fast,
          padding: const EdgeInsets.all(TioCardTokens.padding),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? colors.primary
                  : colors.outlineStrong.withValues(
                      alpha: TioCardTokens.unselectedOutlineAlpha,
                    ),
              width: selected
                  ? TioCardTokens.selectedBorderWidth
                  : TioCardTokens.unselectedBorderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );

    return Semantics(
      // The option is one node, so assistive technology announces "selected
      // button" once for the whole card rather than per inner widget.
      container: true,
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      onTap: tappable,
      // A supplied label describes the whole option, so the composed content
      // is not read out after it. Without one the content speaks for itself.
      excludeSemantics: semanticLabel != null,
      child:
          enabled ? card : Opacity(opacity: TioOpacity.opacity64, child: card),
    );
  }
}
