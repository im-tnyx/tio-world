import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// The minimum Meal Diary-specific Settings shell.
///
/// This first slice exposes only the Meal Categories navigation boundary. It
/// owns no category state and deliberately omits later Diary preferences.
class MealDiarySettingsPage extends StatelessWidget {
  const MealDiarySettingsPage({
    required this.onMealCategoriesPressed,
    super.key,
  });

  final VoidCallback onMealCategoriesPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

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
          ],
        ),
      ),
    );
  }
}
