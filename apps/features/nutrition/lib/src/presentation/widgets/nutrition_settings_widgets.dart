import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Shared building blocks for the Nutrition-owned Settings surfaces.
///
/// Extracted so Nutrition Profile and Nutrition Targets render identically
/// rather than each hand-rolling its own rows, which is how selection-card and
/// sheet treatments drifted apart elsewhere in the app.
class NutritionSettingsSectionHeader extends StatelessWidget {
  const NutritionSettingsSectionHeader({
    required this.title,
    super.key,
    this.trailing,
  });

  final String title;

  /// Optional action for the section as a whole, such as the single pencil
  /// that edits every macro together.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final label = Text(
      title,
      style: TextStyle(
        color: colors.textMuted,
        fontWeight: TioFontWeight.w700,
        fontSize: TioFontSize.size11,
        letterSpacing: TioLetterSpacing.positive08,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(
        left: TioSpacing.sm,
        right: TioSpacing.sm,
        bottom: TioSpacing.sm,
      ),
      child: trailing == null
          ? label
          : Row(
              children: [
                Expanded(child: label),
                trailing!,
              ],
            ),
    );
  }
}

/// Edit-in-place affordance: opens a focused editor for a value without
/// leaving the current surface.
class NutritionEditPencil extends StatelessWidget {
  const NutritionEditPencil({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _NutritionCircularAction(
      icon: Icons.edit_outlined,
      onPressed: onPressed,
    );
  }
}

/// Navigation affordance: opens a separate screen.
///
/// Deliberately distinct from [NutritionEditPencil]. A pencil promises editing
/// right here; a chevron promises going somewhere. Using the wrong one makes
/// the screen lie about what a tap will do.
class NutritionOpenChevron extends StatelessWidget {
  const NutritionOpenChevron({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    // A bare glyph, unlike the pencil. The circular affordance reads as a
    // button you press in place; navigation is a lighter promise and matches
    // how chevrons appear elsewhere in Settings.
    return InkResponse(
      onTap: onPressed,
      radius: TioSize.dp24,
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.xs),
        child: Icon(
          Icons.chevron_right_rounded,
          size: TioSize.dp20,
          color: colors.textMuted,
        ),
      ),
    );
  }
}

/// Shared shape for the two affordances, so only the glyph carries meaning.
class _NutritionCircularAction extends StatelessWidget {
  const _NutritionCircularAction({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    // The circle is the ink surface, and it clips. Owner-approved on
    // 2026-09-09 for every consumer of this affordance, not for Meal
    // Categories alone: pressing the pencil was painting a splash and a
    // highlight past the 36dp circle and onto the row behind it, which is not
    // what any other Settings surface does — there the ripple belongs to the
    // row, and Core's own `TioSettingsEditAffordance` paints nothing at all.
    return Material(
      color: colors.surfaceVariant,
      shape: const CircleBorder(),
      // Structural, not cosmetic. Whatever the ink layer decides to draw —
      // including the focus ring the framework supplies — is confined to the
      // affordance. Suppressing colours alone would leave the next state
      // someone adds free to bleed onto the card again.
      clipBehavior: Clip.antiAlias,
      child: InkResponse(
        onTap: onPressed,
        // Never wider than the circle it lives in.
        radius: TioSize.dp36 / 2,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        // Nothing is drawn on press: the framework's own `NoSplash` rather
        // than a transparent splash colour, so nothing is painted at all
        // instead of something painted invisibly.
        splashFactory: NoSplash.splashFactory,
        highlightColor: TioPalette.transparent,
        hoverColor: TioPalette.transparent,
        // `focusColor` is deliberately left alone. A keyboard user has to be
        // able to see where focus sits, and the clip above keeps that ring
        // inside the circle where it belongs.
        child: SizedBox(
          width: TioSize.dp36,
          height: TioSize.dp36,
          child: Center(
            child: Icon(
              icon,
              size: TioSize.dp16,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
