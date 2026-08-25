import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  test('equal ProfileSetupData values have equal hashes regardless of Set order',
      () {
    final first = ProfileSetupData(
      name: 'Tio User',
      gender: ProfileGender.other,
      goals: const <ProfileGoal>{
        ProfileGoal.buildMuscle,
        ProfileGoal.keepFit,
      },
      dateOfBirth: DateTime(1995, 6, 5),
      heightCm: 175,
      currentWeightKg: 72.5,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const <ProfileHealthCondition>{
        ProfileHealthCondition.diabetes,
        ProfileHealthCondition.hypertension,
      },
    );
    final second = ProfileSetupData(
      name: 'Tio User',
      gender: ProfileGender.other,
      goals: const <ProfileGoal>{
        ProfileGoal.keepFit,
        ProfileGoal.buildMuscle,
      },
      dateOfBirth: DateTime(1995, 6, 5),
      heightCm: 175,
      currentWeightKg: 72.5,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const <ProfileHealthCondition>{
        ProfileHealthCondition.hypertension,
        ProfileHealthCondition.diabetes,
      },
    );

    expect(first, equals(second));
    expect(first.hashCode, second.hashCode);
    expect({first, second}, hasLength(1));
  });
}
