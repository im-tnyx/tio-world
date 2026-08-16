import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class NutritionIntroScreen extends StatelessWidget {
  const NutritionIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: 'Set up your nutrition flow',
          subtitle:
              'We will calculate your personalized energy targets and daily habits based on your profile.',
        ),
        const SizedBox(height: TioSpacing.extraLarge),

        // Feature Highlights List (Clean non-clickable format)
        _FeatureHighlightRow(
          icon: Icons.restaurant_outlined,
          title: 'Daily Calories & Macros',
          description:
              'Custom protein, carbohydrate, and fat targets tailored to your body and goal pace.',
          colors: colors,
          textTheme: textTheme,
        ),
        const SizedBox(height: TioSpacing.large),

        _FeatureHighlightRow(
          icon: Icons.water_drop_outlined,
          title: 'Hydration & Daily Activity',
          description:
              'Personalized daily water intake and step targets to keep your metabolism active.',
          colors: colors,
          textTheme: textTheme,
        ),
        const SizedBox(height: TioSpacing.large),

        _FeatureHighlightRow(
          icon: Icons.bedtime_outlined,
          title: 'Sleep & Recovery',
          description:
              'Optimal sleep schedule recommendations to maximize muscle recovery and energy.',
          colors: colors,
          textTheme: textTheme,
        ),

        const SizedBox(height: TioSpacing.extraLarge),

        // Privacy note at bottom
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: colors.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: TioSpacing.small),
            Expanded(
              child: Text(
                'Your nutrition and body data is private and secure.',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureHighlightRow extends StatelessWidget {
  const _FeatureHighlightRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
    required this.textTheme,
  });

  final IconData icon;
  final String title;
  final String description;
  final TioColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: TioSpacing.medium + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.35,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
