/// Narrow contract for obtaining authentication credentials (e.g. Firebase ID Token)
/// to attach to protected backend requests.
abstract interface class AuthTokenProvider {
  /// Returns the current valid ID token or null if unauthenticated.
  /// When [forceRefresh] is true, forces a token refresh from the identity provider.
  Future<String?> getIdToken({bool forceRefresh = false});
}

/// Fallback token provider representing an unavailable / unconfigured auth state.
class UnavailableAuthTokenProvider implements AuthTokenProvider {
  const UnavailableAuthTokenProvider();

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => null;
}
