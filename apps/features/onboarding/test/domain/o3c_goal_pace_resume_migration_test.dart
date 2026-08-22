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

    test('pace edits invalidate Body Goal while Wellness edits invalidate Wellness',
        () {
      final bodyGoalController = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
          ),
          currentStepId: OnboardingStepId.bodyGoal,
          profile: ProfileOnboardingDraft(
            currentStepId: ProfileStepId.goalPace,
            currentWeightKg: 70,
            targetWeightKg: 64,
            targetWeightDirection: GoalWeightDirection.loss,
          ),
          targets: const TargetsOnboardingDraft(
            currentStepId: TargetStepId.bridge,
            goalPaceKgPerWeek: 0.5,
          ),
          completedStepIds: const {
            OnboardingStepId.profileBasics,
            OnboardingStepId.bodyGoal,
            OnboardingStepId.targets,
          },
        ),
      );

      bodyGoalController.updateGoalPaceKgPerWeek(0.7);

      expect(
        bodyGoalController.state.completedStepIds,
        isNot(contains(OnboardingStepId.bodyGoal)),
      );
      expect(
        bodyGoalController.state.completedStepIds,
        contains(OnboardingStepId.targets),
      );
      expect(
        bodyGoalController.state.draft.completedStepIds,
        isNot(contains(OnboardingStepId.bodyGoal)),
      );
      expect(
        bodyGoalController.state.draft.completedStepIds,
        contains(OnboardingStepId.targets),
      );

      final wellnessController = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
          ),
          currentStepId: OnboardingStepId.targets,
          profile: ProfileOnboardingDraft(
            currentStepId: ProfileStepId.goalPace,
            currentWeightKg: 70,
            targetWeightKg: 64,
            targetWeightDirection: GoalWeightDirection.loss,
          ),
          targets: const TargetsOnboardingDraft(
            currentStepId: TargetStepId.waterTarget,
            goalPaceKgPerWeek: 0.5,
          ),
          completedStepIds: const {
            OnboardingStepId.profileBasics,
            OnboardingStepId.bodyGoal,
            OnboardingStepId.wellnessGoals,
            OnboardingStepId.targets,
          },
        ),
      );

      expect(wellnessController.state.stepId, OnboardingStepId.wellnessGoals);
      wellnessController.updateWaterTargetMl(2800);

      expect(
        wellnessController.state.completedStepIds,
        contains(OnboardingStepId.bodyGoal),
      );
      expect(
        wellnessController.state.completedStepIds,
        isNot(contains(OnboardingStepId.wellnessGoals)),
      );
      expect(
        wellnessController.state.completedStepIds,
        contains(OnboardingStepId.targets),
      );
      expect(
        wellnessController.state.draft.completedStepIds,
        isNot(contains(OnboardingStepId.wellnessGoals)),
      );
      expect(
        wellnessController.state.draft.completedStepIds,
        contains(OnboardingStepId.targets),
      );
    });
  });
}
