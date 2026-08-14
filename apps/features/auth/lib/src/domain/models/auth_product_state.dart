import 'package:tio_feature_auth/src/domain/models/auth_capability.dart';
import 'package:tio_feature_auth/src/domain/models/auth_session_state.dart';
import 'backend_user_state.dart';

/// Composite auth readiness for protected backend calls and durable onboarding.
///
/// All three conditions must be met:
/// 1. Firebase client configured ([AuthCapabilityAvailable])
/// 2. Firebase user authenticated ([AuthSessionAuthenticated])
/// 3. Backend DB application user synced ([BackendUserReady])
class AuthProductState {
  const AuthProductState({
    required this.capability,
    required this.sessionState,
    required this.backendUserState,
  });

  final AuthCapability capability;
  final AuthSessionState sessionState;
  final BackendUserState backendUserState;

  /// True only when ALL THREE conditions are met.
  bool get isReadyForProtectedBackendCalls =>
      capability.isAvailable &&
      sessionState is AuthSessionAuthenticated &&
      backendUserState is BackendUserReady;

  /// True when Firebase is configured and a session exists.
  bool get isFirebaseAuthenticated =>
      capability.isAvailable && sessionState is AuthSessionAuthenticated;

  /// True when Firebase config is missing entirely.
  bool get isAuthUnavailable => !capability.isAvailable;

  @override
  bool operator ==(Object other) =>
      other is AuthProductState &&
      other.capability == capability &&
      other.sessionState == sessionState &&
      other.backendUserState == backendUserState;

  @override
  int get hashCode => Object.hash(capability, sessionState, backendUserState);

  @override
  String toString() =>
      'AuthProductState(capability: $capability, session: $sessionState, backend: $backendUserState)';
}
