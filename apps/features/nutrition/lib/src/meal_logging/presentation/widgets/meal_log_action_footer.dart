import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// The pinned action region a meal-logging editor commits from.
///
/// ```text
/// ─────────────────────────────────────────────────
/// Meal type ▼                       🗓 Sep 27, 18:42
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
/// There is no separate `enabled` flag for the three actions. A null callback
/// is the resting disabled state — dimmed, inert, and reported disabled to
/// assistive technology. [primaryLoading] is different: it is the transient
/// state of a real callback already in flight and is delegated to `TioButton`'s
/// governed loading contract.
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
    this.mealCategoryAnchorKey,
    this.dateTimeAnchorKey,
    this.primaryLoading = false,
    this.primaryLoadingLabel,
  });

  /// What the category control reads: the selected category's name, or an
  /// invitation to choose one. The caller resolves it, because the caller owns
  /// the selection.
  final String mealCategoryLabel;

  /// What the date/time control reads, beside its calendar glyph.
  final String dateTimeLabel;

  /// The commit label — `Log Meal` on create, `Save Changes` on a future edit.
  final String primaryLabel;

  final String? mealCategorySemanticLabel;
  final String? dateTimeSemanticLabel;
  final String? primarySemanticLabel;

  /// One short muted line above the button. Use it for a concise save/error
  /// state; anything longer belongs in the body, not in a pinned region.
  final String? note;

  final VoidCallback? onMealCategoryTap;
  final VoidCallback? onDateTimeTap;
  final VoidCallback? onPrimaryPressed;
  final bool primaryLoading;
  final String? primaryLoadingLabel;

  /// Optional presentation anchor for a caller-owned Meal Type popup, exactly
  /// as [dateTimeAnchorKey] is for the date one. The footer stays a fixed
  /// strip: the popup floats over the body above it and never grows this row.
  final GlobalKey? mealCategoryAnchorKey;

  /// Optional presentation anchor for a caller-owned DateTime popup.
  final GlobalKey? dateTimeAnchorKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioEditorActionFooter(
      dividerKey: const ValueKey('meal-log-footer-divider'),
      leading: KeyedSubtree(
        key: mealCategoryAnchorKey,
        child: TioEditorFooterAction(
          controlKey: const ValueKey('meal-log-footer-category'),
          semanticLabel: mealCategorySemanticLabel ?? mealCategoryLabel,
          onTap: onMealCategoryTap,
          builder: (context, textStyle, iconColor) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  mealCategoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
              const SizedBox(width: TioSpacing.xs),
              Icon(
                Icons.expand_more_rounded,
                size: TioSize.dp20,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
      trailing: KeyedSubtree(
        key: dateTimeAnchorKey,
        child: TioEditorFooterAction(
          controlKey: const ValueKey('meal-log-footer-date-time'),
          semanticLabel: dateTimeSemanticLabel ?? dateTimeLabel,
          onTap: onDateTimeTap,
          builder: (context, textStyle, iconColor) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/svg_icon/ic_calendar_1.svg',
                package: 'tio_core',
                width: TioSize.dp20,
                height: TioSize.dp20,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              const SizedBox(width: TioSpacing.sm),
              Flexible(
                child: Text(
                  dateTimeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
      note: note == null
          ? null
          : Semantics(
              liveRegion: true,
              child: Text(
                note!,
                key: const ValueKey('meal-log-footer-note'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: TioFontSize.size12,
                ),
              ),
            ),
      primary: TioButton.primary(
        key: const ValueKey('meal-log-footer-primary'),
        label: primaryLabel,
        semanticLabel: primarySemanticLabel,
        expand: true,
        loading: primaryLoading,
        loadingLabel: primaryLoadingLabel,
        onPressed: onPrimaryPressed,
      ),
    );
  }
}
