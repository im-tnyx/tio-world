import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('ProfileSetupDtoMapper', () {
    test('maps complete ProfileSetupData to verified backend JSON schema', () {
      final data = ProfileSetupData(
        name: 'Alex Mercer',
        gender: ProfileGender.female,
        goals: const {ProfileGoal.loseWeight, ProfileGoal.keepFit},
        dateOfBirth: DateTime(1995, 5, 20),
        heightCm: 168.5,
        currentWeightKg: 62.0,
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.diabetes},
        otherHealthCondition: 'Mild asthma',
      );

      const mapper = ProfileSetupDtoMapper();
      final payload = mapper.toRequestPayload(data);

      expect(payload['name'], 'Alex Mercer');
      expect(payload['gender'], 'female');
      expect(payload['goals'], containsAll(['lose_weight', 'keep_fit']));
      expect(payload['dob'], '1995-05-20');
      expect(payload['height'], 168.5);
      expect(payload['currentWeight'], 62.0);
      expect(payload['activityLevel'], 'active');
      expect(payload['healthConditions'], ['diabetes']);
      expect(payload['otherHealthCondition'], 'Mild asthma');
    });

    test('omits otherHealthCondition when null or empty', () {
      final data = ProfileSetupData(
        name: 'Bob',
        gender: ProfileGender.male,
        goals: const {ProfileGoal.buildMuscle},
        dateOfBirth: DateTime(2000, 1, 1),
        heightCm: 180,
        currentWeightKg: 75,
        activityLevel: ProfileActivityLevel.sedentary,
        healthConditions: const {ProfileHealthCondition.none},
      );

      const mapper = ProfileSetupDtoMapper();
      final payload = mapper.toRequestPayload(data);

      expect(payload.containsKey('otherHealthCondition'), isFalse);
    });
  });

  group('RemoteProfileSetupRepository', () {
    test('delegates mapped payload to remote data source on saveProfileSetup', () async {
      final fakeDataSource = _FakeProfileSetupRemoteDataSource();
      final repository = RemoteProfileSetupRepository(
        remoteDataSource: fakeDataSource,
      );

      final data = ProfileSetupData(
        name: 'Jane Doe',
        gender: ProfileGender.female,
        goals: const {ProfileGoal.boostStrength},
        dateOfBirth: DateTime(1998, 12, 10),
        heightCm: 165,
        currentWeightKg: 58,
        activityLevel: ProfileActivityLevel.light,
        healthConditions: const {ProfileHealthCondition.none},
      );

      await repository.saveProfileSetup(data);

      expect(fakeDataSource.lastSavedPayload, isNotNull);
      expect(fakeDataSource.lastSavedPayload?['name'], 'Jane Doe');
      expect(fakeDataSource.lastSavedPayload?['gender'], 'female');
      expect(fakeDataSource.lastSavedPayload?['dob'], '1998-12-10');
      expect(await repository.getProfileSetup(), isNull);
    });
  });
}

class _FakeProfileSetupRemoteDataSource implements ProfileSetupRemoteDataSource {
  Map<String, dynamic>? lastSavedPayload;

  @override
  Future<void> saveProfileSetup(Map<String, dynamic> data) async {
    lastSavedPayload = data;
  }
}
