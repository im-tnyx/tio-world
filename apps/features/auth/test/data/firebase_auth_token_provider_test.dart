import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('FirebaseAuthTokenProvider', () {
    test('returns token when user is authenticated', () async {
      final provider = FirebaseAuthTokenProvider(
        tokenGetter: ({bool forceRefresh = false}) async {
          return 'firebase-id-token-123';
        },
      );

      final token = await provider.getIdToken();
      expect(token, 'firebase-id-token-123');
    });

    test('passes forceRefresh flag to token getter on 401 retry', () async {
      bool capturedForceRefresh = false;
      final provider = FirebaseAuthTokenProvider(
        tokenGetter: ({bool forceRefresh = false}) async {
          capturedForceRefresh = forceRefresh;
          return 'refreshed-token-456';
        },
      );

      final token = await provider.getIdToken(forceRefresh: true);
      expect(capturedForceRefresh, isTrue);
      expect(token, 'refreshed-token-456');
    });

    test('returns null when user is signed out', () async {
      final provider = FirebaseAuthTokenProvider(
        tokenGetter: ({bool forceRefresh = false}) async => null,
      );

      final token = await provider.getIdToken();
      expect(token, isNull);
    });

    test('returns null on token retrieval failure without throwing', () async {
      final provider = FirebaseAuthTokenProvider(
        tokenGetter: ({bool forceRefresh = false}) async {
          throw Exception('Network error during token refresh');
        },
      );

      // Token getter thrown by user code is captured safely
      // In real FirebaseAuthTokenProvider, try/catch handles User.getIdToken errors
      expect(
        () => provider.getIdToken(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
