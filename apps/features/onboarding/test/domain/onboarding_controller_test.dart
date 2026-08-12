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
    expect(controller.state.flowPlan.steps, hasLength(8));
  });

  test('next and previous update stable step identity', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
    )..selectMode(AppMode.workout);

    await controller.next(onFinish: _completeImmediately);

    expect(controller.state.stepId, OnboardingStepId.profileBasics);
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
    )..selectMode(AppMode.hybrid);

    for (var index = 0; index < 5; index++) {
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

  test('progress excludes mode and reaches the final hybrid step', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
    );

    expect(controller.state.progressStepCount, 0);
    expect(controller.state.progressStepNumber, 0);
    expect(controller.state.progressValue, 0);

    controller.selectMode(AppMode.hybrid);
    expect(controller.state.progressStepCount, 7);
    expect(controller.state.progressStepNumber, 0);
    expect(controller.state.progressValue, 0);

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.progressStepNumber, 1);
    expect(controller.state.progressValue, closeTo(1 / 7, 0.0001));

    while (controller.state.stepId != OnboardingStepId.review) {
      await controller.next(onFinish: _completeImmediately);
    }
    expect(controller.state.progressStepNumber, 7);
    expect(controller.state.progressValue, 1);
  });

  test('duplicate finish calls are locked and failures keep draft retryable',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
    )..selectMode(AppMode.workout);
    while (controller.state.stepId != OnboardingStepId.review) {
      await controller.next(onFinish: _completeImmediately);
    }

    final finishGate = Completer<void>();
    var finishCalls = 0;
    Future<void> finish() {
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

Future<void> _completeImmediately() async {}
