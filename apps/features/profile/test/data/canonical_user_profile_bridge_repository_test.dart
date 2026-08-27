import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  group('CanonicalUserProfileBridgeRepository', () {
    test('canonical upsert delegates only to UserProfile owner', () async {
      final canonical = _FakeCanonicalUserProfileRepository();
      final bridge = CanonicalUserProfileBridgeRepository(
        canonicalRepository: canonical,
        avatarRepository: _RecordingAvatarRepository(),
      );
      final profile = UserProfileData(
        name: 'Tio User',
        gender: ProfileGender.female,
        dateOfBirth: DateTime(1996, 6, 15),
        unitPreferences: const UnitPreferences(),
        heightCm: 165,
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
      );

      await bridge.upsert(profile);

      expect(canonical.data, profile);
    });

    test('retired broad ProfileSetup reads and writes fail closed', () async {
      final bridge = CanonicalUserProfileBridgeRepository(
        canonicalRepository: _FakeCanonicalUserProfileRepository(),
        avatarRepository: _RecordingAvatarRepository(),
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

      await expectLater(bridge.saveProfileSetup(broad), throwsStateError);
      await expectLater(bridge.getProfileSetup(), throwsStateError);
      await expectLater(
        bridge.watchProfileSetup(),
        emitsError(isA<StateError>()),
      );
    });

    test('avatar actions delegate only to narrow avatar owner', () async {
      final avatar = _RecordingAvatarRepository();
      final bridge = CanonicalUserProfileBridgeRepository(
        canonicalRepository: _FakeCanonicalUserProfileRepository(),
        avatarRepository: avatar,
      );

      final url = await bridge.uploadAvatarImage(
        fileName: 'avatar.jpg',
        bytes: const [4, 5, 6],
      );
      await bridge.deleteAvatarImage();

      expect(url, 'https://example.test/canonical-avatar.jpg');
      expect(avatar.uploadCalls, 1);
      expect(avatar.deleteCalls, 1);
    });
  });
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

class _RecordingAvatarRepository implements ProfileAvatarRepository {
  int uploadCalls = 0;
  int deleteCalls = 0;

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) async {
    uploadCalls += 1;
    return 'https://example.test/canonical-avatar.jpg';
  }

  @override
  Future<void> deleteAvatarImage() async {
    deleteCalls += 1;
  }
}
