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
    final textTheme = Theme.of(context).textTheme;
    final profile = draft.profile;
    final workout = draft.workout;
    final blockers = completionEligibility.blockingSteps;
    final goalSummary = draft.goalSelection.goals.map(_goalIntentLabel).join(', ');
    final weightGoalDirection = const WeightGoalFlowPolicy().directionFor(
      mode: draft.selectedMode,
      selection: draft.goalSelection,
    );
    final targetWeightIsActive = weightGoalDirection != null &&
        profile.targetWeightDirection == weightGoalDirection;
    final activeTargetWeightKg =
        targetWeightIsActive ? profile.targetWeightKg : null;
    final effectiveProfile = targetWeightIsActive
        ? profile
        : profile.copyWith(clearTargetWeightKg: true);
    final effectiveTargets = weightGoalDirection == null
        ? draft.targets.copyWith(goalPaceKgPerWeek: 0.0)
        : draft.targets;

    final hasWorkoutPreferences = draft.selectedMode != AppMode.nutrition &&
        draft.workoutIntroChoice != WorkoutIntroChoice.later &&
        workout.gymAccess != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: 'Review your plan',
          subtitle:
              'Everything is set up to match your personal goals. Take a quick look before we begin.',
        ),
        const SizedBox(height: TioSpacing.lg),
        _ReviewCard(
          title: 'Profile & Goals',
          icon: Icons.person_outline_rounded,
          children: [
            _SummaryRow(
              label: 'Name',
              value: profile.name.trim().isEmpty ? 'Not set' : profile.name.trim(),
            ),
            const SizedBox(height: TioSize.dp10),
            _SummaryRow(
              label: 'Gender',
              value: profile.gender == null
                  ? 'Not selected'
                  : _genderLabel(profile.gender!),
            ),
            const SizedBox(height: TioSize.dp10),
            _SummaryRow(
              label: 'Goals',
              value: goalSummary.isEmpty ? 'Not selected' : goalSummary,
            ),
            const SizedBox(height: TioSize.dp10),
            _SummaryRow(
              label: 'Date of birth',
              value: profile.dateOfBirth == null
                  ? 'Not selected'
                  : _formatDate(profile.dateOfBirth!),
            ),
            const SizedBox(height: TioSize.dp10),
            _SummaryRow(
              label: 'Height',
              value: profile.heightCm == null
                  ? 'Not selected'
                  : '${profile.heightCm!.round()} cm',
            ),
            const SizedBox(height: TioSize.dp10),
            _SummaryRow(
              label: 'Weight plan',
              value: profile.currentWeightKg == null
                  ? 'Not selected'
                  : activeTargetWeightKg != null
                      ? '${profile.currentWeightKg!.toStringAsFixed(1)} kg ➔ ${activeTargetWeightKg.toStringAsFixed(1)} kg'
                      : '${profile.currentWeightKg!.toStringAsFixed(1)} kg',
            ),
            const SizedBox(height: TioSize.dp10),
            _SummaryRow(
              label: 'Activity',
              value: profile.activityLevel == null
                  ? 'Not selected'
                  : _activityLabel(profile.activityLevel!),
            ),
            if (profile.healthConditions.isNotEmpty &&
                !profile.healthConditions.contains(ProfileHealthCondition.none)) ...[
              const SizedBox(height: TioSize.dp10),
              _SummaryRow(
                label: 'Health info',
                value: _healthSummary(profile),
              ),
            ],
          ],
        ),
        const SizedBox(height: TioSpacing.md),
        _ReviewCard(
          title: 'Daily Targets',
          icon: Icons.track_changes_rounded,
          children: [
            _SummaryRow(
              label: 'Steps',
              value: '${draft.targets.dailySteps} steps/day',
            ),
            const SizedBox(height: TioSize.dp10),
            _SummaryRow(
              label: 'Hydration',
              value: '${draft.targets.waterMl} ml/day',
            ),
            const SizedBox(height: TioSize.dp10),
            _SummaryRow(
              label: 'Sleep',
              value:
                  '${draft.targets.sleepTargetMinutes ~/ 60}h ${(draft.targets.sleepTargetMinutes % 60).toString().padLeft(2, '0')}m / night',
            ),
            if (weightGoalDirection != null) ...[
              const SizedBox(height: TioSize.dp10),
              _SummaryRow(
                label: 'Goal pace',
                value:
                    '${draft.targets.goalPaceKgPerWeek.toStringAsFixed(1)} kg / week',
              ),
            ],
            if (const CalculateNutritionTargetRecommendationUseCase()(
                  profile: effectiveProfile,
                  targets: effectiveTargets,
                )
                case NutritionTargetRecommendationSuccess(:final recommendation)) ...[
              const SizedBox(height: TioSize.dp10),
              _SummaryRow(
                label: 'Target calories',
                value:
                    '${recommendation.caloriesKcal} kcal (${recommendation.proteinGrams}g P / ${recommendation.carbsGrams}g C / ${recommendation.fatGrams}g F)',
              ),
            ],
          ],
        ),
        if (hasWorkoutPreferences) ...[
          const SizedBox(height: TioSpacing.md),
          _ReviewCard(
            title: 'Workout Plan',
            icon: Icons.fitness_center_rounded,
            children: [
              _SummaryRow(
                label: 'Gym access',
                value: switch (workout.gymAccess!) {
                  WorkoutGymAccess.gym => 'Commercial gym',
                  WorkoutGymAccess.home => 'Home workout',
                },
              ),
              if (workout.workoutSplit != null) ...[
                const SizedBox(height: TioSize.dp10),
                _SummaryRow(
                  label: 'Workout split',
                  value: _splitLabel(workout.workoutSplit!),
                ),
              ],
              if (workout.trainingDays.isNotEmpty) ...[
                const SizedBox(height: TioSize.dp10),
                _SummaryRow(
                  label: 'Training days',
                  value: '${workout.trainingDays.length} days / week',
                ),
              ],
              if (workout.workoutDuration != null) ...[
                const SizedBox(height: TioSize.dp10),
                _SummaryRow(
                  label: 'Session duration',
                  value: _durationLabel(workout.workoutDuration!),
                ),
              ],
              if (workout.focusAreas.isNotEmpty) ...[
                const SizedBox(height: TioSize.dp10),
                _SummaryRow(
                  label: 'Focus areas',
                  value: workout.focusAreas.map(_focusAreaLabel).join(', '),
                ),
              ],
            ],
          ),
        ],
        if (!completionEligibility.isEligible &&
            completionEligibility.message != null) ...[
          const SizedBox(height: TioSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TioSpacing.md),
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: TioOpacity.opacity12),
              borderRadius: BorderRadius.circular(TioRadius.md),
              border: Border.all(
                color: colors.danger.withValues(alpha: TioOpacity.opacity30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: TioSize.dp18,
                      color: colors.danger,
                    ),
                    const SizedBox(width: TioSize.dp6),
                    Text(
                      'Setup Incomplete',
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.danger,
                        fontWeight: TioFontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TioSize.dp6),
                Text(
                  completionEligibility.message!,
                  style: textTheme.bodySmall?.copyWith(color: colors.danger),
                ),
                if (blockers.isNotEmpty) ...[
                  const SizedBox(height: TioSpacing.sm),
                  for (final step in blockers)
                    Padding(
                      padding: const EdgeInsets.only(top: TioSpacing.xxs),
                      child: Text(
                        '• ${step.progressTitle}',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.danger,
                          fontWeight: TioFontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: TioSpacing.lg),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return TioCard(
      variant: TioCardVariant.elevated,
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSize.dp14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: TioSize.dp18, color: colors.primary),
              const SizedBox(width: TioSpacing.sm),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: TioFontWeight.w700,
                  color: colors.textPrimary,
                  fontSize: TioFontSize.size15,
                ),
              ),
            ],
          ),
          const SizedBox(height: TioSize.dp10),
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
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: TioSize.dp105,
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: TioFontWeight.w500,
              fontSize: TioFontSize.size13,
            ),
          ),
        ),
        const SizedBox(width: TioSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w600,
              fontSize: TioFontSize.size13,
            ),
          ),
        ),
      ],
    );
  }
}

