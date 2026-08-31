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
    return _NutritionCircularAction(
      icon: Icons.chevron_right_rounded,
      onPressed: onPressed,
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
    return InkResponse(
      onTap: onPressed,
      radius: TioSize.dp24,
      child: Container(
        width: TioSize.dp36,
        height: TioSize.dp36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: TioSize.dp16,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

/// Rounded surface grouping related Nutrition settings rows.
class NutritionSettingsGroupCard extends StatelessWidget {
  const NutritionSettingsGroupCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(TioRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// A labelled row showing one current value and opening its focused editor.
///
/// [isUnset] drives muted styling so an unknown value reads as genuinely
/// unset rather than as a real answer.
class NutritionValueRow extends StatelessWidget {
  const NutritionValueRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isUnset,
    required this.onTap,
    super.key,
    this.annotation,
    this.showEditAffordance = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isUnset;
  final VoidCallback onTap;

  /// Optional derived detail shown beside the label, such as a macro's read-only
  /// share of macro energy. Purely presentational and never persisted.
  final String? annotation;

  /// Whether this row shows its own pencil.
  ///
  /// Rows edited together through one section-level pencil set this false, so
  /// the screen never offers two competing edit affordances for one action.
  final bool showEditAffordance;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md + TioSize.dp4,
        ),
        child: Row(
          children: [
            Icon(icon, size: TioSize.dp24, color: colors.textPrimary),
            const SizedBox(width: TioSpacing.lg),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                        fontSize: TioFontSize.size15,
                      ),
                    ),
                  ),
                  if (annotation != null) ...[
                    const SizedBox(width: TioSpacing.sm),
                    Text(
                      annotation!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: TioFontWeight.w600,
                        fontSize: TioFontSize.size13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Expanded(
              flex: 2,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: isUnset ? colors.textMuted : colors.textPrimary,
                  fontSize: TioFontSize.size15,
                  fontWeight: isUnset ? TioFontWeight.w400 : TioFontWeight.w700,
                ),
              ),
            ),
            if (showEditAffordance) ...[
              const SizedBox(width: TioSpacing.lg),
              Container(
                width: TioSize.dp36,
                height: TioSize.dp36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: TioSize.dp16,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
