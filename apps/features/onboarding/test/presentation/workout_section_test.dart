import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
      'real workout section renders GymAccess first and keeps progress dynamic',
      (tester) async {
    final harness = await _pumpWorkout(tester);
    final semantics = tester.ensureSemantics();
    try {
      expect(find.byType(WorkoutSection), findsOneWidget);
      expect(find.byType(GymAccessScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Workout step 1 of 8, Where will you mostly work out?',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('workout-choice-gym-access-home')),
      );
      await tester.pumpAndSettle();

      expect(
        harness.controller.state.draft.workout.gymAccess,
        WorkoutGymAccess.home,
      );
      expect(harness.controller.state.progressStepCount, 26);
      expect(harness.controller.state.workoutFlowPlan.stepCount, 9);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(EquipmentScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Workout step 2 of 9, What equipment do you have at home?',
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('gym path skips equipment and Back returns to GymAccess',
      (tester) async {
    await _pumpWorkout(tester);

    await tester
        .tap(find.byKey(const ValueKey('workout-choice-gym-access-gym')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(ExperienceLevelScreen), findsOneWidget);
    expect(find.byType(EquipmentScreen), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(GymAccessScreen), findsOneWidget);
  });

  testWidgets(
      'FocusAreas full_body selection reaches the typed draft centrally',
      (tester) async {
    final harness = await _pumpWorkout(
      tester,
      workout: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.focusAreas,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
      ),
    );

    expect(find.byType(FocusAreasScreen), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('workout-choice-focus-fullBody')));
    await tester.pumpAndSettle();

    final selected = harness.controller.state.draft.workout.focusAreas;
    expect(selected, contains(WorkoutFocusArea.fullBody));
    expect(
      WorkoutFocusArea.individualAreas.every(selected.contains),
      isTrue,
    );

    final arms = find.byKey(const ValueKey('workout-choice-focus-arms'));
    await tester.ensureVisible(arms);
    await tester.pumpAndSettle();
    await tester.tap(arms);
    await tester.pumpAndSettle();

    final updated = harness.controller.state.draft.workout.focusAreas;
    expect(updated, isNot(contains(WorkoutFocusArea.fullBody)));
    expect(updated, isNot(contains(WorkoutFocusArea.arms)));
  });

  testWidgets(
      'TrainingDays updates typed multi-select state with parent CTA ownership',
      (tester) async {
    final harness = await _pumpWorkout(
      tester,
      workout: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.trainingDays,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
      ),
    );

    expect(find.byType(TrainingDaysScreen), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('workout-choice-training-day-monday')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('workout-choice-training-day-wednesday')),
    );
    await tester.pumpAndSettle();

    expect(harness.controller.state.draft.workout.trainingDays, {
      WorkoutTrainingDay.monday,
      WorkoutTrainingDay.wednesday,
    });
  });

  testWidgets('WorkoutDuration and WorkoutSplit render real typed selections',
      (tester) async {
    final durationHarness = await _pumpWorkout(
      tester,
      workout: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.workoutDuration,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
      ),
    );

    expect(find.byType(WorkoutDurationScreen), findsOneWidget);
    await tester.tap(
      find.byKey(
          const ValueKey('workout-choice-workout-duration-sixtyMinutes')),
    );
    await tester.pumpAndSettle();
    expect(
      durationHarness.controller.state.draft.workout.workoutDuration,
      WorkoutDuration.sixtyMinutes,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    final splitHarness = await _pumpWorkout(
      tester,
      workout: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.workoutSplit,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
        workoutDuration: WorkoutDuration.sixtyMinutes,
      ),
    );

    expect(find.byType(WorkoutSplitScreen), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('workout-choice-workout-split-upperLower')),
    );
    await tester.pumpAndSettle();
    expect(
      splitHarness.controller.state.draft.workout.workoutSplit,
      WorkoutSplit.upperLower,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets(
      'HealthConcerns and SpecialEvent are real optional inputs and reach Targets',
      (tester) async {
    final harness = await _pumpWorkout(
      tester,
      workout: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.healthConcerns,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.upperLower,
      ),
    );

    expect(find.byType(HealthConcernsScreen), findsOneWidget);
    expect(find.byType(SpecialEventScreen), findsNothing);

    final healthInput = find.descendant(
      of: find.byKey(const ValueKey('workout-health-concerns-input')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(
      healthInput,
      'Knee stiffness',
    );
    await tester.pumpAndSettle();
    expect(harness.controller.state.draft.workout.healthConcerns,
        'Knee stiffness');

    final healthField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('workout-health-concerns-input')),
        matching: find.byType(EditableText),
      ),
    );
    expect(healthField.maxLines, 6);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(SpecialEventScreen), findsOneWidget);
    final eventInput = find.descendant(
      of: find.byKey(const ValueKey('workout-special-event-input')),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(
      eventInput,
      'City 10K',
    );
    await tester.pumpAndSettle();
    expect(harness.controller.state.draft.workout.specialEvent, 'City 10K');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(HealthConcernsScreen), findsOneWidget);
    expect(find.text('Knee stiffness'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(SpecialEventScreen), findsOneWidget);
    expect(find.text('City 10K'), findsOneWidget);

    final titleTopBefore =
        tester.getTopLeft(find.text('Are you training for a special event?')).dy;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final buttonBottom = tester.getBottomRight(find.byType(FilledButton)).dy;
    final logicalHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final keyboardTop = logicalHeight - (280 / tester.view.devicePixelRatio);
    expect(buttonBottom, lessThanOrEqualTo(keyboardTop));
    expect(
      tester.getTopLeft(find.text('Are you training for a special event?')).dy,
      titleTopBefore,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(harness.controller.state.stepId, OnboardingStepId.targets);
  });
}

Future<_WorkoutHarness> _pumpWorkout(
  WidgetTester tester, {
  WorkoutOnboardingDraft? workout,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final seed = OnboardingControllerSeed(
    entryPath: OnboardingEntryPath.firstRun,
    draft: OnboardingDraft(
      selectedMode: AppMode.workout,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      ),
      currentStepId: OnboardingStepId.workoutPreferences,
      profile: _validProfile(),
      workout: workout ?? const WorkoutOnboardingDraft(),
    ),
  );

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
  await tester.pump();

  return _WorkoutHarness(
    controller: container.read(onboardingControllerProvider(seed)),
  );
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    currentStepId: ProfileStepId.healthConditions,
    name: 'Tio User',
    gender: ProfileGender.other,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: 70,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

class _WorkoutHarness {
  const _WorkoutHarness({required this.controller});

  final OnboardingController controller;
}
