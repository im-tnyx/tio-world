import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// What the reader asked the Add Food sheet for.
///
/// One value, because one path is implemented. The sheet still *shows* the
/// natural-language, photo and food-search paths, but an unavailable path
/// cannot be chosen, so it has nothing to return. When TNYX-62's remaining
/// paths land they become members here rather than booleans on the caller.
enum MealDiaryAddFoodChoice { quickAdd }

/// Opens the Add Food sheet and reports what was chosen.
///
/// Returns null when the reader backed out. Dismissal is the whole of that
/// outcome: this sheet owns no state, writes nothing, and is not told which
/// day the diary is on, so closing it cannot leave anything behind.
Future<MealDiaryAddFoodChoice?> showMealDiaryAddFoodSheet(
  BuildContext context,
) {
  return showModalBottomSheet<MealDiaryAddFoodChoice>(
    context: context,
    isScrollControlled: true,
    // The Meal Diary lives inside a shell branch navigator while the app bar
    // and bottom navigation sit outside it. A sheet on the branch navigator
    // would leave the Today action and the tabs live behind the barrier, so a
    // reader could change the diary's day — or leave for another tab — with
    // this sheet still open on top of it. The root navigator covers the shell.
    useRootNavigator: true,
    // Without this the route applies `MediaQuery.removePadding(removeTop:
    // true)`, so no inner `SafeArea` can protect the top however it is
    // configured — and a sheet tall enough to reach the top of a short or
    // split-screen viewport puts its title and close button under the status
    // bar or a display cutout. Flutter's own wrapper is `SafeArea(bottom:
    // false)`, which leaves the bottom to the inner one below rather than
    // padding it twice.
    useSafeArea: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: AddFoodSheet(
          onQuickAdd: () => Navigator.of(sheetContext)
              .pop(MealDiaryAddFoodChoice.quickAdd),
          onDismiss: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    ),
  );
}

/// The Add Food surface: the four ways N5 will eventually let someone log a
/// meal, weighted the way TNYX-62 specifies rather than flattened into a list.
///
/// ```text
/// Add Food                                   ×
/// ┌─────────────────────────────────────────┐
/// │ What did you eat?                    🎙 │   describe it
/// └─────────────────────────────────────────┘
/// ┌─────────────────────────────────────────┐
/// │ 📷  Take a Photo                        │   or show it
/// └─────────────────────────────────────────┘
/// ┌──────────────────┐ ┌────────────────────┐
/// │ +  Quick Add     │ │ 🔍  Search Food    │   or do it yourself
/// └──────────────────┘ └────────────────────┘
/// ```
///
/// The shape carries the meaning. Describing a meal is the way most meals will
/// be logged, so it is the largest thing on the sheet and looks like somewhere
/// to type. A photo is the second way, so it gets a card of its own. Quick Add
/// and Search are the deliberate manual fallbacks, so they share one compact
/// row. Rendering all four as equal rows — which is what this sheet did before
/// device review — throws that away and makes the reader read four options
/// instead of seeing one.
///
/// Only Quick Add works today. The other three are drawn as unavailable —
/// dimmed, inert, saying so in their own copy and reported disabled to
/// assistive technology — because the sheet is where the reader learns what
/// logging will offer, and a row that looks live and does nothing is worse
/// than no row at all.
class AddFoodSheet extends StatelessWidget {
  const AddFoodSheet({
    required this.onQuickAdd,
    required this.onDismiss,
    super.key,
  });

  /// Said in the copy, not only in the dimming, and repeated in semantics.
  static const unavailable = 'Not available yet';

