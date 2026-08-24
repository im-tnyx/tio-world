import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  test('training-only target below current persists target-derived loss without ranked Body card', () {
    final result = const BodySetupMapper().map(
      OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.getStronger,
        ),
        profile: ProfileOnboardingDraft(
          currentWeightKg: 80,
          targetWeightKg: 75,
          targetWeightDirection: GoalWeightDirection.loss,
        ),
        targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
      ),
    );

    expect(result.activeGoal?.goalType, body_owner.BodyGoalType.loseWeight);
    expect(result.activeGoal?.targetWeightKg, 75);
    expect(result.activeGoal?.weeklyWeightChangeKg, 0.5);
    expect(result.activeGoal?.intentRank, isNull);
  });

  test('training-only target above current persists target-derived gain', () {
    final result = const BodySetupMapper().map(
      OnboardingDraft(
        selectedMode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.improveEndurance,
        ),
        profile: ProfileOnboardingDraft(
          currentWeightKg: 70,
          targetWeightKg: 74,
          targetWeightDirection: GoalWeightDirection.gain,
        ),
        targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.3),
      ),
    );

    expect(result.activeGoal?.goalType, body_owner.BodyGoalType.gainWeight);
    expect(result.activeGoal?.intentRank, isNull);
  });

  test('Maintain plus training never leaks dormant target or pace into Body owner', () {
    final result = const BodySetupMapper().map(
      OnboardingDraft(
        selectedMode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
          supportingGoal: GoalIntent.buildMuscle,
          tertiaryGoal: GoalIntent.getStronger,
        ),
        profile: ProfileOnboardingDraft(
          currentWeightKg: 80,
          targetWeightKg: 75,
          targetWeightDirection: GoalWeightDirection.loss,
        ),
        targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
      ),
    );

    expect(result.activeGoal?.goalType, body_owner.BodyGoalType.maintainWeight);
    expect(result.activeGoal?.targetWeightKg, isNull);
    expect(result.activeGoal?.weeklyWeightChangeKg, isNull);
  });

  test('Body plus two training selections map both canonical Workout priorities', () {
    final result = const WorkoutTargetsMapper().map(
      OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.buildMuscle,
          tertiaryGoal: GoalIntent.getStronger,
        ),
      ),
    );

    expect(result.primaryWorkoutGoal, workout_owner.WorkoutTargetGoal.buildMuscle);
    expect(result.primaryGoalRank, 1);
    expect(result.supportingWorkoutGoal, workout_owner.WorkoutTargetGoal.getStronger);
    expect(result.supportingGoalRank, 2);
  });

  test('zero-delta target cannot establish Goal Pace direction', () {
    const policy = WeightGoalFlowPolicy();
    const selection = GoalIntentSelection(primaryGoal: GoalIntent.keepFit);

    expect(
      policy.effectiveDirectionFor(
        mode: AppMode.workout,
        selection: selection,
        currentWeightKg: 80,
        targetWeightKg: 80,
      ),
      isNull,
    );

    final profileError = const ProfileStepValidator().validate(
      ProfileOnboardingDraft(
        currentStepId: ProfileStepId.targetWeight,
        currentWeightKg: 80,
        targetWeightKg: 80,
      ),
      weightGoalDirection: null,
    );
    expect(profileError[ProfileStepId.targetWeight], contains('above or below'));
  });
}
