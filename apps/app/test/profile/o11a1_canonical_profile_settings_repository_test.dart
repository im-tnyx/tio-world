import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/profile/canonical_profile_settings_repository.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  group('O11A1 CanonicalProfileSettingsRepository', () {
    test('splits Profile and Current Weight writes across canonical owners',
        () async {
      final existing = UserProfileData(
        name: 'Before',
        gender: ProfileGender.male,
        dateOfBirth: DateTime(1990, 1, 2),
        unitPreferences: const UnitPreferences(
          weightUnit: WeightUnit.lb,
          heightUnit: HeightUnit.ftIn,
          distanceUnit: DistanceUnit.mi,
          volumeUnit: VolumeUnit.flOz,
        ),
        heightCm: 180,
        activityLevel: ProfileActivityLevel.veryActive,
        healthConditions: const {ProfileHealthCondition.hypertension},
        otherHealthCondition: 'Preserve me',
      );
      final profile = _ProfileRepository(existing);
      final body = _BodyRepository();
      final measuredAt = DateTime.utc(2026, 8, 23, 13, 30);
      final repository = CanonicalProfileSettingsRepository(
        profileRepository: profile,
        bodyRepository: body,
        now: () => measuredAt,
      );

      await repository.updateProfileSettings(
        ProfileSettingsUpdate(
          name: 'After',
          gender: ProfileGender.female,
          dateOfBirth: DateTime(1992, 3, 4),
          heightCm: 165,
          currentWeightKg: 61.5,
        ),
      );

      expect(profile.readCalls, 1);
      expect(profile.upserts, hasLength(1));
      final saved = profile.upserts.single;
      expect(saved.name, 'After');
      expect(saved.gender, ProfileGender.female);
      expect(saved.dateOfBirth, DateTime(1992, 3, 4));
      expect(saved.heightCm, 165);
      expect(saved.unitPreferences, existing.unitPreferences);
      expect(saved.activityLevel, ProfileActivityLevel.veryActive);
      expect(saved.healthConditions, existing.healthConditions);
      expect(saved.otherHealthCondition, 'Preserve me');

      expect(body.records, hasLength(1));
      final weight = body.records.single;
      expect(weight.weightKg, 61.5);
      expect(weight.measuredAt, measuredAt);
      expect(weight.source, BodyWeightSources.profileSettings);
      expect(body.events, ['recordCurrentWeight']);
    });

    test('fails closed when canonical Profile is missing', () async {
      final profile = _ProfileRepository(null);
      final body = _BodyRepository();
      final repository = CanonicalProfileSettingsRepository(
        profileRepository: profile,
        bodyRepository: body,
      );

      await expectLater(
        repository.updateProfileSettings(
          ProfileSettingsUpdate(
            name: 'User',
            gender: ProfileGender.other,
            dateOfBirth: DateTime(2000, 1, 1),
            heightCm: 170,
            currentWeightKg: 70,
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(profile.upserts, isEmpty);
      expect(body.records, isEmpty);
    });

    test('does not record weight when canonical Profile write fails', () async {
      final profile = _ProfileRepository(
        UserProfileData(
          name: 'Before',
          gender: ProfileGender.other,
          dateOfBirth: DateTime(2000, 1, 1),
          unitPreferences: UnitPreferences.metric,
          heightCm: 170,
          activityLevel: ProfileActivityLevel.active,
          healthConditions: const {ProfileHealthCondition.none},
        ),
        failUpsert: true,
      );
      final body = _BodyRepository();
      final repository = CanonicalProfileSettingsRepository(
        profileRepository: profile,
        bodyRepository: body,
      );

      await expectLater(
        repository.updateProfileSettings(
          ProfileSettingsUpdate(
            name: 'After',
            gender: ProfileGender.female,
            dateOfBirth: DateTime(1999, 2, 3),
            heightCm: 168,
            currentWeightKg: 65,
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(profile.upserts, hasLength(1));
      expect(body.records, isEmpty);
    });
  });
}

final class _ProfileRepository implements UserProfileRepository {
  _ProfileRepository(this.current, {this.failUpsert = false});

  UserProfileData? current;
  final bool failUpsert;
  int readCalls = 0;
  final List<UserProfileData> upserts = [];

  @override
  Future<UserProfileData?> read() async {
    readCalls++;
    return current;
  }

  @override
  Future<void> upsert(UserProfileData profile) async {
    upserts.add(profile);
    if (failUpsert) throw StateError('profile write failed');
    current = profile;
  }
}

final class _BodyRepository implements BodyRepository {
  final List<BodyWeightRecord> records = [];
  final List<String> events = [];

  @override
  Future<BodyState> getBodyState() async => const BodyState();

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    events.add('recordCurrentWeight');
    records.add(record);
  }

  @override
  Future<void> saveBodySetup(BodySetupData data) async {
    throw UnsupportedError('not used by this acceptance');
  }

  @override
  Future<void> setActiveBodyGoal(BodyGoalUpdate update) async {
    throw UnsupportedError('not used by this acceptance');
  }
}
