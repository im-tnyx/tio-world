import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('FirebaseAuthSessionRepository', () {
    test('currentSessionState returns unauthenticated when no current user', () async {
      final repo = FirebaseAuthSessionRepository(
        currentUserGetter: () => null,
      );

      final state = await repo.currentSessionState;
      expect(state, isA<AuthSessionUnauthenticated>());
    });

    test('sessionState stream emits transitions accurately', () async {
      final controller = StreamController<fb.User?>();
      final repo = FirebaseAuthSessionRepository(
        authStateStream: controller.stream,
        currentUserGetter: () => null,
      );

      final emissions = <AuthSessionState>[];
      final subscription = repo.sessionState.listen(emissions.add);

      // Emit signed out
      controller.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(emissions.length, 1);
      expect(emissions.first, isA<AuthSessionUnauthenticated>());

      await subscription.cancel();
      await controller.close();
    });

    test('signOut invokes signOutHandler', () async {
      bool signOutCalled = false;
      final repo = FirebaseAuthSessionRepository(
        signOutHandler: () async {
          signOutCalled = true;
        },
      );

      await repo.signOut();
      expect(signOutCalled, isTrue);
    });
  });
}
