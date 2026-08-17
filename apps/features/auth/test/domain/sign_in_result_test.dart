import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('SignInResult', () {
    test('SignInSuccess equality and toString', () {
      const session1 = AuthSession(userId: 'u1', email: 'a@b.com');
      const session2 = AuthSession(userId: 'u1', email: 'a@b.com');
      const success1 = SignInSuccess(session1);
      const success2 = SignInSuccess(session2);

      expect(success1, equals(success2));
      expect(success1.hashCode, equals(success2.hashCode));
      expect(success1.toString(), contains('SignInSuccess'));
    });

    test('SignInCancelled equality and toString', () {
      const c1 = SignInCancelled();
      const c2 = SignInCancelled();

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1.toString(), equals('SignInCancelled()'));
    });

    test('SignInFailure equality and toString', () {
      const f1 = SignInFailure('Network error', code: '400');
      const f2 = SignInFailure('Network error', code: '400');
      const f3 = SignInFailure('Auth error', code: '401');

      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1, isNot(equals(f3)));
      expect(f1.toString(), contains('Network error'));
    });
  });
}
