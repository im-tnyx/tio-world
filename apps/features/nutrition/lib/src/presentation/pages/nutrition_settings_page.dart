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
            _NutritionSettingsGroupCard(
              children: [
                _NutritionSettingsTile(
                  key: const ValueKey('nutrition-settings-profile-entry'),
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Nutrition Profile',
                  subtitle: 'Diet Type, allergies & restrictions',
                  onTap: onNutritionProfilePressed,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _NutritionSettingsSectionHeader(title: 'DAILY TARGETS'),
            _NutritionSettingsGroupCard(
              children: [
                _NutritionSettingsTile(
                  key: const ValueKey('nutrition-settings-targets-entry'),
                  icon: Icons.track_changes_rounded,
                  title: 'Nutrition Targets',
                  subtitle: 'Calories, protein, carbs, fat & fiber',
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

class _NutritionSettingsGroupCard extends StatelessWidget {
  const _NutritionSettingsGroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(TioRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _NutritionSettingsTile extends StatelessWidget {
  const _NutritionSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
            Container(
              width: TioSize.dp40,
              height: TioSize.dp40,
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(TioAlpha.alpha18),
                borderRadius: BorderRadius.circular(TioRadius.sm),
              ),
              child: Icon(icon, size: TioSize.dp22, color: colors.primary),
            ),
            const SizedBox(width: TioSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.xxs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size12,
                      fontWeight: TioFontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
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
