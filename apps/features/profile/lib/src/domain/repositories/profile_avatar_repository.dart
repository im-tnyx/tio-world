/// Narrow owner boundary for Profile avatar media actions.
///
/// Avatar media remains account-adjacent metadata stored through `avatar_url`;
/// this contract intentionally exposes no common Profile or Body persistence.
abstract interface class ProfileAvatarRepository {
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  });

  Future<void> deleteAvatarImage();
}
