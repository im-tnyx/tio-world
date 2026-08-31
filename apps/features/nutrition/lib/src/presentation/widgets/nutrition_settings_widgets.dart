import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Shared building blocks for the Nutrition-owned Settings surfaces.
///
/// Extracted so Nutrition Profile and Nutrition Targets render identically
/// rather than each hand-rolling its own rows, which is how selection-card and
/// sheet treatments drifted apart elsewhere in the app.
class NutritionSettingsSectionHeader extends StatelessWidget {
  const NutritionSettingsSectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding:
          const EdgeInsets.only(left: TioSpacing.sm, bottom: TioSpacing.sm),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontWeight: TioFontWeight.w700,
          fontSize: TioFontSize.size11,
          letterSpacing: TioLetterSpacing.positive08,
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
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isUnset;
  final VoidCallback onTap;

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
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w700,
                  fontSize: TioFontSize.size15,
                ),
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
        ),
      ),
    );
  }
}
