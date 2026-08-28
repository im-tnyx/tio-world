enum HealthConnectionStatus {
  /// The current platform/app build cannot offer a health connection.
  unavailable,

  /// Health connection is available, but authorization has not been requested.
  notRequested,

  /// The latest explicit authorization attempt was not granted.
  denied,

  /// A real platform adapter confirmed the required authorization/capability.
  connected,
}
