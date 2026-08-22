import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('TargetStepValidator', () {
    const validator = TargetStepValidator();

    test('bridge step is always valid', () {
      const draft = TargetsOnboardingDraft(currentStepId: TargetStepId.bridge);
      expect(validator.isCurrentStepValid(draft), isTrue);
      expect(validator.validateCurrentStep(draft), isNull);
    });

    test('stepTarget validates 2000..18000 bounds', () {
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.stepTarget,
            dailySteps: 10000,
          ),
        ),
        isTrue,
      );

      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.stepTarget,
            dailySteps: 2000,
          ),
        ),
        isTrue,
      );

      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.stepTarget,
            dailySteps: 18000,
          ),
        ),
        isTrue,
      );

      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.stepTarget,
            dailySteps: 1999,
          ),
        ),
        isFalse,
      );

      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.stepTarget,
            dailySteps: 18001,
          ),
        ),
        isFalse,
      );
    });

    test('sleepTarget validates 240..720 minutes bounds', () {
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.sleepTarget,
            sleepTargetMinutes: 480,
          ),
        ),
        isTrue,
      );
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.sleepTarget,
            sleepTargetMinutes: 240,
          ),
        ),
        isTrue,
      );
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.sleepTarget,
            sleepTargetMinutes: 720,
          ),
        ),
        isTrue,
      );
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.sleepTarget,
            sleepTargetMinutes: 239,
          ),
        ),
        isFalse,
      );
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.sleepTarget,
            sleepTargetMinutes: 721,
          ),
        ),
        isFalse,
      );
    });

    test('waterTarget validates 1000..8000 ml bounds', () {
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.waterTarget,
            waterMl: 2500,
          ),
        ),
        isTrue,
      );
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.waterTarget,
            waterMl: 1000,
          ),
        ),
        isTrue,
      );
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.waterTarget,
            waterMl: 8000,
          ),
        ),
        isTrue,
      );
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.waterTarget,
            waterMl: 999,
          ),
        ),
        isFalse,
      );
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.waterTarget,
            waterMl: 8001,
          ),
        ),
        isFalse,
      );
    });

    test('goalPace validates 0.1..1.5 kg/week for explicit weight direction', () {
      for (final direction in [
        GoalWeightDirection.loss,
        GoalWeightDirection.gain,
      ]) {
        expect(
          validator.isCurrentStepValid(
            const TargetsOnboardingDraft(
              currentStepId: TargetStepId.goalPace,
              goalPaceKgPerWeek: 0.5,
            ),
            weightGoalDirection: direction,
          ),
          isTrue,
        );
        expect(
          validator.isCurrentStepValid(
            const TargetsOnboardingDraft(
              currentStepId: TargetStepId.goalPace,
              goalPaceKgPerWeek: 0.1,
            ),
            weightGoalDirection: direction,
          ),
          isTrue,
        );
        expect(
          validator.isCurrentStepValid(
            const TargetsOnboardingDraft(
              currentStepId: TargetStepId.goalPace,
              goalPaceKgPerWeek: 1.5,
            ),
            weightGoalDirection: direction,
          ),
          isTrue,
        );
        expect(
          validator.isCurrentStepValid(
            const TargetsOnboardingDraft(
              currentStepId: TargetStepId.goalPace,
              goalPaceKgPerWeek: 0.05,
            ),
            weightGoalDirection: direction,
          ),
          isFalse,
        );
        expect(
          validator.isCurrentStepValid(
            const TargetsOnboardingDraft(
              currentStepId: TargetStepId.goalPace,
              goalPaceKgPerWeek: 1.6,
            ),
            weightGoalDirection: direction,
          ),
          isFalse,
        );
      }
    });

    test('goalPace creates no validation obligation without weight direction', () {
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.goalPace,
            goalPaceKgPerWeek: 0.0,
          ),
          weightGoalDirection: null,
        ),
        isTrue,
      );
    });

    test('nutritionTarget is navigation-passable for preview', () {
      expect(
        validator.isCurrentStepValid(
          const TargetsOnboardingDraft(
            currentStepId: TargetStepId.nutritionTarget,
          ),
        ),
        isTrue,
      );
    });
  });
}
