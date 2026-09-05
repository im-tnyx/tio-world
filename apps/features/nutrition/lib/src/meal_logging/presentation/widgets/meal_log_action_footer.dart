import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// The pinned action region a meal-logging editor commits from.
///
/// ```text
/// ┌ Meal type        ▼ ┐ ┌ 🗓 Sep 27, 2026 · Time ┐
/// └────────────────────┘ └────────────────────────┘
/// [                    Log Meal                    ]
/// ```
///
/// Nutrition owns this rather than `apps/core`, and deliberately: it knows what
/// a meal category is, that a meal has a consumed date and time, and that the
/// commit is called `Log Meal`. Core is not allowed to learn any of that, so a
/// generic version of this widget would have to be so anonymous that nothing
/// would be left of it.
///
/// It exists as its own widget rather than inline in Quick Add because the same
/// three controls belong to the full Meal Editor too — create mode says
/// `Log Meal`, edit mode will say `Save Changes`. Building it once now is
/// cheaper than extracting it from a screen later. That is the whole of the
/// reuse claim: neither of those flows is implemented here.
///
/// ## Disabled is the absence of a callback
///
/// There is no `enabled` flag for any of the three. A null callback is the
/// disabled state — dimmed, inert, and reported disabled to assistive
/// technology — which is how `TioCard` and `TioButton` already work. Two ways
/// to be switched off is one too many.
class MealLogActionFooter extends StatelessWidget {
  const MealLogActionFooter({
    required this.mealCategoryLabel,
    required this.dateTimeLabel,
    required this.primaryLabel,
    super.key,
    this.mealCategorySemanticLabel,
    this.dateTimeSemanticLabel,
    this.primarySemanticLabel,
    this.note,
    this.onMealCategoryTap,
    this.onDateTimeTap,
    this.onPrimaryPressed,
  });

  /// What the category control reads. A neutral placeholder while TNYX-67 has
  /// not yet given Nutrition a real category to name.
  final String mealCategoryLabel;

  /// What the date/time control reads, beside its calendar glyph.
  final String dateTimeLabel;

  /// The commit label — `Log Meal` on create, `Save Changes` on a future edit.
  final String primaryLabel;

  final String? mealCategorySemanticLabel;
  final String? dateTimeSemanticLabel;
  final String? primarySemanticLabel;

  /// One short muted line above the button. Use it to say why the commit is
  /// unavailable; anything longer belongs in the body, not in a pinned region.
  final String? note;

  final VoidCallback? onMealCategoryTap;
  final VoidCallback? onDateTimeTap;
  final VoidCallback? onPrimaryPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intrinsic height so the two controls match when one of them wraps on
        // a narrow phone, which the date one does first.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _FooterControl(
                  controlKey: const ValueKey('meal-log-footer-category'),
                  label: mealCategoryLabel,
                  semanticLabel: mealCategorySemanticLabel ?? mealCategoryLabel,
                  trailing: Icons.expand_more_rounded,
                  onTap: onMealCategoryTap,
                ),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(
                child: _FooterControl(
                  controlKey: const ValueKey('meal-log-footer-date-time'),
                  label: dateTimeLabel,
                  semanticLabel: dateTimeSemanticLabel ?? dateTimeLabel,
                  leading: Icons.calendar_today_outlined,
                  onTap: onDateTimeTap,
                ),
              ),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: TioSpacing.md),
          Text(
            note!,
            key: const ValueKey('meal-log-footer-note'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size12,
            ),
          ),
        ],
        const SizedBox(height: TioSpacing.md),
        TioButton.primary(
          key: const ValueKey('meal-log-footer-primary'),
          label: primaryLabel,
          semanticLabel: primarySemanticLabel,
          expand: true,
          onPressed: onPrimaryPressed,
        ),
      ],
    );
  }
}

/// One compact control in the footer's top row.
class _FooterControl extends StatelessWidget {
  const _FooterControl({
    required this.controlKey,
    required this.label,
    required this.semanticLabel,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final Key controlKey;
  final String label;
  final String semanticLabel;
  final IconData? leading;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isEnabled = onTap != null;
    final iconColor = isEnabled ? colors.textSecondary : colors.textMuted;

    final control = TioCard(
      variant: TioCardVariant.normal,
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.md,
        vertical: TioSpacing.md,
      ),
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(leading, size: TioSize.dp16, color: iconColor),
            const SizedBox(width: TioSpacing.sm),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: TioFontSize.size13,
                fontWeight: TioFontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: TioSpacing.xs),
            Icon(trailing, size: TioSize.dp16, color: iconColor),
          ],
        ],
      ),
    );

    return Semantics(
      key: controlKey,
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: isEnabled
            ? control
            : Opacity(opacity: TioOpacity.opacity64, child: control),
      ),
    );
  }
}
