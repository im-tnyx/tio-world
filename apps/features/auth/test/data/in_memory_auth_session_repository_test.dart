import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('InMemoryAuthSessionRepository', () {
    test('emits initial unauthenticated state and allows setting authenticated session', () async {
      final repo = InMemoryAuthSessionRepository();

      expect(await repo.currentSessionState, isA<AuthSessionUnauthenticated>());

      final emittedStates = <AuthSessionState>[];
      final subscription = repo.sessionState.listen(emittedStates.add);

      repo.setSession(const AuthSession(userId: 'usr_001', email: 'test@tnyx.app'));
      expect(await repo.currentSessionState, isA<AuthSessionAuthenticated>());
      expect(
        (await repo.currentSessionState as AuthSessionAuthenticated).session.userId,
        'usr_001',
      );

      await repo.signOut();
      expect(await repo.currentSessionState, isA<AuthSessionUnauthenticated>());

      await subscription.cancel();
      repo.dispose();
    });
  });
}
