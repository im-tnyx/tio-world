import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O8B Review Back and exact resume cursor matrix', () {
    test('Review resumes exactly and Back chain is canonical for every variant',
        () {
      for (final variant in _variants) {
        final controller = OnboardingController(
          entryPath: OnboardingEntryPath.resumeDraft,
          initialDraft: _reviewDraft(variant),
        );

        expect(
          controller.state.stepId,
          OnboardingStepId.review,
          reason: '${variant.name} should resume at Review',
        );
        expect(
          controller.state.flowPlan.contains(OnboardingStepId.review),
          isTrue,
          reason: variant.name,
        );

        controller.previous();
        expect(
          controller.state.stepId,
          OnboardingStepId.healthConnections,
          reason: '${variant.name} Review Back should reach Health Connections',
        );

        controller.previous();
        final expectedSecondBack = variant.mode == AppMode.workout
            ? OnboardingStepId.workoutTargets
            : OnboardingStepId.nutritionGoals;
        expect(
          controller.state.stepId,
          expectedSecondBack,
          reason: '${variant.name} second Back should reach active predecessor',
        );
        if (variant.mode != AppMode.workout) {
          expect(
            controller.state.draft.targets.currentStepId,
            TargetStepId.nutritionTarget,
            reason: '${variant.name} must restore the active Nutrition Goals cursor',
          );
        }
      }
    });

    test('Wellness valid child cursor resumes exactly', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.maintainWeight,
          ),
          currentStepId: OnboardingStepId.wellnessGoals,
          targets: const TargetsOnboardingDraft(
            currentStepId: TargetStepId.waterTarget,
          ),
        ),
      );

      expect(controller.state.stepId, OnboardingStepId.wellnessGoals);
      expect(
        controller.state.draft.targets.currentStepId,
        TargetStepId.waterTarget,
      );
    });

    test('Nutrition Profile valid child cursor resumes exactly when active', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.maintainWeight,
          ),
          currentStepId: OnboardingStepId.nutritionProfile,
          nutrition: const NutritionOnboardingDraft(
            currentStepId: NutritionProfileStepId.allergiesRestrictions,
            dietType: NutritionDietType.vegetarian,
            allergyRestrictions: {NutritionAllergyRestriction.none},
          ),
        ),
      );

      expect(controller.state.stepId, OnboardingStepId.nutritionProfile);
      expect(
        controller.state.draft.nutrition.currentStepId,
        NutritionProfileStepId.allergiesRestrictions,
      );
      expect(controller.state.draft.nutrition.dietType, NutritionDietType.vegetarian);
      expect(
        controller.state.draft.nutrition.allergyRestrictions,
        {NutritionAllergyRestriction.none},
      );
    });

    test('Workout Profile valid child cursor resumes exactly when active', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.workout,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.stayFit,
          ),
          currentStepId: OnboardingStepId.workoutProfile,
          workout: const WorkoutOnboardingDraft(
            currentStepId: WorkoutStepId.focusAreas,
            gymAccess: WorkoutGymAccess.gym,
            focusAreas: {WorkoutFocusArea.fullBody},
          ),
        ),
      );

      expect(controller.state.stepId, OnboardingStepId.workoutProfile);
      expect(
        controller.state.draft.workout.currentStepId,
        WorkoutStepId.focusAreas,
      );
      expect(
        controller.state.draft.workout.focusAreas,
        {WorkoutFocusArea.fullBody},
      );
    });

    test('Workout Targets valid child cursor resumes exactly when active', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.workout,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.stayFit,
          ),
          currentStepId: OnboardingStepId.workoutTargets,
          workout: const WorkoutOnboardingDraft(
            currentStepId: WorkoutStepId.specialEvent,
            gymAccess: WorkoutGymAccess.gym,
            specialEvent: '5K race',
          ),
        ),
      );

      expect(controller.state.stepId, OnboardingStepId.workoutTargets);
      expect(
        controller.state.draft.workout.currentStepId,
        WorkoutStepId.specialEvent,
      );
      expect(controller.state.draft.workout.specialEvent, '5K race');
    });

    test('Hybrid later never resurrects a dormant Workout step on resume', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.hybrid,
          workoutIntroChoice: WorkoutIntroChoice.later,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
            supportingGoal: GoalIntent.improveEndurance,
          ),
          currentStepId: OnboardingStepId.workoutTargets,
          workout: const WorkoutOnboardingDraft(
            currentStepId: WorkoutStepId.specialEvent,
            gymAccess: WorkoutGymAccess.gym,
            specialEvent: 'Dormant race goal',
          ),
        ),
      );

      expect(
        controller.state.flowPlan.contains(OnboardingStepId.workoutProfile),
        isFalse,
      );
      expect(
        controller.state.flowPlan.contains(OnboardingStepId.workoutTargets),
        isFalse,
      );
      expect(controller.state.stepId, isNot(OnboardingStepId.workoutTargets));
      expect(controller.state.draft.workout.specialEvent, 'Dormant race goal');
    });
  });
}

class _Variant {
  const _Variant({
    required this.name,
    required this.mode,
    required this.goalSelection,
    this.workoutIntroChoice,
  });

  final String name;
  final AppMode mode;
  final GoalIntentSelection goalSelection;
  final WorkoutIntroChoice? workoutIntroChoice;
}

const _variants = <_Variant>[
  _Variant(
    name: 'Workout',
    mode: AppMode.workout,
    goalSelection: GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
  ),
  _Variant(
    name: 'Nutrition',
    mode: AppMode.nutrition,
    goalSelection: GoalIntentSelection(primaryGoal: GoalIntent.maintainWeight),
  ),
  _Variant(
    name: 'Hybrid setupNow',
    mode: AppMode.hybrid,
    workoutIntroChoice: WorkoutIntroChoice.setupNow,
    goalSelection: GoalIntentSelection(
      primaryGoal: GoalIntent.loseWeight,
      supportingGoal: GoalIntent.improveEndurance,
    ),
  ),
  _Variant(
    name: 'Hybrid later',
    mode: AppMode.hybrid,
    workoutIntroChoice: WorkoutIntroChoice.later,
    goalSelection: GoalIntentSelection(
      primaryGoal: GoalIntent.loseWeight,
      supportingGoal: GoalIntent.improveEndurance,
    ),
  ),
];

OnboardingDraft _reviewDraft(_Variant variant) {
  return OnboardingDraft(
    selectedMode: variant.mode,
    workoutIntroChoice: variant.workoutIntroChoice,
    goalSelection: variant.goalSelection,
    currentStepId: OnboardingStepId.review,
    targets: const TargetsOnboardingDraft(
      currentStepId: TargetStepId.nutritionTarget,
    ),
  );
}
