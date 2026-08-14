import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/domain/models/auth_capability.dart';
import 'package:tio_feature_auth/src/domain/models/auth_product_state.dart';
import 'package:tio_feature_auth/src/domain/models/auth_session.dart';
import 'package:tio_feature_auth/src/domain/models/auth_session_state.dart';
import 'package:tio_feature_auth/src/domain/models/backend_user_state.dart';

void main() {
  test('isReadyForProtectedBackendCalls requires all three conditions', () {
    const capability = AuthCapabilityAvailable();
    const session = AuthSessionAuthenticated(AuthSession(userId: 'u1'));
    const backend = BackendUserReady(userId: 'u1', referralCode: 'r1', isOnboarded: true);

    const state = AuthProductState(
      capability: capability,
      sessionState: session,
      backendUserState: backend,
    );
    expect(state.isReadyForProtectedBackendCalls, isTrue);

    // Missing capability
    expect(
      const AuthProductState(
        capability: AuthCapabilityUnavailable(''),
        sessionState: session,
        backendUserState: backend,
      ).isReadyForProtectedBackendCalls,
      isFalse,
    );

    // Unauthenticated session
    expect(
      const AuthProductState(
        capability: capability,
        sessionState: AuthSessionUnauthenticated(),
        backendUserState: backend,
      ).isReadyForProtectedBackendCalls,
      isFalse,
    );

    // Backend not ready
    expect(
      const AuthProductState(
        capability: capability,
        sessionState: session,
        backendUserState: BackendUserSyncing(),
      ).isReadyForProtectedBackendCalls,
      isFalse,
    );
  });

  test('isFirebaseAuthenticated checks capability and session', () {
    const capability = AuthCapabilityAvailable();
    const session = AuthSessionAuthenticated(AuthSession(userId: 'u1'));
    const state = AuthProductState(
      capability: capability,
      sessionState: session,
      backendUserState: BackendUserUnknown(),
    );
    expect(state.isFirebaseAuthenticated, isTrue);

    expect(
      const AuthProductState(
        capability: AuthCapabilityUnavailable(''),
        sessionState: session,
        backendUserState: BackendUserUnknown(),
      ).isFirebaseAuthenticated,
      isFalse,
    );
  });

  test('isAuthUnavailable', () {
    expect(
      const AuthProductState(
        capability: AuthCapabilityUnavailable(''),
        sessionState: AuthSessionUnknown(),
        backendUserState: BackendUserUnknown(),
      ).isAuthUnavailable,
      isTrue,
    );
  });
}
