import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class NutritionIntroScreen extends StatelessWidget {
  const NutritionIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TioScreenHeader(
          title: 'Set up your nutrition flow',
          subtitle: 'We’ll preview your nutrition goals and target setup before '
              'building your personalized daily targets.',
        ),
        SizedBox(height: TioSpacing.extraLarge),
        _NutritionIntroCard(
          icon: Icons.restaurant_menu_outlined,
          title: 'Target-focused',
          description:
              'Daily calories, macros, hydration, and goal pace belong in the upcoming Targets section.',
        ),
        SizedBox(height: TioSpacing.medium),
        _NutritionIntroCard(
          icon: Icons.flag_outlined,
          title: 'Habits & consistency',
          description:
              'Step targets, sleep consistency, and hydration metrics adapt directly to your profile.',
        ),
        SizedBox(height: TioSpacing.medium),
        _NutritionIntroCard(
          icon: Icons.lock_outline,
          title: 'Private by default',
          description:
              'Any nutrition answers collected in this onboarding flow stay in-memory only in this slice.',
        ),
      ],
    );
  }
}

class _NutritionIntroCard extends StatelessWidget {
  const _NutritionIntroCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      container: true,
      child: TioCard(
        variant: TioCardVariant.outlined,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: TioSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: TioSpacing.small),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
