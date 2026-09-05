import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// A tappable navigation row for a neutral settings group surface.
class TioSettingsNavigationRow extends StatelessWidget {
  const TioSettingsNavigationRow({
    required this.leading,
    required this.title,
    required this.supportingText,
    super.key,
    this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  final Widget leading;
  final String title;
  final String supportingText;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool showChevron;

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
            leading,
            const SizedBox(width: TioSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? colors.textPrimary,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.xxs),
                  Text(
                    supportingText,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size12,
                      fontWeight: TioFontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: TioSize.dp20,
                color: colors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

/// Standard coloured icon container for a settings navigation row.
class TioSettingsLeadingIcon extends StatelessWidget {
  const TioSettingsLeadingIcon({required this.icon, super.key, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final iconColor = color ?? colors.primary;
    return Container(
      width: TioSize.dp40,
      height: TioSize.dp40,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(TioAlpha.alpha18),
        borderRadius: BorderRadius.circular(TioRadius.sm),
      ),
      child: Icon(icon, size: TioSize.dp22, color: iconColor),
    );
  }
}

/// A tappable settings row with a leading icon, a value and an edit affordance.
///
/// [value] remains caller-composed so a screen can preserve a specialised
/// value treatment without rebuilding the shared interactive row geometry.
class TioSettingsValueRow extends StatelessWidget {
  const TioSettingsValueRow({
    required this.leading,
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
    this.annotation,
    this.labelSingleLine = false,
    this.showEditAffordance = true,
    this.trailing,
  }) : assert(
          !showEditAffordance || trailing == null,
          'Use either the built-in edit affordance or a custom trailing widget.',
        );

  final Widget leading;
  final String label;
  final Widget value;
  final VoidCallback? onTap;
  final String? annotation;
  final bool labelSingleLine;
  final bool showEditAffordance;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final trailing = this.trailing ??
        (showEditAffordance ? const TioSettingsEditAffordance() : null);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md + TioSize.dp4,
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: TioSpacing.lg),
            Expanded(
              flex: 3,
              child: annotation == null
                  ? _labelText(colors)
                  : Row(
                      children: [
                        Flexible(child: _labelText(colors)),
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
                    ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Expanded(flex: 2, child: value),
            if (trailing != null) ...[
              const SizedBox(width: TioSpacing.lg),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _labelText(TioColors colors) {
    return Text(
      label,
      maxLines: labelSingleLine ? 1 : null,
      overflow: labelSingleLine ? TextOverflow.ellipsis : null,
      style: TextStyle(
        color: colors.textPrimary,
        fontWeight: TioFontWeight.w700,
        fontSize: TioFontSize.size15,
      ),
    );
  }
}

/// A non-interactive label/value row for settings details.
class TioSettingsReadOnlyRow extends StatelessWidget {
  const TioSettingsReadOnlyRow({
    required this.label,
    required this.value,
    required this.isUnset,
    super.key,
  });

  final String label;
  final String value;
  final bool isUnset;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.md + TioSize.dp4,
      ),
      child: Row(
        children: [
          Expanded(
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
          // A bare Text here was measured with no width limit, so a value long
          // enough to need more room than the label left it — a full date on a
          // narrow phone, say — spilled out of the row instead of wrapping.
          //
          // Flexible caps it; the Align keeps it anchored to the row's trailing
          // edge exactly where it sat before, so every value that already fitted
          // renders unchanged.
          Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: isUnset ? colors.textMuted : colors.textSecondary,
                  fontSize: TioFontSize.size15,
                  fontWeight: TioFontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard right-aligned value text for a settings value row.
class TioSettingsValueText extends StatelessWidget {
  const TioSettingsValueText({
    required this.value,
    required this.isUnset,
    super.key,
  });

  final String value;
  final bool isUnset;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: TextStyle(
        color: isUnset ? colors.textMuted : colors.textPrimary,
        fontSize: TioFontSize.size15,
        fontWeight: isUnset ? TioFontWeight.w400 : TioFontWeight.w700,
      ),
    );
  }
}

/// Standard neutral edit affordance for tappable settings value rows.
class TioSettingsEditAffordance extends StatelessWidget {
  const TioSettingsEditAffordance({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Container(
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
    );
  }
}
