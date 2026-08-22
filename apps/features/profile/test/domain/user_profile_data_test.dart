import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('UserProfileData', () {
    test('normalizes boundary text and keeps only common Profile semantics', () {
      final profile = UserProfileData(
        name: '  Jane Doe  ',
        gender: ProfileGender.female,
        dateOfBirth: DateTime(1998, 12, 10),
        unitPreferences: MeasurementUnitPreferences.imperial,
        heightCm: 165,
        activityLevel: ProfileActivityLevel.light,
        healthConditions: const {ProfileHealthCondition.other},
        otherHealthCondition: '  Example condition  ',
      );

      expect(profile.name, 'Jane Doe');
      expect(profile.gender, ProfileGender.female);
      expect(profile.dateOfBirth, DateTime(1998, 12, 10));
      expect(profile.unitPreferences, MeasurementUnitPreferences.imperial);
      expect(profile.heightCm, 165);
      expect(profile.activityLevel, ProfileActivityLevel.light);
      expect(profile.healthConditions, const {ProfileHealthCondition.other});
      expect(profile.otherHealthCondition, 'Example condition');
    });

    test('rejects an empty canonical name', () {
      expect(
        () => _profile(name: '   '),
        throwsArgumentError,
      );
    });

    test('rejects non-positive or non-finite height', () {
      expect(() => _profile(heightCm: 0), throwsArgumentError);
      expect(() => _profile(heightCm: -1), throwsArgumentError);
      expect(() => _profile(heightCm: double.nan), throwsArgumentError);
    });

    test('rejects none combined with another health condition', () {
      expect(
        () => _profile(
          healthConditions: const {
            ProfileHealthCondition.none,
            ProfileHealthCondition.diabetes,
          },
        ),
        throwsArgumentError,
      );
    });

    test('defensively protects the health-condition set', () {
      final source = <ProfileHealthCondition>{ProfileHealthCondition.none};
      final profile = _profile(healthConditions: source);

      source
        ..clear()
        ..add(ProfileHealthCondition.diabetes);

      expect(profile.healthConditions, const {ProfileHealthCondition.none});
      expect(
        () => profile.healthConditions.add(ProfileHealthCondition.diabetes),
        throwsUnsupportedError,
      );
    });
  });
}

UserProfileData _profile({
  String name = 'Jane Doe',
  double heightCm = 165,
  Set<ProfileHealthCondition> healthConditions = const {
    ProfileHealthCondition.none,
  },
}) {
  return UserProfileData(
    name: name,
    gender: ProfileGender.female,
    dateOfBirth: DateTime(1998, 12, 10),
    unitPreferences: MeasurementUnitPreferences.metric,
    heightCm: heightCm,
    activityLevel: ProfileActivityLevel.light,
    healthConditions: healthConditions,
  );
}
