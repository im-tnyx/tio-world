import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('AuthSession', () {
    test('props equality and hash code', () {
      const session1 = AuthSession(
        userId: 'user_123',
        email: 'user@example.com',
        phone: '+1234567890',
        displayName: 'Test User',
      );
      const session2 = AuthSession(
        userId: 'user_123',
        email: 'user@example.com',
        phone: '+1234567890',
        displayName: 'Test User',
      );
      const session3 = AuthSession(
        userId: 'user_456',
        email: 'other@example.com',
      );

      expect(session1, equals(session2));
      expect(session1.hashCode, equals(session2.hashCode));
      expect(session1, isNot(equals(session3)));
    });
  });

  group('AuthSessionState', () {
    test('state transitions and equality', () {
      const unknown = AuthSessionUnknown();
      const unauth = AuthSessionUnauthenticated();
      const auth1 = AuthSessionAuthenticated(
        AuthSession(userId: 'u1'),
      );
      const auth2 = AuthSessionAuthenticated(
        AuthSession(userId: 'u1'),
      );

      expect(unknown, isA<AuthSessionUnknown>());
      expect(unauth, isA<AuthSessionUnauthenticated>());
      expect(auth1, equals(auth2));
      expect(auth1, isNot(equals(unauth)));
    });
  });
}
