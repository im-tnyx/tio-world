/// Builds the canonical profile-avatar fields for a `public.users` write.
///
/// `avatar_url` is the only field that receives new avatar values. The legacy
/// `profile_image` column remains read-compatible only and is cleared solely
/// during an explicit delete so an old fallback image cannot reappear.
Map<String, dynamic> buildCanonicalAvatarWrite({
  String? avatarUrl,
  bool clear = false,
}) {
  if (clear) {
    return const {
      'avatar_url': null,
      'profile_image': null,
    };
  }

  final normalized = avatarUrl?.trim();
  if (normalized == null || normalized.isEmpty) {
    // A missing avatar in onboarding/profile setup means "leave the current
    // avatar untouched", not "delete the user's avatar".
    return const {};
  }

  return {'avatar_url': normalized};
}
