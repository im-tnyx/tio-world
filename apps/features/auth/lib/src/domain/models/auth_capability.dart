/// Explicit capability model describing whether Firebase/Authentication infrastructure
/// is configured and ready in the running environment.
sealed class AuthCapability {
  const AuthCapability();

  bool get isAvailable;
}

/// Authentication service is properly configured and operational.
class AuthCapabilityAvailable extends AuthCapability {
  const AuthCapabilityAvailable();

  @override
  bool get isAvailable => true;

  @override
  bool operator ==(Object other) => other is AuthCapabilityAvailable;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthCapabilityAvailable()';
}

/// Authentication service is unavailable (e.g. Missing Firebase client credentials or init failure).
class AuthCapabilityUnavailable extends AuthCapability {
  const AuthCapabilityUnavailable(this.reason);

  final String reason;

  @override
  bool get isAvailable => false;

  @override
  bool operator ==(Object other) =>
      other is AuthCapabilityUnavailable && other.reason == reason;

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  @override
  String toString() => 'AuthCapabilityUnavailable($reason)';
}
