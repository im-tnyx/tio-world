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
    this.mealCategoryAnchorKey,
    this.dateTimeAnchorKey,
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

  /// One short muted line above the button. Use it to say why the commit is
  /// unavailable; anything longer belongs in the body, not in a pinned region.
  final String? note;

  final VoidCallback? onMealCategoryTap;
  final VoidCallback? onDateTimeTap;
  final VoidCallback? onPrimaryPressed;

  /// Optional presentation anchor for a caller-owned Meal Type popup, exactly
  /// as [dateTimeAnchorKey] is for the date one. The footer stays a fixed
  /// strip: the popup floats over the body above it and never grows this row.
  final GlobalKey? mealCategoryAnchorKey;

  /// Optional presentation anchor for a caller-owned DateTime popup.
  final GlobalKey? dateTimeAnchorKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FooterSeparator(),
        // Two plain controls on one line rather than two boxes: the category
        // sits at the leading edge with its chevron right beside the word it
        // opens, and the date runs to the trailing edge behind its calendar.
        // Cards here would have made the footer look like more content when
        // its job is to be the quiet strip the content stops at.
        Row(
          children: [
            // Flexible, not fixed: a custom category name can be longer than
            // any of the four defaults, and the unselected wording is longer
            // than all of them. Without this the row overflows instead of
            // shortening, and the reader loses the date rather than a few
            // characters of a name they chose.
            Flexible(
              child: KeyedSubtree(
                key: mealCategoryAnchorKey,
                child: _FooterAction(
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
                    // Never shortened away: the chevron is what says this
                    // opens something.
                    Icon(
                      Icons.expand_more_rounded,
                      size: TioSize.dp20,
                      color: iconColor,
                    ),
                  ],
                ),
                ),
              ),
            ),
            // Takes the remainder and hands it back right-aligned, so the
            // date keeps the trailing edge however short the category is.
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: KeyedSubtree(
                  key: dateTimeAnchorKey,
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
        // The optional note owns its own spacing; without it, keep the
        // footer controls and primary action visually compact.
        const SizedBox(height: TioSpacing.xs),
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
  final Widget Function(
      BuildContext context, TextStyle textStyle, Color iconColor) builder;
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
            // A real target once this path is live. This compact footer keeps
            // its approved 44dp control height while retaining InkWell focus
            // and ripple behavior instead of relying on a bare detector.
            ? Material(
                color: TioPalette.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(TioRadius.sm),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: TioSize.dp44,
                      minWidth: TioSize.dp48,
                    ),
                    child: Padding(
                      // Keep the fixed target while reserving 2dp below its
                      // content, which shifts the visual baseline up by 1dp.
                      padding: const EdgeInsets.only(
                        left: TioSpacing.xs,
                        right: TioSpacing.xs,
                        bottom: TioSize.dp2,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: 1,
                        child: content,
                      ),
                    ),
                  ),
                ),
              )
            : Opacity(
                opacity: TioOpacity.opacity64,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: TioSize.dp2),
                  child: content,
                ),
              ),
      ),
    );
  }
}
