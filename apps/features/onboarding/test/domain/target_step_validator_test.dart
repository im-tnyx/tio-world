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
      for (final steps in [2000, 10000, 18000]) {
        expect(
          validator.isCurrentStepValid(
            TargetsOnboardingDraft(
              currentStepId: TargetStepId.stepTarget,
              dailySteps: steps,
            ),
          ),
          isTrue,
        );
      }
      for (final steps in [1999, 18001]) {
        expect(
          validator.isCurrentStepValid(
            TargetsOnboardingDraft(
              currentStepId: TargetStepId.stepTarget,
              dailySteps: steps,
            ),
          ),
          isFalse,
        );
      }
    });

    test('sleepTarget validates 240..720 minutes bounds', () {
      for (final minutes in [240, 480, 720]) {
        expect(
          validator.isCurrentStepValid(
            TargetsOnboardingDraft(
              currentStepId: TargetStepId.sleepTarget,
              sleepTargetMinutes: minutes,
            ),
          ),
          isTrue,
        );
      }
      for (final minutes in [239, 721]) {
        expect(
          validator.isCurrentStepValid(
            TargetsOnboardingDraft(
              currentStepId: TargetStepId.sleepTarget,
              sleepTargetMinutes: minutes,
            ),
          ),
          isFalse,
        );
      }
    });

    test('waterTarget validates 1000..8000 ml bounds', () {
      for (final ml in [1000, 2500, 8000]) {
        expect(
          validator.isCurrentStepValid(
            TargetsOnboardingDraft(
              currentStepId: TargetStepId.waterTarget,
              waterMl: ml,
            ),
          ),
          isTrue,
        );
      }
      for (final ml in [999, 8001]) {
        expect(
          validator.isCurrentStepValid(
            TargetsOnboardingDraft(
              currentStepId: TargetStepId.waterTarget,
              waterMl: ml,
            ),
          ),
          isFalse,
        );
      }
    });

    test('goalPace validates 0.1..1.5 kg/week after direction exists', () {
      for (final direction in [
        GoalWeightDirection.loss,
        GoalWeightDirection.gain,
      ]) {
        for (final pace in [0.1, 0.5, 1.5]) {
          expect(
            validator.isCurrentStepValid(
              TargetsOnboardingDraft(
                currentStepId: TargetStepId.goalPace,
                goalPaceKgPerWeek: pace,
              ),
              weightGoalDirection: direction,
            ),
            isTrue,
          );
        }
        for (final pace in [0.05, 1.6]) {
          expect(
            validator.isCurrentStepValid(
              TargetsOnboardingDraft(
                currentStepId: TargetStepId.goalPace,
                goalPaceKgPerWeek: pace,
              ),
              weightGoalDirection: direction,
            ),
            isFalse,
          );
        }
      }
    });

    test('goalPace blocks when Target Weight has not established direction', () {
      const draft = TargetsOnboardingDraft(
        currentStepId: TargetStepId.goalPace,
        goalPaceKgPerWeek: 0.5,
      );

      expect(
        validator.validateCurrentStep(
          draft,
          weightGoalDirection: null,
        ),
        'Choose a target weight above or below your current weight before setting goal pace.',
      );
      expect(
        validator.isCurrentStepValid(draft, weightGoalDirection: null),
        isFalse,
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
