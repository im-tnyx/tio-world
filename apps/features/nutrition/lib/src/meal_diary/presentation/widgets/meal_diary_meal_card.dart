import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import 'meal_log_actions_popup.dart';

/// One actionable Meal Diary entry.
///
/// The card is purely presentational: it receives already-formatted strings and
/// emits actions. It holds no read model, preference, repository, or formatting
/// policy, so the Diary owns what a value means and the card owns only how the
/// composition reads.
///
/// Geometry follows the owner-supplied reference card: a fixed leading media
/// slot filling the card's own leading corner, the logged time as a scrim over
/// the bottom of that slot, and a content column carrying the meal name above
/// aligned label/value detail rows with the overflow action in the card's
/// top-trailing corner.
///
/// The runtime MealLog contract carries no meal image, so this renders the
/// governed fallback glyph. A future real image belongs in the same slot and
/// must not change any of the geometry around it.
class MealDiaryMealCard extends StatelessWidget {
  const MealDiaryMealCard({
    required this.entryId,
    required this.mealName,
    required this.caloriesText,
    required this.proteinText,
    required this.timeText,
    required this.notePreview,
    required this.noteIndicatorVisible,
    required this.onTap,
    required this.onEdit,
    super.key,
  });

  final String entryId;

  /// Null when the entry has no resolvable name; the title band then collapses
  /// rather than showing invented copy.
  final String? mealName;

  /// Formatted detail values. Null omits that row instead of rendering a
  /// placeholder for a value the runtime does not have.
  final String? caloriesText;
  final String? proteinText;

  /// Formatted local wall-clock time, or null when the Diary cannot show one.
  final String? timeText;

  /// One-line note preview, independent from [noteIndicatorVisible] so the
  /// Diary can show the marker without the body.
  final String? notePreview;
  final bool noteIndicatorVisible;

  /// Both open the same Quick Edit flow. Null keeps read-only harnesses honest
  /// by omitting the action rather than drawing a dead control.
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final edit = onEdit;
    final tap = onTap;
    final accessibilityLabel = <String>[
      mealName ?? 'Meal log',
      if (timeText != null) timeText!,
      if (caloriesText != null) 'Calories $caloriesText',
      if (proteinText != null) 'Protein $proteinText',
      if (notePreview != null)
        'Note $notePreview'
      else if (noteIndicatorVisible)
        'Meal note',
    ].join(', ');

    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The overflow target always occupies the top-right 48x48 corner when
        // an edit callback exists, so this band must be reserved whenever it
        // does — not only when there happens to be a name or note to show —
        // or the first detail row below renders and hit-tests underneath it.
        if (mealName != null || noteIndicatorVisible || edit != null)
          SizedBox(
            // The title shares its band with the overflow target, so the band
            // is that target's height and the title centres against it exactly
            // as the reference card does.
            height: TioSize.dp48,
            child: Row(
              children: [
                if (mealName != null)
                  Expanded(
                    child: Text(
                      mealName!,
                      key: ValueKey('meal-diary-entry-title-$entryId'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (noteIndicatorVisible) ...[
                  const SizedBox(width: TioSpacing.sm),
                  Icon(
                    Icons.sticky_note_2_outlined,
                    key: ValueKey('meal-diary-entry-note-$entryId'),
                    size: TioSize.dp16,
                    color: colors.textSecondary,
                    semanticLabel: 'Meal note',
                  ),
                ],
                // The overflow target sits flush in the card corner, so it
                // reaches past this padded column by its own width less the
                // column inset. Only the title band yields that region.
                if (edit != null)
                  const SizedBox(width: TioSize.dp48 - TioSpacing.lg),
              ],
            ),
          ),
        if (caloriesText != null)
          _MealDetailRow(
            key: ValueKey('meal-diary-entry-calories-$entryId'),
            label: 'Calories',
            value: caloriesText!,
          ),
        if (proteinText != null)
          _MealDetailRow(
            key: ValueKey('meal-diary-entry-protein-$entryId'),
            label: 'Protein',
            value: proteinText!,
          ),
        if (notePreview != null) ...[
          const SizedBox(height: TioSpacing.xs),
          Text(
            notePreview!,
            key: ValueKey('meal-diary-entry-note-preview-$entryId'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );

    return Stack(
      children: [
        Semantics(
          container: true,
          button: tap != null,
          label: accessibilityLabel,
          onTap: tap,
          // The wrapping node owns the card's one accessible tap action and
          // deliberately represents the visible title, time, details and note.
          // Excluding the TioCard subtree prevents its InkWell from exposing a
          // second tap node; the separate overflow sibling remains reachable.
          excludeSemantics: true,
          child: TioCard(
            key: ValueKey('meal-diary-entry-$entryId'),
            variant: TioCardVariant.normal,
            // The media fills the card's own leading corner, so the card
            // carries no padding and the content column owns its inset.
            padding: EdgeInsets.zero,
            onTap: tap,
            child: SizedBox(
              height: TioSize.dp120,
              child: Row(
                children: [
                  _MealMedia(entryId: entryId, timeText: timeText),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: TioSpacing.lg,
                        end: TioSpacing.lg,
                        bottom: TioSpacing.xs,
                      ),
                      child: detail,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (edit != null)
          PositionedDirectional(
            top: TioSpacing.none,
            end: TioSpacing.none,
            child: MealLogActionsPopup(entryId: entryId, onEdit: edit),
          ),
      ],
    );
  }
}

class _MealMedia extends StatelessWidget {
  const _MealMedia({required this.entryId, required this.timeText});

  final String entryId;
  final String? timeText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return ClipRRect(
      // Only the card's own corner is rounded; the other side runs straight
      // into the content so the slot belongs to the card rather than floating
      // inside it.
      borderRadius: const BorderRadiusDirectional.horizontal(
        start: Radius.circular(TioCardTokens.radius),
      ),
      child: SizedBox.square(
        key: ValueKey('meal-diary-entry-media-$entryId'),
        dimension: TioSize.dp120,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: colors.surfaceVariant,
              child: Icon(
                Icons.restaurant_outlined,
                key: ValueKey('meal-diary-entry-fallback-icon-$entryId'),
                size: TioSize.dp40,
                color: colors.textSecondary,
                semanticLabel: 'Meal image unavailable',
              ),
            ),
            if (timeText != null)
              Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: DecoratedBox(
                  // A scrim, not a badge: the fade reads as part of the media
                  // surface and keeps the same contrast once a real image
                  // replaces the fallback. An opaque pill would read as a
                  // control, and time is informational.
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.mediaBackground.withValues(
                          alpha: TioOpacity.opacity0,
                        ),
                        colors.mediaBackground.withValues(
                          alpha: TioOpacity.opacity60,
                        ),
                      ],
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: TioSpacing.lg,
                        left: TioSpacing.xs,
                        right: TioSpacing.xs,
                        bottom: TioSpacing.xs,
                      ),
                      child: Text(
                        timeText!,
                        key: ValueKey('meal-diary-entry-time-$entryId'),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onMediaPrimary,
                              fontWeight: TioFontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MealDetailRow extends StatelessWidget {
  const _MealDetailRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final bodyMedium = Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.only(bottom: TioSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: TioSpacing.sm),
          Text(
            value,
            textAlign: TextAlign.end,
            style: bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
