import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'targets_screen_components.dart';

class NutritionTargetScreen extends StatelessWidget {
  const NutritionTargetScreen({
    required this.profile,
    required this.targets,
    super.key,
    this.calculator = const CalculateNutritionTargetRecommendationUseCase(),
    this.errorText,
  });

  final ProfileOnboardingDraft profile;
  final TargetsOnboardingDraft targets;
  final CalculateNutritionTargetRecommendationUseCase calculator;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final result = calculator(profile: profile, targets: targets);

    return TargetsScreenScaffold(
      stepId: TargetStepId.nutritionTarget,
      title: 'Nutrition targets',
      description:
          'Your daily energy and macronutrient targets calculated based on '
          'your metabolic baseline and selected goal pace.',
      errorText: errorText,
      child: switch (result) {
        NutritionTargetRecommendationSuccess(:final recommendation) =>
          _NutritionTargetContent(recommendation: recommendation),
        NutritionTargetRecommendationInsufficientInput(:final missingFields) =>
          _InsufficientInputCard(missingFields: missingFields),
        NutritionTargetRecommendationInvalidInput(:final message) =>
          _InvalidInputCard(message: message),
      },
    );
  }
}

class _NutritionTargetContent extends StatelessWidget {
  const _NutritionTargetContent({required this.recommendation});

  final NutritionTargetRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(TioSpacing.lg),
          decoration: BoxDecoration(
            color: colors.nutrition.withValues(alpha: TioOpacity.opacity12),
            borderRadius: BorderRadius.circular(TioRadius.lg),
            border: Border.all(
              color: colors.nutrition.withValues(alpha: TioOpacity.opacity35),
              width: TioStroke.width15,
            ),
          ),
          child: Column(
            children: [
              Text(
                'DAILY CALORIE TARGET',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.nutrition,
                      fontWeight: TioFontWeight.w700,
                      letterSpacing: TioLetterSpacing.positive12,
                    ),
              ),
              const SizedBox(height: TioSpacing.sm),
              Text(
                '${recommendation.caloriesKcal} kcal',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: TioFontWeight.w700,
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: TioSpacing.sm),
              Text(
                'Calculated energy expenditure adjusted for your goal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: TioSpacing.lg),
        _MacroRowCard(
          label: 'Protein',
          value: '${recommendation.proteinGrams} g',
          description: 'Essential for muscle repair and recovery',
          color: colors.workout,
        ),
        const SizedBox(height: TioSpacing.md),
        _MacroRowCard(
          label: 'Carbohydrates',
          value: '${recommendation.carbsGrams} g',
          description: 'Primary energy fuel for daily activity and training',
          color: colors.nutrition,
        ),
        const SizedBox(height: TioSpacing.md),
        _MacroRowCard(
          label: 'Fats',
          value: '${recommendation.fatGrams} g',
          description: 'Supports hormone regulation and vitamin absorption',
          color: colors.warning,
        ),
        const SizedBox(height: TioSpacing.md),
        _MacroRowCard(
          label: 'Dietary Fiber',
          value: '${recommendation.fiberGrams} g',
          description: 'Supports healthy digestion and metabolic health',
          color: colors.textSecondary,
        ),
        const SizedBox(height: TioSpacing.lg),
        Container(
          padding: const EdgeInsets.all(TioSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(TioRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetabolicMetric(
                label: 'BMR Baseline',
                value: '${recommendation.bmr} kcal',
              ),
              Container(
                height: TioSize.dp28,
                width: TioStroke.width1,
                color: colors.outlineStrong.withValues(
                  alpha: TioOpacity.opacity30,
                ),
              ),
              _MetabolicMetric(
                label: 'TDEE Maintenance',
                value: '${recommendation.tdee} kcal',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroRowCard extends StatelessWidget {
  const _MacroRowCard({
    required this.label,
    required this.value,
    required this.description,
    required this.color,
  });

  final String label;
  final String value;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(TioRadius.md),
        border: Border.all(color: colors.surfaceVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: TioFontWeight.w600,
                        color: colors.textPrimary,
                      ),
                ),
                const SizedBox(height: TioSpacing.xxs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: TioSpacing.md),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: TioFontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetabolicMetric extends StatelessWidget {
  const _MetabolicMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textMuted,
              ),
        ),
        const SizedBox(height: TioSpacing.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: TioFontWeight.w700,
                color: colors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _InsufficientInputCard extends StatelessWidget {
  const _InsufficientInputCard({required this.missingFields});

  final Set<String> missingFields;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      padding: const EdgeInsets.all(TioSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(TioRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: colors.info),
              const SizedBox(width: TioSpacing.sm),
              Text(
                'Complete profile required',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: TioFontWeight.w700,
                      color: colors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.md),
          Text(
            'Calorie and macronutrient recommendations require your body stats, '
            'date of birth, gender, and activity level. Please complete previous profile steps.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _InvalidInputCard extends StatelessWidget {
  const _InvalidInputCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      padding: const EdgeInsets.all(TioSpacing.lg),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: TioOpacity.opacity15),
        borderRadius: BorderRadius.circular(TioRadius.lg),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.danger,
            ),
      ),
    );
  }
}
