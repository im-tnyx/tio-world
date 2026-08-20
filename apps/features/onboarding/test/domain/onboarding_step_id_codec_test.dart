import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  const codec = OnboardingStepIdCodec();

  group('OnboardingStepIdCodec', () {
    test('preserves every legacy schema-v2 storage key exactly', () {
      const legacyKeys = <OnboardingStepId, String>{
        OnboardingStepId.mode: 'mode',
        OnboardingStepId.profileBasics: 'profileBasics',
        OnboardingStepId.mobile: 'mobile',
        OnboardingStepId.workoutIntro: 'workoutIntro',
        OnboardingStepId.workoutPreferences: 'workoutPreferences',
        OnboardingStepId.nutritionIntro: 'nutritionIntro',
        OnboardingStepId.nutritionPreferences: 'nutritionPreferences',
        OnboardingStepId.targets: 'targets',
        OnboardingStepId.review: 'review',
      };

      for (final entry in legacyKeys.entries) {
        expect(codec.encode(entry.key), entry.value);
        expect(codec.tryDecode(entry.value), entry.key);
      }
    });

    test('round-trips future identities without activating them', () {
      const futureIds = <OnboardingStepId>[
        OnboardingStepId.userProfile,
        OnboardingStepId.bodyGoal,
        OnboardingStepId.wellnessGoals,
        OnboardingStepId.nutritionProfile,
        OnboardingStepId.workoutProfile,
        OnboardingStepId.nutritionGoals,
        OnboardingStepId.workoutTargets,
        OnboardingStepId.healthConnections,
        OnboardingStepId.planBuilding,
      ];

      for (final stepId in futureIds) {
        expect(codec.tryDecode(codec.encode(stepId)), stepId);
      }
    });

    test('unknown or non-string values do not fabricate an identity', () {
      expect(codec.tryDecode('unknownFutureStep'), isNull);
      expect(codec.tryDecode(42), isNull);
      expect(
        codec.decodeOr(
          'unknownFutureStep',
          fallback: OnboardingStepId.mode,
        ),
        OnboardingStepId.mode,
      );
    });
  });
}
