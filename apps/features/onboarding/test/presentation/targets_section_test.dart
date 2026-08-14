import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
      'targets section renders bridge first and advances through all child steps to review',
      (tester) async {
    final harness = await _pumpTargets(tester);
    final semantics = tester.ensureSemantics();

    try {
      // Step 1: Bridge
      expect(find.byType(TargetsSection), findsOneWidget);
      expect(find.byType(BridgeScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 1 of 6, Building your targets'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: StepTarget
      expect(find.byType(StepTargetScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 2 of 6, Daily step target'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: SleepTarget
      expect(find.byType(SleepTargetScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 3 of 6, Sleep schedule target'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: WaterTarget
      expect(find.byType(WaterTargetScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 4 of 6, Daily hydration target'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 5: GoalPace (Real Screen) — CTA must be 'Continue'
      expect(find.byType(GoalPaceScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'Target step 5 of 6')),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 6: NutritionTarget (Real Screen with Canonical Calculations) — CTA must be 'Review'
      expect(find.byType(NutritionTargetScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel('Target step 6 of 6, Nutrition targets'),
        findsOneWidget,
      );
      expect(find.text('DAILY CALORIE TARGET'), findsOneWidget);
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbohydrates'), findsOneWidget);
      expect(find.text('Fats'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      // Advances to Review section
      expect(harness.controller.state.stepId, OnboardingStepId.review);
      expect(find.byType(ReviewSection), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('switching water display unit does not alter waterMl in domain',
      (tester) async {
    final harness = await _pumpTargets(
      tester,
      initialTargets: const TargetsOnboardingDraft(
        currentStepId: TargetStepId.waterTarget,
        waterMl: 2500,
      ),
    );

    expect(find.byType(WaterTargetScreen), findsOneWidget);
    expect(find.text('2.5'), findsOneWidget);
    expect(find.text('L/day'), findsOneWidget);

    // Change unit to ml via dropdown
    await tester.tap(find.byKey(const ValueKey('targets-water-unit-dropdown')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ml').last);
    await tester.pumpAndSettle();

    expect(find.text('2500'), findsOneWidget);
    expect(find.text('ml/day'), findsOneWidget);
    // Domain waterMl is still 2500
    expect(harness.controller.state.draft.targets.waterMl, 2500);

    // Change unit to oz via dropdown
    await tester.tap(find.byKey(const ValueKey('targets-water-unit-dropdown')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('oz').last);
    await tester.pumpAndSettle();

    expect(find.text('85'), findsOneWidget);
    expect(find.text('oz/day'), findsOneWidget);
    // Domain waterMl is still 2500
    expect(harness.controller.state.draft.targets.waterMl, 2500);
  });

  testWidgets('goal pace screen shows pace slider and warnings in weight loss mode',
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
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
      ),
      initialTargets: const TargetsOnboardingDraft(
        currentStepId: TargetStepId.goalPace,
        goalPaceKgPerWeek: 0.5,
      ),
    );

    expect(find.byType(GoalPaceScreen), findsOneWidget);
    expect(find.text('Target Fat Loss Pace'), findsOneWidget);
    expect(find.text('0.5 kg'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.byKey(const ValueKey('targets-goal-pace-slider')), findsOneWidget);

    // Update pace to 1.2 kg/week -> should show aggressive warning
    harness.controller.updateGoalPaceKgPerWeek(1.2);
    await tester.pumpAndSettle();

    expect(find.text('1.2 kg'), findsOneWidget);
    expect(find.text('Aggressive'), findsOneWidget);
    expect(find.text('Aggressive Loss Pace'), findsOneWidget);
  });
}

class _TargetsHarness {
  const _TargetsHarness({
    required this.controller,
  });

  final OnboardingController controller;
}

Future<_TargetsHarness> _pumpTargets(
  WidgetTester tester, {
  ProfileOnboardingDraft? initialProfile,
  TargetsOnboardingDraft? initialTargets,
}) async {
  final draft = OnboardingDraft(
    selectedMode: AppMode.workout,
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
          targetWeightKg: 70,
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
    targets: initialTargets ?? const TargetsOnboardingDraft(),
    completedStepIds: const {
      OnboardingStepId.mode,
      OnboardingStepId.profileBasics,
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