String _genderLabel(ProfileGender gender) {
  return switch (gender) {
    ProfileGender.male => 'Male',
    ProfileGender.female => 'Female',
    ProfileGender.other => 'Other',
  };
}

String _goalIntentLabel(GoalIntent goal) {
  return switch (goal) {
    GoalIntent.loseWeight => 'Lose weight',
    GoalIntent.gainWeight => 'Gain weight',
    GoalIntent.maintainWeight => 'Maintain weight',
    GoalIntent.recomposition => 'Recomposition',
    GoalIntent.buildMuscle => 'Build muscle',
    GoalIntent.getStronger => 'Get stronger',
    GoalIntent.improveEndurance => 'Improve endurance',
    GoalIntent.stayFit => 'Stay fit',
  };
}

String _activityLabel(ProfileActivityLevel activity) {
  return switch (activity) {
    ProfileActivityLevel.sedentary => 'Sedentary',
    ProfileActivityLevel.light => 'Lightly active',
    ProfileActivityLevel.active => 'Active',
    ProfileActivityLevel.veryActive => 'Very active',
    ProfileActivityLevel.dynamic => 'Highly dynamic',
  };
}

String _splitLabel(WorkoutSplit split) {
  return switch (split) {
    WorkoutSplit.auto => 'Auto-balanced',
    WorkoutSplit.fullBody => 'Full body',
    WorkoutSplit.upperLower => 'Upper / Lower',
    WorkoutSplit.ppl => 'Push / Pull / Legs',
    WorkoutSplit.bodyPart => 'Body part split',
  };
}

String _durationLabel(WorkoutDuration duration) {
  return switch (duration) {
    WorkoutDuration.auto => 'Optimal duration',
    WorkoutDuration.thirtyMinutes => '30 min',
    WorkoutDuration.sixtyMinutes => '60 min',
    WorkoutDuration.ninetyMinutes => '90 min',
    WorkoutDuration.oneHundredTwentyMinutes => '120 min',
  };
}

String _focusAreaLabel(WorkoutFocusArea area) {
  return switch (area) {
    WorkoutFocusArea.fullBody => 'Full body',
    WorkoutFocusArea.shoulders => 'Shoulders',
    WorkoutFocusArea.arms => 'Arms',
    WorkoutFocusArea.back => 'Back',
    WorkoutFocusArea.chest => 'Chest',
    WorkoutFocusArea.abs => 'Abs & Core',
    WorkoutFocusArea.glutes => 'Glutes',
    WorkoutFocusArea.legs => 'Legs',
    WorkoutFocusArea.cardio => 'Cardio',
  };
}

String _healthSummary(ProfileOnboardingDraft profile) {
  final conditions = profile.healthConditions;
  if (conditions.isEmpty || conditions.contains(ProfileHealthCondition.none)) {
    return 'None';
  }
  if (conditions.contains(ProfileHealthCondition.other) &&
      profile.otherHealthCondition.trim().isNotEmpty) {
    return profile.otherHealthCondition.trim();
  }
  return conditions.map((e) => e.name).join(', ');
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
