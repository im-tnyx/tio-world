import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../controllers/meal_diary_display_preferences_controller.dart';

/// Meal Diary-specific Settings.
///
/// Meal Categories remains a navigation boundary. The three display
/// preferences below are device-local presentation state: they never rewrite
/// durable MealLog timestamps or notes.
class MealDiarySettingsPage extends ConsumerWidget {
  const MealDiarySettingsPage({
    required this.onMealCategoriesPressed,
    super.key,
  });

  final VoidCallback onMealCategoriesPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.tioColors;
    final controller = ref.watch(mealDiaryDisplayPreferencesControllerProvider);
    final preferences = controller.preferences;

    return Scaffold(
      key: const ValueKey('meal-diary-settings-page'),
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Meal Diary Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.lg,
            vertical: TioSpacing.md,
          ),
          children: [
            TioGroupCard(
              children: [
                TioSettingsNavigationRow(
                  key: const ValueKey('meal-diary-settings-categories-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.category_outlined,
                  ),
                  title: 'Meal Categories',
                  supportingText: 'Manage meal categories',
                  onTap: onMealCategoriesPressed,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            TioGroupCard(
              children: [
                _MealDiaryPreferenceToggleRow(
                  key: const ValueKey('meal-diary-settings-show-times'),
                  title: 'Show meal times',
                  value: preferences.showMealTimes,
                  onChanged: controller.setShowMealTimes,
                ),
                const _MealDiarySettingsDivider(),
                _MealDiaryPreferenceToggleRow(
                  key: const ValueKey('meal-diary-settings-meal-notes'),
                  title: 'Meal Notes',
                  value: preferences.mealNotesEnabled,
                  onChanged: controller.setMealNotesEnabled,
                ),
                const _MealDiarySettingsDivider(),
                _MealDiaryPreferenceToggleRow(
                  key: const ValueKey('meal-diary-settings-note-preview'),
                  title: 'Show note preview',
                  value: preferences.showMealNotePreview,
                  enabled: preferences.mealNotesEnabled,
                  onChanged: controller.setShowMealNotePreview,
                ),
              ],
            ),
            if (controller.saveError != null) ...[
              const SizedBox(height: TioSpacing.md),
              Text(
                key: const ValueKey('meal-diary-settings-save-error'),
                'Could not save Meal Diary settings. Your previous saved '
                'preference was restored.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.danger,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Feature-owned toggle composition using the governed Settings row geometry.
///
/// Core does not currently expose a generic settings toggle row. Keeping this
/// one-off composition here avoids inventing a new Core public contract for one
/// screen while still consuming the canonical spacing, typography and colors.
class _MealDiaryPreferenceToggleRow extends StatelessWidget {
  const _MealDiaryPreferenceToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return MergeSemantics(
      child: Semantics(
        enabled: enabled,
        child: InkWell(
          onTap: enabled ? () => onChanged(!value) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.lg,
              vertical: TioSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: enabled ? colors.textPrimary : colors.textMuted,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  ),
                ),
                const SizedBox(width: TioSpacing.lg),
                Switch.adaptive(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealDiarySettingsDivider extends StatelessWidget {
  const _MealDiarySettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: TioStroke.width1,
      thickness: TioStroke.width1,
      indent: TioSpacing.lg,
      endIndent: TioSpacing.lg,
      color: context.tioColors.outlineStrong.withAlpha(TioAlpha.alpha20),
    );
  }
}
