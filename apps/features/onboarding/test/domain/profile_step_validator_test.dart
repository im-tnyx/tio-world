import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  final validator = ProfileStepValidator(now: () => DateTime(2026, 8, 13));

  test('validates name while Goal validation is delegated', () {
    expect(
      validator.validate(ProfileOnboardingDraft(name: 'Ti')),
      contains(ProfileStepId.name),
    );
    expect(
      validator.validate(ProfileOnboardingDraft(name: 'Tio')),
      isEmpty,
    );

    expect(
      validator.validate(ProfileOnboardingDraft(
        currentStepId: ProfileStepId.goal,
      )),
      isEmpty,
    );
  });

  test('accepts source-defined date boundaries and rejects outside dates', () {
    ProfileOnboardingDraft draft(DateTime value) => ProfileOnboardingDraft(
          currentStepId: ProfileStepId.age,
          dateOfBirth: value,
        );

    expect(validator.validate(draft(DateTime(1950))), isEmpty);
    expect(validator.validate(draft(DateTime(2026, 8, 13))), isEmpty);
    expect(
      validator.validate(draft(DateTime(1949, 12, 31))),
      contains(ProfileStepId.age),
    );
    expect(
      validator.validate(draft(DateTime(2026, 8, 14))),
      contains(ProfileStepId.age),
    );
  });

  test('accepts inclusive height and weight bounds', () {
    for (final value in [100.0, 250.0]) {
      expect(
        validator.validate(ProfileOnboardingDraft(
          currentStepId: ProfileStepId.height,
          heightCm: value,
        )),
        isEmpty,
      );
    }
    for (final value in [30.0, 200.0]) {
      expect(
        validator.validate(ProfileOnboardingDraft(
          currentStepId: ProfileStepId.currentWeight,
          currentWeightKg: value,
        )),
        isEmpty,
      );
      expect(
        validator.validate(ProfileOnboardingDraft(
          currentStepId: ProfileStepId.targetWeight,
          targetWeightKg: value,
        )),
        isEmpty,
      );
    }

    expect(
      validator.validate(ProfileOnboardingDraft(
        currentStepId: ProfileStepId.height,
        heightCm: 99.9,
      )),
      contains(ProfileStepId.height),
    );
    expect(
      validator.validate(ProfileOnboardingDraft(
        currentStepId: ProfileStepId.targetWeight,
        targetWeightKg: 200.1,
      )),
      contains(ProfileStepId.targetWeight),
    );
  });

  test('health conditions step is optional and non-blocking', () {
    expect(
      validator.validate(ProfileOnboardingDraft(
        currentStepId: ProfileStepId.healthConditions,
      )),
      isEmpty,
    );
    expect(
      validator.validate(ProfileOnboardingDraft(
        currentStepId: ProfileStepId.healthConditions,
        healthConditions: const {ProfileHealthCondition.other},
      )),
      isEmpty,
    );
    expect(
      validator.validate(ProfileOnboardingDraft(
        currentStepId: ProfileStepId.healthConditions,
        healthConditions: const {ProfileHealthCondition.other},
        otherHealthCondition: 'Asthma',
      )),
      isEmpty,
    );
  });
}
