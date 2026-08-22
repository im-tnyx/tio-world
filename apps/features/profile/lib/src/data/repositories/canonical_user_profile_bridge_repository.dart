import 'dart:async';

import '../../domain/models/profile_setup_data.dart';
import '../../domain/models/user_profile_data.dart';
import '../../domain/repositories/profile_setup_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';

/// Transitional O2 composition bridge.
///
/// Legacy Profile/avatar/settings surfaces continue through
/// [ProfileSetupRepository], while Product Onboarding can use the same injected
/// object through [UserProfileRepository] and therefore reach only the canonical
/// common Profile owner.
final class CanonicalUserProfileBridgeRepository
    implements ProfileSetupRepository, UserProfileRepository {
  const CanonicalUserProfileBridgeRepository({
    required ProfileSetupRepository legacyRepository,
    required UserProfileRepository canonicalRepository,
  })  : _legacyRepository = legacyRepository,
        _canonicalRepository = canonicalRepository;

  final ProfileSetupRepository _legacyRepository;
  final UserProfileRepository _canonicalRepository;

  @override
  Future<UserProfileData?> read() => _canonicalRepository.read();

  @override
  Future<void> upsert(UserProfileData profile) =>
      _canonicalRepository.upsert(profile);

  @override
  Future<void> saveProfileSetup(ProfileSetupData data) =>
      _legacyRepository.saveProfileSetup(data);

  @override
  Future<ProfileSetupData?> getProfileSetup() =>
      _legacyRepository.getProfileSetup();

  @override
  Stream<ProfileSetupData?> watchProfileSetup() =>
      _legacyRepository.watchProfileSetup();

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) =>
      _legacyRepository.uploadAvatarImage(
        fileName: fileName,
        bytes: bytes,
      );

  @override
  Future<void> deleteAvatarImage() => _legacyRepository.deleteAvatarImage();

  @override
  Future<void> updateAvatarFrame(String frame) =>
      _legacyRepository.updateAvatarFrame(frame);
}
