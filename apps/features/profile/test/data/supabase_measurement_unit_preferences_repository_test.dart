import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('SupabaseMeasurementUnitPreferencesRepository canonical cutover', () {
    test('preserves non-unit canonical Profile fields', () async {
      final existing = UserProfileData(
        name: 'Profile User',
        gender: ProfileGender.female,
        dateOfBirth: DateTime(1995, 6, 7),
        unitPreferences: MeasurementUnitPreferences.metric,
        heightCm: 164,
        activityLevel: ProfileActivityLevel.veryActive,
        healthConditions: const {ProfileHealthCondition.hypertension},
        otherHealthCondition: 'Preserve condition',
      );
      final profileRepository = _ProfileRepository(existing);
      final repository = SupabaseMeasurementUnitPreferencesRepository(
        client: SupabaseClient('https://example.supabase.co', 'test-anon-key'),
        profileRepository: profileRepository,
      );
      const requested = MeasurementUnitPreferences(
        weightUnit: WeightUnit.lb,
        heightUnit: HeightUnit.ftIn,
        distanceUnit: DistanceUnit.mi,
        volumeUnit: VolumeUnit.flOz,
      );

      await repository.updateMeasurementUnitPreferences(requested);

      expect(profileRepository.readCalls, 1);
      expect(profileRepository.upserts, hasLength(1));
      final saved = profileRepository.upserts.single;
      expect(saved.unitPreferences, requested);
      expect(saved.name, existing.name);
      expect(saved.gender, existing.gender);
      expect(saved.dateOfBirth, existing.dateOfBirth);
      expect(saved.heightCm, existing.heightCm);
      expect(saved.activityLevel, existing.activityLevel);
      expect(saved.healthConditions, existing.healthConditions);
      expect(saved.otherHealthCondition, existing.otherHealthCondition);
    });

    test('fails closed when canonical Profile is missing', () async {
      final profileRepository = _ProfileRepository(null);
      final repository = SupabaseMeasurementUnitPreferencesRepository(
        client: SupabaseClient('https://example.supabase.co', 'test-anon-key'),
        profileRepository: profileRepository,
      );

      await expectLater(
        repository.updateMeasurementUnitPreferences(
          MeasurementUnitPreferences.metric,
        ),
        throwsA(isA<StateError>()),
      );

      expect(profileRepository.upserts, isEmpty);
    });
  });
}

final class _ProfileRepository implements UserProfileRepository {
  _ProfileRepository(this.current);

  UserProfileData? current;
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
    current = profile;
  }
}
