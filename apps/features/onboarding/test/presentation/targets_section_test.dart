import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('Wellness section renders four active children in exact order',
      (tester) async {
    final harness = await _pumpTargets(
      tester,
      initialTargets: const TargetsOnboardingDraft(
        currentStepId: TargetStepId.bridge,
      ),
    );
    final semantics = tester.ensureSemantics();

    try {
      expect(harness.controller.state.stepId, OnboardingStepId.wellnessGoals);
      expect(find.byType(WellnessSection), findsOneWidget);
      expect(find.byType(TargetsSection), findsNothing);
      expect(find.byType(BridgeScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 1 of 4, Building your targets'),
        findsOneWidget,
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(StepTargetScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 2 of 4, Daily step target'),
        findsOneWidget,
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(SleepTargetScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 3 of 4, Sleep schedule target'),
        findsOneWidget,
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(WaterTargetScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 4 of 4, Daily hydration target'),
        findsOneWidget,
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        harness.controller.state.stepId,
        OnboardingStepId.workoutPreferences,
      );
      expect(find.byType(WorkoutSection), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'Nutrition Goals section renders Nutrition Target only and reaches review',
      (tester) async {
    final harness = await _pumpTargets(
      tester,
      mode: AppMode.nutrition,
      initialTargets: const TargetsOnboardingDraft(
        currentStepId: TargetStepId.nutritionTarget,
      ),
    );
    final semantics = tester.ensureSemantics();

    try {
      expect(harness.controller.state.stepId, OnboardingStepId.nutritionGoals);
      expect(
        harness.controller.state.targetsFlowPlan.steps,
        const [TargetStepId.nutritionTarget],
      );
      expect(find.byType(NutritionGoalsSection), findsOneWidget);
      expect(find.byType(TargetsSection), findsNothing);
      expect(find.byType(WellnessSection), findsNothing);
      expect(find.byType(BridgeScreen), findsNothing);
      expect(find.byType(StepTargetScreen), findsNothing);
      expect(find.byType(SleepTargetScreen), findsNothing);
      expect(find.byType(WaterTargetScreen), findsNothing);
      expect(find.byType(GoalPaceScreen), findsNothing);
      expect(find.byType(NutritionTargetScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 1 of 1, Nutrition targets'),
        findsOneWidget,
      );
      expect(find.text('DAILY CALORIE TARGET'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbohydrates'), findsOneWidget);
      expect(find.text('Fats'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(harness.controller.state.stepId, OnboardingStepId.review);
      expect(find.byType(ReviewSection), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('switching Wellness water display unit preserves waterMl',
      (tester) async {
    final harness = await _pumpTargets(
      tester,
      initialTargets: const TargetsOnboardingDraft(
        currentStepId: TargetStepId.waterTarget,
        waterMl: 2500,
      ),
    );

    expect(harness.controller.state.stepId, OnboardingStepId.wellnessGoals);
    expect(find.byType(WellnessSection), findsOneWidget);
    expect(find.byType(WaterTargetScreen), findsOneWidget);
    expect(find.text('2.5'), findsOneWidget);
    expect(find.text('L/day'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('targets-water-unit-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('mL').last);
    await tester.pumpAndSettle();

    expect(find.text('2500'), findsOneWidget);
    expect(find.text('ml/day'), findsOneWidget);
    expect(harness.controller.state.draft.targets.waterMl, 2500);

    await tester.tap(find.byKey(const ValueKey('targets-water-unit-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('fl oz').last);
    await tester.pumpAndSettle();

    expect(find.text('85'), findsOneWidget);
    expect(find.text('fl oz/day'), findsOneWidget);
    expect(harness.controller.state.draft.targets.waterMl, 2500);
  });

  testWidgets(
      'legacy Goal Pace cursor renders the existing screen under Body Goal',
      (tester) async {
    final harness = await _pumpTargets(
      tester,
      initialProfile: ProfileOnboardingDraft(
        currentStepId: ProfileStepId.healthConditions,
        name: 'Tio User',
        gender: ProfileGender.other,
        goals: const {ProfileGoal.loseWeight},
        dateOfBirth: DateTime(2000, 1, 1),
        heightCm: 170,
        currentWeightKg: 85,
        targetWeightKg: 75,
        targetWeightDirection: GoalWeightDirection.loss,
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
      ),
      initialTargets: const TargetsOnboardingDraft(
        currentStepId: TargetStepId.goalPace,
        goalPaceKgPerWeek: 0.5,
      ),
    );

    expect(harness.controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(
      harness.controller.state.draft.profile.currentStepId,
      ProfileStepId.goalPace,
    );
    expect(find.byType(BodyGoalSection), findsOneWidget);
    expect(find.byType(TargetsSection), findsNothing);
    expect(find.byType(GoalPaceScreen), findsOneWidget);
    expect(find.text('How fast do you want to \nlose weight?'), findsOneWidget);
    expect(find.textContaining('0.5 kg'), findsWidgets);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.byKey(const ValueKey('targets-goal-pace-slider')), findsOneWidget);
    expect(find.byKey(const ValueKey('targets-projection-card')), findsOneWidget);
    expect(find.textContaining('kcal'), findsNothing);
    expect(find.text('Target Calories'), findsNothing);

    harness.controller.updateGoalPaceKgPerWeek(1.2);
    await tester.pumpAndSettle();

    expect(find.textContaining('1.2 kg'), findsWidgets);
    expect(find.text('Aggressive Loss Pace'), findsOneWidget);
    expect(find.textContaining('kcal'), findsNothing);
  });
}

class _TargetsHarness {
  const _TargetsHarness({required this.controller});
  final OnboardingController controller;
}

Future<_TargetsHarness> _pumpTargets(
  WidgetTester tester, {
  AppMode mode = AppMode.workout,
  ProfileOnboardingDraft? initialProfile,
  TargetsOnboardingDraft? initialTargets,
}) async {
  final draft = OnboardingDraft(
    selectedMode: mode,
    goalSelection: const GoalIntentSelection(
      primaryGoal: GoalIntent.loseWeight,
    ),
    currentStepId: OnboardingStepId.targets,
    profile: initialProfile ??
        ProfileOnboardingDraft(
          currentStepId: ProfileStepId.healthConditions,
          name: 'Tio User',
          gender: ProfileGender.other,
          goals: const {ProfileGoal.keepFit},
          dateOfBirth: DateTime(2000, 1, 1),
          heightCm: 170,
          currentWeightKg: 70,
          targetWeightKg: 66,
          targetWeightDirection: GoalWeightDirection.loss,
          activityLevel: ProfileActivityLevel.active,
          healthConditions: const {ProfileHealthCondition.none},
        ),
    workout: const WorkoutOnboardingDraft(
      gymAccess: WorkoutGymAccess.gym,
      experienceLevel: WorkoutExperienceLevel.beginner,
      focusAreas: {WorkoutFocusArea.legs},
      trainingDays: {WorkoutTrainingDay.monday, WorkoutTrainingDay.wednesday},
      workoutDuration: WorkoutDuration.sixtyMinutes,
      workoutSplit: WorkoutSplit.auto,
    ),
    targets: initialTargets ??
        const TargetsOnboardingDraft(
          currentStepId: TargetStepId.nutritionTarget,
        ),
    completedStepIds: const {
      OnboardingStepId.mode,
      OnboardingStepId.profileBasics,
      OnboardingStepId.bodyGoal,
      OnboardingStepId.wellnessGoals,
      OnboardingStepId.workoutPreferences,
    },
  );

  final seed = OnboardingControllerSeed(
    entryPath: OnboardingEntryPath.firstRun,
    draft: draft,
  );
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: TioTheme(
          child: OnboardingFlowPage(
            seed: seed,
            onFinishRequested: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _TargetsHarness(
    controller: container.read(onboardingControllerProvider(seed)),
  );
}
