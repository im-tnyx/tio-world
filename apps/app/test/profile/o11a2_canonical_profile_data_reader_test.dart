import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/profile/canonical_profile_data_reader.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  group('O11A2 CanonicalProfileDataReader', () {
    test('composes display data only from canonical Profile, Body and account',
        () async {
      final profile = UserProfileData(
        name: 'Canonical Name',
        gender: ProfileGender.female,
        dateOfBirth: DateTime(1994, 4, 5),
        unitPreferences: const MeasurementUnitPreferences(
          weightUnit: WeightUnit.lb,
          heightUnit: HeightUnit.ftIn,
          distanceUnit: DistanceUnit.mi,
          volumeUnit: VolumeUnit.flOz,
        ),
        heightCm: 166,
        activityLevel: ProfileActivityLevel.veryActive,
        healthConditions: const {ProfileHealthCondition.hypertension},
        otherHealthCondition: 'Canonical condition',
      );
      final reader = CanonicalProfileDataReader(
        profileRepository: _ProfileRepository(profile),
        bodyRepository: _BodyRepository(
          BodyState(
            latestWeight: BodyWeightEntry(
              weightKg: 62,
              measuredAt: DateTime.utc(2026, 8, 23),
              source: BodyWeightSources.profileSettings,
            ),
            activeGoal: const BodyGoalState(
              goalType: BodyGoalType.loseWeight,
              targetWeightKg: 58,
            ),
          ),
        ),
        accountReader: const _AccountReader(
          ProfileAccountSnapshot(
            username: 'canonical-user',
            avatarUrl: 'https://example.com/avatar.png',
            plan: 'plus',
            mobile: '+919000000000',
            isMobileVerified: true,
          ),
        ),
      );

      final result = await reader.read();

      expect(result, isNotNull);
      expect(result!.name, 'Canonical Name');
      expect(result.gender, ProfileGender.female);
      expect(result.dateOfBirth, DateTime(1994, 4, 5));
      expect(result.heightCm, 166);
      expect(result.currentWeightKg, 62);
      expect(result.targetWeightKg, 58);
      expect(result.unitPreferences, profile.unitPreferences);
      expect(result.activityLevel, ProfileActivityLevel.veryActive);
      expect(result.healthConditions, profile.healthConditions);
      expect(result.otherHealthCondition, 'Canonical condition');
      expect(result.username, 'canonical-user');
      expect(result.avatarUrl, 'https://example.com/avatar.png');
      expect(result.plan, 'plus');
      expect(result.mobile, '+919000000000');
      expect(result.isMobileVerified, isTrue);
      expect(result.goals, isEmpty);
    });

    test('returns missing when canonical Profile is missing', () async {
      final body = _BodyRepository(
        BodyState(
          latestWeight: BodyWeightEntry(
            weightKg: 70,
            measuredAt: DateTime.utc(2026, 8, 23),
          ),
        ),
      );
      final reader = CanonicalProfileDataReader(
        profileRepository: _ProfileRepository(null),
        bodyRepository: body,
        accountReader: const _AccountReader(
          ProfileAccountSnapshot(plan: 'free'),
        ),
      );

      expect(await reader.read(), isNull);
      expect(body.readCalls, 0);
    });

    test('fails closed instead of fabricating a missing canonical weight',
        () async {
      final reader = CanonicalProfileDataReader(
        profileRepository: _ProfileRepository(
          UserProfileData(
            name: 'User',
            gender: ProfileGender.other,
            dateOfBirth: DateTime(2000, 1, 1),
            unitPreferences: MeasurementUnitPreferences.metric,
            heightCm: 170,
            activityLevel: ProfileActivityLevel.active,
            healthConditions: const {ProfileHealthCondition.none},
          ),
        ),
        bodyRepository: _BodyRepository(const BodyState()),
        accountReader: const _AccountReader(
          ProfileAccountSnapshot(plan: 'free'),
        ),
      );

      await expectLater(reader.read(), throwsA(isA<StateError>()));
    });
  });
}

final class _ProfileRepository implements UserProfileRepository {
  _ProfileRepository(this.value);

  final UserProfileData? value;

  @override
  Future<UserProfileData?> read() async => value;

  @override
  Future<void> upsert(UserProfileData profile) async =>
      throw UnsupportedError('not used by this acceptance');
}

final class _BodyRepository implements BodyRepository {
  _BodyRepository(this.state);

  final BodyState state;
  int readCalls = 0;

  @override
  Future<BodyState> getBodyState() async {
    readCalls++;
    return state;
  }

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async =>
      throw UnsupportedError('not used by this acceptance');

  @override
  Future<void> saveBodySetup(BodySetupData data) async =>
      throw UnsupportedError('not used by this acceptance');
}

final class _AccountReader implements ProfileAccountSnapshotReader {
  const _AccountReader(this.value);

  final ProfileAccountSnapshot? value;

  @override
  Future<ProfileAccountSnapshot?> read() async => value;
}