  final VoidCallback onQuickAdd;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return TioSheet(
      key: const ValueKey('meal-diary-add-food-sheet'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add Food',
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('meal-diary-add-food-close'),
                tooltip: 'Close',
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.sm),
          const _DescribeMealSurface(),
          const SizedBox(height: TioSpacing.md),
          const _PhotoCard(),
          const SizedBox(height: TioSpacing.md),
          // Intrinsic height so the two compact cards match whichever of them
          // wraps onto more lines — on a narrow phone that is usually the one
          // with the longer label, and a short card beside a tall one reads as
          // a mistake.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _CompactAction(
                    actionKey: const ValueKey('add-food-quick-add'),
                    icon: Icons.add_rounded,
                    title: 'Quick Add',
                    supportingText: 'Calories and macros',
                    semanticLabel: 'Quick Add. Calories and macros.',
                    onTap: onQuickAdd,
                  ),
                ),
                const SizedBox(width: TioSpacing.md),
                const Expanded(
                  child: _CompactAction(
                    actionKey: ValueKey('add-food-search'),
                    icon: Icons.search_rounded,
                    title: 'Search Food',
                    supportingText: unavailable,
                    semanticLabel: 'Search Food. $unavailable.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The natural-language entry point: the primary way N5 expects meals to be
/// logged, so it is the one element on the sheet shaped like somewhere to type.
///
/// It is an outlined card rather than a real `TioInput` because it has to hold
/// a prompt, a hint line and a microphone at once, which is not the single-line
/// contract the generic field owns, and because there is nothing to type into
/// yet. The parsing behind it belongs to TNYX-62; giving the field a keyboard
/// now would collect a sentence and drop it.
class _DescribeMealSurface extends StatelessWidget {
  const _DescribeMealSurface();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: TioOpacity.opacity64,
      child: TioCard(
        variant: TioCardVariant.outlined,
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                key: const ValueKey('add-food-ai-text'),
                enabled: false,
                label: 'What did you eat? Describe your meal. '
                    '${AddFoodSheet.unavailable}.',
                child: ExcludeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Decorative, and inside the excluded region on purpose:
                      // it says what kind of surface this is, the same way a
                      // field's leading icon does. It is not a second control,
                      // so it gets no semantics node and no tap of its own —
                      // typing is TNYX-62's to switch on.
                      Padding(
                        padding: const EdgeInsets.only(top: TioSpacing.xxs),
                        child: Icon(
                          Icons.keyboard_alt_outlined,
                          size: TioSize.dp22,
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(width: TioSpacing.md),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What did you eat?',
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.textPrimary,
                                fontWeight: TioFontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: TioSpacing.xxs),
                            Text(
                              'Describe your meal · ${AddFoodSheet.unavailable}',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: TioFontSize.size12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Semantics(
              key: const ValueKey('add-food-voice'),
              button: true,
              enabled: false,
              label: 'Voice input. ${AddFoodSheet.unavailable}.',
              child: ExcludeSemantics(
                child: Container(
                  width: TioSize.dp40,
                  height: TioSize.dp40,
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_none_rounded,
                    size: TioSize.dp22,
                    color: colors.textMuted,
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

/// The second capture route, on a card of its own so it stays clearly above
/// the two manual fallbacks and clearly below the describe-it surface.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      key: const ValueKey('add-food-photo'),
      button: true,
      enabled: false,
      label: 'Take a Photo. ${AddFoodSheet.unavailable}.',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: TioOpacity.opacity64,
          child: TioCard(
            variant: TioCardVariant.normal,
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: TioSize.dp22,
                  color: colors.textMuted,
                ),
                const SizedBox(width: TioSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Take a Photo',
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: TioFontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.xxs),
                      Text(
                        'Analyze food from a photo · '
                        '${AddFoodSheet.unavailable}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: TioFontSize.size12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the two manual fallbacks that share the bottom row.
///
/// [onTap] null is the unavailable state: no ripple, no callback, dimmed, and
/// disabled to assistive technology. There is no separate `enabled` flag,
/// because an action with nowhere to go and an action that is switched off are
/// the same thing here.
class _CompactAction extends StatelessWidget {
  const _CompactAction({
    required this.actionKey,
    required this.icon,
    required this.title,
    required this.supportingText,
    required this.semanticLabel,
    this.onTap,
  });

  final Key actionKey;
  final IconData icon;
  final String title;
  final String supportingText;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = onTap != null;
    final iconColor = isEnabled ? colors.primary : colors.textMuted;

    final card = TioCard(
      variant: TioCardVariant.normal,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: TioSize.dp20, color: iconColor),
              const SizedBox(width: TioSpacing.sm),
              Flexible(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.xxs),
          Text(
            supportingText,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size12,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      key: actionKey,
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      onTap: onTap,
      child: ExcludeSemantics(
        child: isEnabled
            ? card
            : Opacity(opacity: TioOpacity.opacity64, child: card),
      ),
    );
  }
}
