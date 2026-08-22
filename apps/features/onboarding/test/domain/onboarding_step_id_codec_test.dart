import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  const codec = OnboardingStepIdCodec();

  group('OnboardingStepIdCodec', () {
    test('preserves legacy storage keys that have not migrated', () {
      const legacyKeys = <OnboardingStepId, String>{
        OnboardingStepId.mode: 'mode',
        OnboardingStepId.profileBasics: 'profileBasics',
        OnboardingStepId.mobile: 'mobile',
        OnboardingStepId.workoutIntro: 'workoutIntro',
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

    test('legacy workoutPreferences reads as canonical workoutProfile', () {
      expect(
        codec.tryDecode('workoutPreferences'),
        OnboardingStepId.workoutProfile,
      );
      expect(
        codec.tryDecode('workoutProfile'),
        OnboardingStepId.workoutProfile,
      );
      expect(
        codec.encode(OnboardingStepId.workoutPreferences),
        'workoutProfile',
      );
      expect(
        OnboardingStepId.workoutPreferences,
        OnboardingStepId.workoutProfile,
      );
    });

    test('round-trips canonical identities without fabricating aliases', () {
      const canonicalIds = <OnboardingStepId>[
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

      for (final stepId in canonicalIds) {
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
