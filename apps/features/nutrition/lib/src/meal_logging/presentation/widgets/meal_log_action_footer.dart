import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// The pinned action region a meal-logging editor commits from.
///
/// ```text
/// ─────────────────────────────────────────────────
/// Meal type ▼                       🗓 Sep 27 · Time
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
        const _FooterSeparator(),
        const SizedBox(height: TioSpacing.md),
        // Two plain controls on one line rather than two boxes: the category
        // sits at the leading edge with its chevron right beside the word it
        // opens, and the date runs to the trailing edge behind its calendar.
        // Cards here would have made the footer look like more content when
        // its job is to be the quiet strip the content stops at.
        Row(
          children: [
            _FooterAction(
              controlKey: const ValueKey('meal-log-footer-category'),
              semanticLabel: mealCategorySemanticLabel ?? mealCategoryLabel,
              onTap: onMealCategoryTap,
              builder: (context, textStyle, iconColor) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mealCategoryLabel, style: textStyle),
                  const SizedBox(width: TioSpacing.xs),
                  Icon(
                    Icons.expand_more_rounded,
                    size: TioSize.dp20,
                    color: iconColor,
                  ),
                ],
              ),
            ),
            // Takes the remainder and hands it back right-aligned, so the
            // date keeps the trailing edge however short the category is.
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _FooterAction(
                  controlKey: const ValueKey('meal-log-footer-date-time'),
                  semanticLabel: dateTimeSemanticLabel ?? dateTimeLabel,
                  onTap: onDateTimeTap,
                  builder: (context, textStyle, iconColor) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/svg_icon/ic_calendar_.svg',
                        package: 'tio_core',
                        width: TioSize.dp20,
                        height: TioSize.dp20,
                        colorFilter: ColorFilter.mode(
                          iconColor,
                          BlendMode.srcIn,
                        ),
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
            ),
          ],
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

/// The line where the scrolling body stops and the pinned region starts.
///
/// It has to reach both edges of the sheet, and the sheet pads its content
/// horizontally. Rather than hard-code that padding back out, the line is
/// allowed to overflow symmetrically to the window width, which cancels
/// whatever the padding happens to be.
///
/// The other half of the problem — the sheet's gap above its actions, which
/// would have left dead space over the line — is handled by asking the sheet
/// for `flushActions` instead of painting around it.
class _FooterSeparator extends StatelessWidget {
  const _FooterSeparator();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    // The outer box is what the Column lays out — one hairline tall. Only the
    // width is allowed to overflow; without pinning the height the OverflowBox
    // would try to fill a Column that offers it no bound.
    return SizedBox(
      height: TioStroke.width1,
      child: OverflowBox(
        maxWidth: double.infinity,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: Divider(
            key: const ValueKey('meal-log-footer-divider'),
            height: TioStroke.width1,
            thickness: TioStroke.width1,
            color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
          ),
        ),
      ),
    );
  }
}

/// One control on the footer's top line.
///
/// The caller builds the content because the two differ: the category is a
/// word followed by its chevron, the date is a glyph followed by its value.
/// What is shared is the part that must not differ — the text and icon
/// treatment, and the fact that a null [onTap] means disabled, dimmed and
/// reported as such rather than merely inert.
class _FooterAction extends StatelessWidget {
  const _FooterAction({
    required this.controlKey,
    required this.semanticLabel,
    required this.builder,
    this.onTap,
  });

  final Key controlKey;
  final String semanticLabel;
  final Widget Function(BuildContext context, TextStyle textStyle, Color iconColor)
      builder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isEnabled = onTap != null;
    final content = builder(
      context,
      TextStyle(
        color: colors.textPrimary,
        fontSize: TioFontSize.size15,
        fontWeight: TioFontWeight.w600,
      ),
      isEnabled ? colors.textPrimary : colors.textMuted,
    );

    return Semantics(
      key: controlKey,
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: isEnabled
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: content,
              )
            : Opacity(opacity: TioOpacity.opacity64, child: content),
      ),
    );
  }
}
