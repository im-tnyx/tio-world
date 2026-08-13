import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('mode selection stays in draft and does not mark completion', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
    );

    controller.selectMode(AppMode.hybrid);

    expect(controller.state.draft.selectedMode, AppMode.hybrid);
    expect(controller.state.draft.status, OnboardingStatus.inProgress);
    expect(controller.state.draft.status, isNot(OnboardingStatus.completed));
    expect(controller.state.stepId, OnboardingStepId.mode);
    expect(controller.state.currentSection, OnboardingSectionId.appMode);
    expect(controller.state.flowPlan.steps, hasLength(8));
  });

  test('each mode selection rebuilds the matching typed plan', () {
    final expectedSteps = {
      AppMode.workout: const [
        OnboardingStepId.mode,
        OnboardingStepId.profileBasics,
        OnboardingStepId.workoutPreferences,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
      AppMode.nutrition: const [
        OnboardingStepId.mode,
        OnboardingStepId.profileBasics,
        OnboardingStepId.nutritionIntro,
        OnboardingStepId.nutritionPreferences,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
      AppMode.hybrid: const [
        OnboardingStepId.mode,
        OnboardingStepId.profileBasics,
        OnboardingStepId.workoutIntro,
        OnboardingStepId.workoutPreferences,
        OnboardingStepId.nutritionIntro,
        OnboardingStepId.nutritionPreferences,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
    };

    for (final mode in AppMode.values) {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
      )..selectMode(mode);

      expect(controller.state.draft.selectedMode, mode);
      expect(controller.state.flowPlan.stepIds, expectedSteps[mode]);
      expect(controller.state.draft.status, isNot(OnboardingStatus.completed));
    }
  });

  test('next and previous update stable step identity', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
    )..selectMode(AppMode.workout);

    await controller.next(onFinish: _completeImmediately);

    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(controller.state.currentSection, OnboardingSectionId.profile);
    expect(
      controller.state.completedStepIds,
      contains(OnboardingStepId.mode),
    );
    expect(controller.state.canGoBack, isTrue);

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.mode);
  });

  test('mode change reconciles an ineligible step to nearest previous step',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(profile: _validProfile()),
    )..selectMode(AppMode.hybrid);

    await controller.next(onFinish: _completeImmediately);
    await controller.next(onFinish: _completeImmediately);
    controller.selectWorkoutIntroChoice(WorkoutIntroChoice.setupNow);
    for (var index = 0; index < 3; index++) {
      await controller.next(onFinish: _completeImmediately);
    }
    expect(controller.state.stepId, OnboardingStepId.nutritionPreferences);

    controller.selectMode(AppMode.workout);

    expect(controller.state.stepId, OnboardingStepId.workoutPreferences);
    expect(
      controller.state.completedStepIds,
      isNot(contains(OnboardingStepId.nutritionIntro)),
    );
  });

  test('invalid restored step reconciles safely to mode', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.workoutIntro,
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.mode);
  });

  test('validation errors disable continue until cleared', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
    )..selectMode(AppMode.workout);

    controller.setValidationErrors(const {'mode': 'Choose a mode'});
    expect(controller.state.canContinue, isFalse);

    controller.setValidationErrors(const {});
    expect(controller.state.canContinue, isTrue);
  });

  test('hybrid workout intro choice drives the next branch and progress',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.hybrid,
        currentStepId: OnboardingStepId.workoutIntro,
        profile: _validProfile(),
      ),
    );

    expect(controller.state.canContinue, isFalse);
    expect(controller.state.progressStepCount, 15);

    controller.selectWorkoutIntroChoice(WorkoutIntroChoice.later);

    expect(controller.state.canContinue, isTrue);
    expect(controller.state.draft.workoutIntroChoice, WorkoutIntroChoice.later);
    expect(
      controller.state.flowPlan.stepIds,
      isNot(contains(OnboardingStepId.workoutPreferences)),
    );
    expect(controller.state.progressStepCount, 14);

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.nutritionIntro);

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.workoutIntro);
    expect(controller.state.draft.workoutIntroChoice, WorkoutIntroChoice.later);

    controller.selectWorkoutIntroChoice(WorkoutIntroChoice.setupNow);
    expect(
      controller.state.flowPlan.stepIds,
      contains(OnboardingStepId.workoutPreferences),
    );
    expect(controller.state.progressStepCount, 15);

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.workoutPreferences);
  });

  test('mode change away from hybrid clears workout intro choice', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
        currentStepId: OnboardingStepId.workoutIntro,
        profile: _validProfile(),
      ),
    );

    controller.selectMode(AppMode.workout);

    expect(controller.state.draft.workoutIntroChoice, isNull);
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
  });

  test('profile child navigation validates and completes only at the end',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
    )..selectMode(AppMode.workout);
    await controller.next(onFinish: _completeImmediately);

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.name);
    expect(controller.state.validationErrors, contains('name'));
    expect(
      controller.state.completedStepIds,
      isNot(contains(OnboardingStepId.profileBasics)),
    );

    controller.updateProfileName('Tio User');
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.gender);

    controller.updateProfileGender(ProfileGender.other);
    await controller.next(onFinish: _completeImmediately);
    controller.toggleProfileGoal(ProfileGoal.keepFit);
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileDateOfBirth(DateTime(2000, 1, 1));
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileHeight(171);
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileCurrentWeight(70);
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileTargetWeight(68);
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileActivity(ProfileActivityLevel.active);
    await controller.next(onFinish: _completeImmediately);

    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.healthConditions,
    );
    expect(
      controller.state.completedStepIds,
      isNot(contains(OnboardingStepId.profileBasics)),
    );

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.workoutPreferences);
    expect(
      controller.state.completedStepIds,
      contains(OnboardingStepId.profileBasics),
    );
  });

  test('profile Back moves gender to name and name to AppMode', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.gender,
          name: 'Tio User',
        ),
      ),
    );

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.name);

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.mode);
  });

  test('final profile child follows each mode plan and mode switch keeps data',
      () async {
    for (final entry in {
      AppMode.workout: OnboardingStepId.workoutPreferences,
      AppMode.hybrid: OnboardingStepId.workoutIntro,
      AppMode.nutrition: OnboardingStepId.nutritionIntro,
    }.entries) {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        initialDraft: OnboardingDraft(
          selectedMode: entry.key,
          currentStepId: OnboardingStepId.profileBasics,
          profile: _validProfile(),
        ),
      );

      await controller.next(onFinish: _completeImmediately);
      expect(controller.state.stepId, entry.value);
    }

    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: _validProfile(currentStepId: ProfileStepId.name),
      ),
    );
    controller.previous();
    controller.selectMode(AppMode.nutrition);

    expect(controller.state.draft.profile.name, 'Tio User');
    expect(controller.state.draft.profile.heightCm, 171);
    expect(controller.state.draft.profile.goals, {ProfileGoal.keepFit});
  });

  test('progress excludes mode and reaches the final hybrid step', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(profile: _validProfile()),
    );

    expect(controller.state.progressStepCount, 0);
    expect(controller.state.progressStepNumber, 0);
    expect(controller.state.progressValue, 0);

    controller.selectMode(AppMode.hybrid);
    expect(controller.state.progressStepCount, 15);
    expect(controller.state.progressStepNumber, 0);
    expect(controller.state.progressValue, 0);

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.progressStepNumber, 9);
    expect(controller.state.progressValue, closeTo(9 / 15, 0.0001));

    controller.selectWorkoutIntroChoice(WorkoutIntroChoice.setupNow);
    expect(controller.state.progressStepCount, 15);

    while (controller.state.stepId != OnboardingStepId.review) {
      await controller.next(onFinish: _completeImmediately);
    }
    expect(controller.state.progressStepNumber, 15);
    expect(controller.state.progressValue, 1);
  });

  test('progress advances on every Profile child step', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.name,
          name: 'Tio User',
        ),
      ),
    );

    expect(controller.state.progressStepCount, 12);
    expect(controller.state.progressStepNumber, 1);
    expect(controller.state.progressValue, closeTo(1 / 12, 0.0001));

    await controller.next(onFinish: _completeImmediately);

    expect(controller.state.draft.profile.currentStepId, ProfileStepId.gender);
    expect(controller.state.progressStepNumber, 2);
    expect(controller.state.progressValue, closeTo(2 / 12, 0.0001));
  });

  test('duplicate finish calls are locked and failures keep draft retryable',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(profile: _validProfile()),
    )..selectMode(AppMode.workout);
    while (controller.state.stepId != OnboardingStepId.review) {
      await controller.next(onFinish: _completeImmediately);
    }

    final finishGate = Completer<void>();
    var finishCalls = 0;
    Future<void> finish(OnboardingDraft _) {
      finishCalls++;
      return finishGate.future;
    }

    final first = controller.next(onFinish: finish);
    final second = controller.next(onFinish: finish);
    expect(finishCalls, 1);
    expect(controller.state.isCompleting, isTrue);

    finishGate.completeError(StateError('finish failed'));
    await Future.wait([first, second]);

    expect(controller.state.isCompleting, isFalse);
    expect(controller.state.retryableError, isA<StateError>());
    expect(controller.state.draft.status, OnboardingStatus.inProgress);
  });
}

Future<void> _completeImmediately(OnboardingDraft _) async {}

ProfileOnboardingDraft _validProfile({
  ProfileStepId currentStepId = ProfileStepId.healthConditions,
}) {
  return ProfileOnboardingDraft(
    currentStepId: currentStepId,
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
