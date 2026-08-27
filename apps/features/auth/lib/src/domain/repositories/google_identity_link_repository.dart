/// Auth-owned boundary for linking Google to the current authenticated user.
///
/// Implementations must preserve the canonical authenticated UUID and return
/// `true` only after authoritative provider evidence confirms the Google
/// identity is linked. A user-cancelled provider chooser returns `false`.
abstract interface class GoogleIdentityLinkRepository {
  Future<bool> linkGoogleIdentity();
}
