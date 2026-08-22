import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  test('canonical upsert never calls legacy broad save', () async {
    final legacy = _FakeLegacyProfileRepository();
    final canonical = _FakeCanonicalUserProfileRepository();
    final bridge = CanonicalUserProfileBridgeRepository(
      legacyRepository: legacy,
      canonicalRepository: canonical,
    );
    final profile = UserProfileData(
      name: 'Tio User',
      gender: ProfileGender.female,
      dateOfBirth: DateTime(1996, 6, 15),
      unitPreferences: const MeasurementUnitPreferences(),
      heightCm: 165,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {ProfileHealthCondition.none},
    );

    await bridge.upsert(profile);

    expect(canonical.data, profile);
    expect(legacy.saveCalls, 0);
  });

  test('legacy broad operations remain delegated for compatibility surfaces',
      () async {
    final legacy = _FakeLegacyProfileRepository();
    final canonical = _FakeCanonicalUserProfileRepository();
    final bridge = CanonicalUserProfileBridgeRepository(
      legacyRepository: legacy,
      canonicalRepository: canonical,
    );
    final broad = ProfileSetupData(
      name: 'Legacy User',
      gender: ProfileGender.male,
      goals: const {},
      dateOfBirth: DateTime(1990, 1, 1),
      heightCm: 180,
      currentWeightKg: 80,
      activityLevel: ProfileActivityLevel.light,
      healthConditions: const {ProfileHealthCondition.none},
    );

    await bridge.saveProfileSetup(broad);

    expect(legacy.saved, broad);
    expect(legacy.saveCalls, 1);
    expect(canonical.data, isNull);
  });
}

class _FakeLegacyProfileRepository implements ProfileSetupRepository {
  int saveCalls = 0;
  ProfileSetupData? saved;

  @override
  Future<void> saveProfileSetup(ProfileSetupData data) async {
    saveCalls += 1;
    saved = data;
  }

  @override
  Future<ProfileSetupData?> getProfileSetup() async => saved;

  @override
  Stream<ProfileSetupData?> watchProfileSetup() => const Stream.empty();

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) async =>
      'memory://$fileName';

  @override
  Future<void> deleteAvatarImage() async {}

  @override
  Future<void> updateAvatarFrame(String frame) async {}
}

class _FakeCanonicalUserProfileRepository implements UserProfileRepository {
  UserProfileData? data;

  @override
  Future<UserProfileData?> read() async => data;

  @override
  Future<void> upsert(UserProfileData profile) async {
    data = profile;
  }
}
