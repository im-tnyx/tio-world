import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/domain.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    required this.draft,
    required this.flowPlan,
    required this.completionEligibility,
    super.key,
  });

  final OnboardingDraft draft;
  final OnboardingFlowPlan flowPlan;
  final OnboardingCompletionEligibility completionEligibility;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final profile = draft.profile;
    final blockers = completionEligibility.blockingSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: 'Review setup',
          subtitle: 'Check the real onboarding details captured so far before '
              'the final completion boundary runs.',
        ),
        const SizedBox(height: TioSpacing.extraLarge),
        _ReviewCard(
          title: 'App Mode',
          children: [
            _SummaryRow(label: 'Mode', value: _modeLabel(draft.selectedMode)),
            if (draft.selectedMode == AppMode.hybrid &&
                draft.workoutIntroChoice != null) ...[
              const SizedBox(height: TioSpacing.medium),
              _SummaryRow(
                label: 'Workout setup',
                value: switch (draft.workoutIntroChoice!) {
                  WorkoutIntroChoice.setupNow => 'Set up now',
                  WorkoutIntroChoice.later => 'Later',
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: TioSpacing.large),
        _ReviewCard(
          title: 'Profile',
          children: [
            _SummaryRow(label: 'Name', value: profile.name.trim()),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Gender',
              value: profile.gender == null
                  ? 'Not selected'
                  : _genderLabel(profile.gender!),
            ),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Goal',
              value: profile.goals.isEmpty
                  ? 'Not selected'
                  : profile.goals.map(_goalLabel).join(', '),
            ),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Date of birth',
              value: profile.dateOfBirth == null
                  ? 'Not selected'
                  : _formatDate(profile.dateOfBirth!),
            ),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Height',
              value: profile.heightCm == null
                  ? 'Not selected'
                  : '${profile.heightCm!.round()} cm',
            ),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Current weight',
              value: profile.currentWeightKg == null
                  ? 'Not selected'
                  : '${profile.currentWeightKg!.toStringAsFixed(0)} kg',
            ),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Target weight',
              value: profile.targetWeightKg == null
                  ? 'Not selected'
                  : '${profile.targetWeightKg!.toStringAsFixed(0)} kg',
            ),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Activity',
              value: profile.activityLevel == null
                  ? 'Not selected'
                  : _activityLabel(profile.activityLevel!),
            ),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Health summary',
              value: _healthSummary(profile),
            ),
          ],
        ),
        const SizedBox(height: TioSpacing.large),
        _ReviewCard(
          title: 'Daily Targets',
          children: [
            _SummaryRow(
              label: 'Steps',
              value: '${draft.targets.dailySteps} steps/day',
            ),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Sleep',
              value: '${draft.targets.sleepTargetMinutes ~/ 60}h '
                  '${(draft.targets.sleepTargetMinutes % 60).toString().padLeft(2, '0')}m / night',
            ),
            const SizedBox(height: TioSpacing.medium),
            _SummaryRow(
              label: 'Hydration',
              value: '${draft.targets.waterMl} ml/day',
            ),
            if (GoalPaceResolver.resolveMode(
                  currentWeightKg: profile.currentWeightKg,
                  targetWeightKg: profile.targetWeightKg,
                ) !=
                GoalPaceMode.maintenance) ...[
              const SizedBox(height: TioSpacing.medium),
              _SummaryRow(
                label: 'Goal pace',
                value: '${draft.targets.goalPaceKgPerWeek.toStringAsFixed(1)} kg/week',
              ),
            ],
            if (const CalculateNutritionTargetRecommendationUseCase()(
                  profile: profile,
                  targets: draft.targets,
                )
                case NutritionTargetRecommendationSuccess(:final recommendation)) ...[
              const SizedBox(height: TioSpacing.medium),
              _SummaryRow(
                label: 'Nutrition target',
                value: '${recommendation.caloriesKcal} kcal '
                    '(${recommendation.proteinGrams}g P / '
                    '${recommendation.carbsGrams}g C / '
                    '${recommendation.fatGrams}g F)',
              ),
            ],
          ],
        ),
        const SizedBox(height: TioSpacing.large),
        _ReviewCard(
          title: 'Current flow truth',
          children: [
            Text(
              'Only real onboarding data is summarized here. Compatibility '
              'preview steps are not treated as saved configuration.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            if (!completionEligibility.isEligible &&
                completionEligibility.message != null) ...[
              const SizedBox(height: TioSpacing.large),
              Semantics(
                liveRegion: true,
                child: Text(
                  completionEligibility.message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
              if (blockers.isNotEmpty) ...[
                const SizedBox(height: TioSpacing.medium),
                for (final step in blockers) ...[
                  _SummaryRow(
                    label: 'Pending',
                    value: step.progressTitle,
                  ),
                  const SizedBox(height: TioSpacing.small),
                ],
              ],
            ],
          ],
        ),
        const SizedBox(height: TioSpacing.extraLarge),
        if (_compatibilityFooter(blockers) case final footer?)
          Text(
            footer,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
      ],
    );
  }
}

String? _compatibilityFooter(List<OnboardingStepDefinition> blockers) {
  final blockerIds = blockers.map((step) => step.id).toSet();
  final hasNutrition = blockerIds.contains(OnboardingStepId.nutritionIntro) ||
      blockerIds.contains(OnboardingStepId.nutritionPreferences);
  final hasTargets = blockerIds.contains(OnboardingStepId.targets);

  if (hasNutrition && hasTargets) {
    return 'Nutrition and Targets remain compatibility previews in this slice.';
  }
  if (hasNutrition) {
    return 'Nutrition remains a compatibility preview in this slice.';
  }
  if (hasTargets) {
    return 'Targets remain a compatibility preview in this slice.';
  }
  return null;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TioSpacing.large),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.radiusLarge),
        border: Border.all(color: colors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: TioSpacing.medium),
          ...children,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(width: TioSpacing.medium),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

String _modeLabel(AppMode? mode) {
  if (mode == null) return 'Not selected';

  return switch (mode) {
    AppMode.workout => 'Workout',
    AppMode.nutrition => 'Nutrition',
    AppMode.hybrid => 'Hybrid',
  };
}

String _genderLabel(ProfileGender gender) {
  return switch (gender) {
    ProfileGender.male => 'Male',
    ProfileGender.female => 'Female',
    ProfileGender.other => 'Other',
  };
}

String _goalLabel(ProfileGoal goal) {
  return switch (goal) {
    ProfileGoal.loseWeight => 'Lose weight',
    ProfileGoal.buildMuscle => 'Build muscle',
    ProfileGoal.keepFit => 'Keep fit',
    ProfileGoal.boostStrength => 'Boost strength',
    ProfileGoal.manageStress => 'Manage stress',
  };
}

String _activityLabel(ProfileActivityLevel activity) {
  return switch (activity) {
    ProfileActivityLevel.sedentary => 'Sedentary',
    ProfileActivityLevel.light => 'Light',
    ProfileActivityLevel.active => 'Active',
    ProfileActivityLevel.veryActive => 'Very active',
    ProfileActivityLevel.dynamic => 'Dynamic',
  };
}

String _healthSummary(ProfileOnboardingDraft profile) {
  final conditions = profile.healthConditions;
  if (conditions.isEmpty || conditions.contains(ProfileHealthCondition.none)) {
    return 'No health conditions selected';
  }
  if (conditions.contains(ProfileHealthCondition.other) &&
      profile.otherHealthCondition.trim().isNotEmpty) {
    return 'Health detail provided';
  }
  return 'Health conditions selected';
}

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
