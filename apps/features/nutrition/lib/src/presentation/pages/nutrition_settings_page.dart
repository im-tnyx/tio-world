import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Nutrition-owned Settings hub reached from the generic Settings launcher.
///
/// V1 exposes only the capability that is actually implemented. Nutrition
/// Targets, Eating Style, Nutrition Approach, Meal Diary settings and Diet
/// Plan are deliberately absent rather than shown as inert placeholder rows.
class NutritionSettingsPage extends StatelessWidget {
  const NutritionSettingsPage({
    required this.onNutritionProfilePressed,
    required this.onNutritionTargetsPressed,
    super.key,
  });

  final VoidCallback onNutritionProfilePressed;
  final VoidCallback onNutritionTargetsPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Nutrition & Diet',
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
            Padding(
              padding: const EdgeInsets.only(
                left: TioSpacing.sm,
                right: TioSpacing.sm,
                bottom: TioSpacing.lg,
              ),
              child: Text(
                'Manage the diet context Tio uses to personalise your food '
                'experience.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: TioFontSize.size14,
                  height: TioLineHeight.height145,
                ),
              ),
            ),
            const _NutritionSettingsSectionHeader(title: 'DIET CONTEXT'),
            TioGroupCard(
              children: [
                TioSettingsNavigationRow(
                  key: const ValueKey('nutrition-settings-profile-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.restaurant_menu_rounded,
                  ),
                  title: 'Nutrition Profile',
                  supportingText: 'Diet Type, allergies & restrictions',
                  onTap: onNutritionProfilePressed,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _NutritionSettingsSectionHeader(title: 'DAILY TARGETS'),
            TioGroupCard(
              children: [
                TioSettingsNavigationRow(
                  key: const ValueKey('nutrition-settings-targets-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.track_changes_rounded,
                  ),
                  title: 'Nutrition Targets',
                  supportingText: 'Calories, protein, carbs, fat & fiber',
                  onTap: onNutritionTargetsPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionSettingsSectionHeader extends StatelessWidget {
  const _NutritionSettingsSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.only(
        left: TioSpacing.sm,
        bottom: TioSpacing.sm,
      ),
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
