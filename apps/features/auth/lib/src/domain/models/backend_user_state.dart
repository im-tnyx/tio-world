/// Explicit sealed hierarchy representing backend application-user sync status.
/// Firebase authentication alone is NOT sufficient — the DB user must exist.
sealed class BackendUserState {
  const BackendUserState();
}

/// Initial state before any sync attempt.
class BackendUserUnknown extends BackendUserState {
  const BackendUserUnknown();
  @override bool operator ==(Object other) => other is BackendUserUnknown;
  @override int get hashCode => runtimeType.hashCode;
  @override String toString() => 'BackendUserUnknown()';
}

/// Sync in progress.
class BackendUserSyncing extends BackendUserState {
  const BackendUserSyncing();
  @override bool operator ==(Object other) => other is BackendUserSyncing;
  @override int get hashCode => runtimeType.hashCode;
  @override String toString() => 'BackendUserSyncing()';
}

/// Backend DB user exists and was successfully resolved.
class BackendUserReady extends BackendUserState {
  const BackendUserReady({
    required this.userId,
    required this.referralCode,
    required this.isOnboarded,
  });
  final String userId;
  final String referralCode;
  final bool isOnboarded;
  @override bool operator ==(Object other) =>
    other is BackendUserReady &&
    other.userId == userId &&
    other.referralCode == referralCode &&
    other.isOnboarded == isOnboarded;
  @override int get hashCode => Object.hash(userId, referralCode, isOnboarded);
  @override String toString() => 'BackendUserReady(userId: $userId, isOnboarded: $isOnboarded)';
}

/// Sync failed with an explicit reason.
class BackendUserFailed extends BackendUserState {
  const BackendUserFailed(this.failure);
  final BackendSyncFailure failure;
  @override bool operator ==(Object other) => other is BackendUserFailed && other.failure == failure;
  @override int get hashCode => failure.hashCode;
  @override String toString() => 'BackendUserFailed($failure)';
}

/// Typed failure reasons for backend user sync.
sealed class BackendSyncFailure {
  const BackendSyncFailure();
}

/// Firebase token was invalid or missing.
class BackendSyncUnauthenticated extends BackendSyncFailure {
  const BackendSyncUnauthenticated();
  @override bool operator ==(Object other) => other is BackendSyncUnauthenticated;
  @override int get hashCode => runtimeType.hashCode;
  @override String toString() => 'BackendSyncUnauthenticated()';
}

/// Transient network error — retryable.
class BackendSyncNetworkFailure extends BackendSyncFailure {
  const BackendSyncNetworkFailure();
  @override bool operator ==(Object other) => other is BackendSyncNetworkFailure;
  @override int get hashCode => runtimeType.hashCode;
  @override String toString() => 'BackendSyncNetworkFailure()';
}

/// Server returned 4xx validation error.
class BackendSyncValidationFailure extends BackendSyncFailure {
  const BackendSyncValidationFailure(this.message);
  final String message;
  @override bool operator ==(Object other) => other is BackendSyncValidationFailure && other.message == message;
  @override int get hashCode => Object.hash(runtimeType, message);
  @override String toString() => 'BackendSyncValidationFailure($message)';
}

/// Server returned 5xx or unexpected error.
class BackendSyncServerFailure extends BackendSyncFailure {
  const BackendSyncServerFailure(this.statusCode);
  final int? statusCode;
  @override bool operator ==(Object other) => other is BackendSyncServerFailure && other.statusCode == statusCode;
  @override int get hashCode => Object.hash(runtimeType, statusCode);
  @override String toString() => 'BackendSyncServerFailure($statusCode)';
}
