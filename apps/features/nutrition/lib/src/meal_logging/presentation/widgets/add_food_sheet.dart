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
/// meal, with the one that exists today separated from the three that do not.
///
/// The unavailable three are drawn rather than hidden because the sheet is
/// where the reader learns what logging will offer. They are drawn *as*
/// unavailable — dimmed, chevron-less, inert and reported to assistive
/// technology as disabled — because a row that looks live and does nothing is
/// worse than no row at all.
class AddFoodSheet extends StatelessWidget {
  const AddFoodSheet({
    required this.onQuickAdd,
    required this.onDismiss,
    super.key,
  });

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
          const SizedBox(height: TioSpacing.md),
          TioGroupCard(
            children: [
              const _UnavailableAction(
                actionKey: ValueKey('add-food-ai-text'),
                icon: Icons.edit_note_rounded,
                title: 'What did you eat?',
                supportingText: 'Describe a meal in your own words',
                semanticLabel: 'Describe a meal in your own words',
              ),
              const _AddFoodDivider(),
              const _UnavailableAction(
                actionKey: ValueKey('add-food-photo'),
                icon: Icons.photo_camera_outlined,
                title: 'Take a Photo',
                supportingText: 'Read the food from a picture',
                semanticLabel: 'Take a photo of your food',
              ),
              const _AddFoodDivider(),
              TioSettingsNavigationRow(
                key: const ValueKey('add-food-quick-add'),
                leading: const TioSettingsLeadingIcon(
                  icon: Icons.add_rounded,
                ),
                title: 'Quick Add',
                supportingText: 'Enter calories and macros yourself',
                onTap: onQuickAdd,
              ),
              const _AddFoodDivider(),
              const _UnavailableAction(
                actionKey: ValueKey('add-food-search'),
                icon: Icons.search_rounded,
                title: 'Search Food',
                supportingText: 'Find a food in the food database',
                semanticLabel: 'Search the food database',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A path this slice deliberately does not implement.
///
/// The unavailability is said three ways so no single channel carries it
/// alone: the supporting line says it in words, the dimming says it visually,
/// and the semantics node says it to a screen reader. The row itself is
/// wrapped rather than tapped-and-ignored, so there is no callback to
/// accidentally wire up to something later.
class _UnavailableAction extends StatelessWidget {
  const _UnavailableAction({
    required this.actionKey,
    required this.icon,
    required this.title,
    required this.supportingText,
    required this.semanticLabel,
  });

  static const _unavailable = 'Not available yet';

  final Key actionKey;
  final IconData icon;
  final String title;
  final String supportingText;

  /// Spoken instead of the visible title, because a title phrased as a
  /// question — "What did you eat?" — reads badly with the unavailability
  /// sentence appended to it.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      key: actionKey,
      button: true,
      enabled: false,
      label: '$semanticLabel. $_unavailable.',
      child: ExcludeSemantics(
        child: Opacity(
          opacity: TioOpacity.opacity64,
          child: TioSettingsNavigationRow(
            leading: TioSettingsLeadingIcon(
              icon: icon,
              color: colors.textMuted,
            ),
            title: title,
            supportingText: '$supportingText · $_unavailable',
            showChevron: false,
          ),
        ),
      ),
    );
  }
}

/// Matches the separator the Settings groups already use, so an Add Food row
/// and a Settings row do not read as two different list systems.
class _AddFoodDivider extends StatelessWidget {
  const _AddFoodDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Divider(
      height: TioSize.dp1,
      thickness: TioStroke.width1,
      indent: TioSize.dp64,
      color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
    );
  }
}
