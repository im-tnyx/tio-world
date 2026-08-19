import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class NutritionIntroScreen extends StatelessWidget {
  const NutritionIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: 'Set up your nutrition flow',
          subtitle:
              'We will calculate your personalized energy targets and daily habits based on your profile.',
        ),
        const SizedBox(height: TioSpacing.xl),

        // Feature Highlights List (Clean non-clickable format)
        _FeatureHighlightRow(
          icon: Icons.restaurant_outlined,
          title: 'Daily Calories & Macros',
          description:
              'Custom protein, carbohydrate, and fat targets tailored to your body and goal pace.',
          colors: colors,
          textTheme: textTheme,
        ),
        const SizedBox(height: TioSpacing.lg),

        _FeatureHighlightRow(
          icon: Icons.water_drop_outlined,
          title: 'Hydration & Daily Activity',
          description:
              'Personalized daily water intake and step targets to keep your metabolism active.',
          colors: colors,
          textTheme: textTheme,
        ),
        const SizedBox(height: TioSpacing.lg),

        _FeatureHighlightRow(
          icon: Icons.bedtime_outlined,
          title: 'Sleep & Recovery',
          description:
              'Optimal sleep schedule recommendations to maximize muscle recovery and energy.',
          colors: colors,
          textTheme: textTheme,
        ),

        const SizedBox(height: TioSpacing.xl),

        // Privacy note at bottom
        Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: TioSize.dp16,
              color: colors.textSecondary.withValues(
                alpha: TioOpacity.opacity70,
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Expanded(
              child: Text(
                'Your nutrition and body data is private and secure.',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: TioFontSize.size12,
                  color: colors.textSecondary.withValues(
                    alpha: TioOpacity.opacity70,
                  ),
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
          width: TioSize.dp44,
          height: TioSize.dp44,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: TioOpacity.opacity12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: TioSize.dp22,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: TioSize.dp14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: TioFontSize.size15,
                  fontWeight: TioFontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: TioSpacing.xs),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: TioFontSize.size13,
                  height: TioLineHeight.height135,
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
