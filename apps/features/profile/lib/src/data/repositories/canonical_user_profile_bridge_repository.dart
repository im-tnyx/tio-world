import 'dart:async';

import '../../domain/models/profile_setup_data.dart';
import '../../domain/models/user_profile_data.dart';
import '../../domain/repositories/profile_avatar_repository.dart';
import '../../domain/repositories/profile_setup_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';

/// Transitional compatibility facade for callers that still hold the broad
/// [ProfileSetupRepository] type.
///
/// Supabase production semantic Profile reads/writes are canonical-only through
/// [UserProfileRepository]. Avatar actions delegate to the narrow
/// [ProfileAvatarRepository]. Retired broad ProfileSetup semantic methods fail
/// closed so they cannot recreate legacy `public.users` Profile/Body mirrors.
final class CanonicalUserProfileBridgeRepository
    implements ProfileSetupRepository, UserProfileRepository {
  const CanonicalUserProfileBridgeRepository({
    required UserProfileRepository canonicalRepository,
    required ProfileAvatarRepository avatarRepository,
  })  : _canonicalRepository = canonicalRepository,
        _avatarRepository = avatarRepository;

  final UserProfileRepository _canonicalRepository;
  final ProfileAvatarRepository _avatarRepository;

  @override
  Future<UserProfileData?> read() => _canonicalRepository.read();

  @override
  Future<void> upsert(UserProfileData profile) =>
      _canonicalRepository.upsert(profile);

  @override
  Future<void> saveProfileSetup(ProfileSetupData data) {
    return Future<void>.error(
      StateError(
        'Broad Supabase ProfileSetup persistence is retired; use canonical owner repositories.',
      ),
    );
  }

  @override
  Future<ProfileSetupData?> getProfileSetup() {
    return Future<ProfileSetupData?>.error(
      StateError(
        'Broad Supabase ProfileSetup reads are retired; use canonical Profile composition.',
      ),
    );
  }

  @override
  Stream<ProfileSetupData?> watchProfileSetup() {
    return Stream<ProfileSetupData?>.error(
      StateError(
        'Broad Supabase ProfileSetup watches are retired; use canonical Profile composition.',
      ),
    );
  }

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) =>
      _avatarRepository.uploadAvatarImage(
        fileName: fileName,
        bytes: bytes,
      );

  @override
  Future<void> deleteAvatarImage() => _avatarRepository.deleteAvatarImage();

  @override
  Future<void> updateAvatarFrame(String frame) async {
    // Avatar framing is entitlement-derived display state, not persisted here.
  }
}
