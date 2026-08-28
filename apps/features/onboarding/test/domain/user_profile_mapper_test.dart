import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/src/domain/domain.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;

void main() {
  const mapper = UserProfileMapper();

  test('maps only canonical common Profile fields with exact typed units', () {
    final draft = ProfileOnboardingDraft(
      name: '  Tio User  ',
      gender: ProfileGender.female,
      goals: const {ProfileGoal.loseWeight},
      dateOfBirth: DateTime(1996, 6, 15, 12),
      heightCm: 165,
      unitPreferences: const UnitPreferences(
        weightUnit: WeightUnit.lb,
        heightUnit: HeightUnit.ftIn,
        distanceUnit: DistanceUnit.mi,
        volumeUnit: VolumeUnit.flOz,
      ),
      currentWeightKg: 60,
      targetWeightKg: 55,
      targetWeightDirection: GoalWeightDirection.loss,
      activityLevel: ProfileActivityLevel.veryActive,
      healthConditions: const {
        ProfileHealthCondition.hypertension,
        ProfileHealthCondition.other,
      },
      otherHealthCondition: '  Migraine  ',
      mobile: '+911234567890',
      isMobileVerified: true,
    );

    final result = mapper.map(draft);

    expect(result.name, 'Tio User');
    expect(result.gender, profile_owner.ProfileGender.female);
    expect(result.dateOfBirth, DateTime(1996, 6, 15));
    expect(result.heightCm, 165);
    expect(result.activityLevel, profile_owner.ProfileActivityLevel.veryActive);
    expect(
      result.healthConditions,
      {
        profile_owner.ProfileHealthCondition.hypertension,
        profile_owner.ProfileHealthCondition.other,
      },
    );
    expect(result.otherHealthCondition, 'Migraine');
    expect(result.unitPreferences.weightUnit, WeightUnit.lb);
    expect(result.unitPreferences.heightUnit, HeightUnit.ftIn);
    expect(result.unitPreferences.distanceUnit, DistanceUnit.mi);
    expect(result.unitPreferences.volumeUnit, VolumeUnit.flOz);
  });

  test('rejects missing required semantic Profile answers', () {
    expect(
      () => mapper.map(ProfileOnboardingDraft()),
      throwsArgumentError,
    );
    expect(
      () => mapper.map(ProfileOnboardingDraft(
        name: 'Tio',
        gender: ProfileGender.male,
        dateOfBirth: DateTime(2000, 1, 1),
        heightCm: 170,
      )),
      throwsArgumentError,
    );
  });

  test('rejects invalid height instead of fabricating a default', () {
    expect(
      () => mapper.map(ProfileOnboardingDraft(
        name: 'Tio',
        gender: ProfileGender.male,
        dateOfBirth: DateTime(2000, 1, 1),
        heightCm: 0,
        activityLevel: ProfileActivityLevel.active,
      )),
      throwsArgumentError,
    );
  });

  test('retains Other condition and normalizes blank detail to null (Case A)',
      () {
    final result = mapper.map(ProfileOnboardingDraft(
      name: 'Tio',
      gender: ProfileGender.other,
      dateOfBirth: DateTime(2000, 1, 1),
      heightCm: 170,
      activityLevel: ProfileActivityLevel.light,
      healthConditions: const {ProfileHealthCondition.other},
      otherHealthCondition: '',
    ));

    expect(
        result.healthConditions, {profile_owner.ProfileHealthCondition.other});
    expect(result.otherHealthCondition, isNull);
  });

  test(
      'retains Other condition and normalizes whitespace detail to null (Case B)',
      () {
    final result = mapper.map(ProfileOnboardingDraft(
      name: 'Tio',
      gender: ProfileGender.other,
      dateOfBirth: DateTime(2000, 1, 1),
      heightCm: 170,
      activityLevel: ProfileActivityLevel.light,
      healthConditions: const {ProfileHealthCondition.other},
      otherHealthCondition: '   ',
    ));

    expect(
        result.healthConditions, {profile_owner.ProfileHealthCondition.other});
    expect(result.otherHealthCondition, isNull);
  });

  test('preserves both diabetes and other when Other detail is blank (Case C)',
      () {
    final result = mapper.map(ProfileOnboardingDraft(
      name: 'Tio',
      gender: ProfileGender.male,
      dateOfBirth: DateTime(2000, 1, 1),
      heightCm: 170,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {
        ProfileHealthCondition.diabetes,
        ProfileHealthCondition.other,
      },
      otherHealthCondition: '',
    ));

    expect(result.healthConditions, {
      profile_owner.ProfileHealthCondition.diabetes,
      profile_owner.ProfileHealthCondition.other,
    });
    expect(result.otherHealthCondition, isNull);
  });

  test(
      'retains Other condition and trims detail when non-empty text provided (Case D)',
      () {
    final result = mapper.map(ProfileOnboardingDraft(
      name: 'Tio',
      gender: ProfileGender.female,
      dateOfBirth: DateTime(1996, 6, 15),
      heightCm: 165,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {ProfileHealthCondition.other},
      otherHealthCondition: '  Asthma  ',
    ));

    expect(
        result.healthConditions, {profile_owner.ProfileHealthCondition.other});
    expect(result.otherHealthCondition, 'Asthma');
  });

  test(
      'normalizes resumed draft DTO containing empty Other text without failing',
      () {
    final resumedDraft = ProfileOnboardingDraft(
      name: 'Tio Resumed',
      gender: ProfileGender.female,
      dateOfBirth: DateTime(1998, 4, 12),
      heightCm: 160,
      activityLevel: ProfileActivityLevel.sedentary,
      healthConditions: const {ProfileHealthCondition.other},
      otherHealthCondition: '',
    );

    final result = mapper.map(resumedDraft);
    expect(
        result.healthConditions, {profile_owner.ProfileHealthCondition.other});
    expect(result.otherHealthCondition, isNull);
  });

  test('does not persist stale Other text when Other is not selected', () {
    final result = mapper.map(ProfileOnboardingDraft(
      name: 'Tio',
      gender: ProfileGender.male,
      dateOfBirth: DateTime(2000, 1, 1),
      heightCm: 170,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {ProfileHealthCondition.none},
      otherHealthCondition: 'stale draft value',
    ));

    expect(result.otherHealthCondition, isNull);
  });
}
