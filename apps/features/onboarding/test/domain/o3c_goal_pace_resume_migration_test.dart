import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O3C Goal Pace resume migration', () {
    test('legacy targets Goal Pace cursor resumes under eligible Body Goal', () {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        currentStepId: OnboardingStepId.targets,
        profile: ProfileOnboardingDraft(
          currentWeightKg: 70,
          targetWeightKg: 64,
          targetWeightDirection: GoalWeightDirection.loss,
        ),
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.goalPace,
          goalPaceKgPerWeek: 0.6,
        ),
      );

      expect(draft.currentStepId, OnboardingStepId.bodyGoal);
      expect(draft.profile.currentStepId, ProfileStepId.goalPace);
      expect(draft.targets.currentStepId, TargetStepId.goalPace);
      expect(draft.targets.goalPaceKgPerWeek, 0.6);

      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: draft,
      );

      expect(controller.state.stepId, OnboardingStepId.bodyGoal);
      expect(
        controller.state.draft.profile.currentStepId,
        ProfileStepId.goalPace,
      );
      expect(controller.state.draft.targets.goalPaceKgPerWeek, 0.6);
      expect(
        controller.state.targetsFlowPlan.contains(TargetStepId.goalPace),
        isFalse,
      );
    });

    test('ineligible legacy Goal Pace cursor clamps without losing pace data', () {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.targets,
        profile: ProfileOnboardingDraft(currentWeightKg: 70),
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.goalPace,
          goalPaceKgPerWeek: 0.6,
        ),
      );

      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: draft,
      );

      expect(controller.state.stepId, OnboardingStepId.bodyGoal);
      expect(
        controller.state.draft.profile.currentStepId,
        ProfileStepId.currentWeight,
      );
      expect(controller.state.draft.targets.goalPaceKgPerWeek, 0.6);
      expect(
        controller.state.bodyGoalFlowPlan.contains(ProfileStepId.goalPace),
        isFalse,
      );
    });
  });
}
