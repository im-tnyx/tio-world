import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/domain/usecases/google_auth_use_case.dart';
import 'package:tio_feature_auth/src/domain/models/auth_session.dart';
import 'package:tio_feature_auth/src/domain/models/backend_user_state.dart';
import 'package:tio_feature_auth/src/domain/repositories/backend_user_sync_repository.dart';
import 'package:tio_feature_auth/src/data/google_sign_in_provider.dart';
import 'package:tio_shared/shared.dart';

class _FakeGoogleSignInProvider extends GoogleSignInProvider {
  GoogleSignInResult resultToReturn = const GoogleSignInCancelled();
  int signInCalls = 0;

  @override
  Future<GoogleSignInResult> signIn() async {
    signInCalls += 1;
    return resultToReturn;
  }
}

class _FakeBackendUserSyncRepository implements BackendUserSyncRepository {
  BackendUserState resultToReturn = const BackendUserUnknown();

  @override
  Future<BackendUserState> syncGoogleUser({
    required AuthSession session,
    required String firebaseIdToken,
    required String deviceId,
    required String deviceFingerprint,
    String? platform,
    String? osVersion,
  }) async => resultToReturn;
}

class _FakeDeviceIdentityProvider implements DeviceIdentityProvider {
  @override
  Future<DeviceIdentity> getIdentity() async => const DeviceIdentity(
    deviceId: 'dev123',
    deviceFingerprint: 'fin123',
  );
}

void main() {
  late _FakeGoogleSignInProvider googleProvider;
  late _FakeBackendUserSyncRepository syncRepository;
  late _FakeDeviceIdentityProvider deviceProvider;

  setUp(() {
    googleProvider = _FakeGoogleSignInProvider();
    syncRepository = _FakeBackendUserSyncRepository();
    deviceProvider = _FakeDeviceIdentityProvider();
  });

  test('legacy Firebase Google path fails closed by default before chooser',
      () async {
    final useCase = GoogleAuthUseCase(
      googleSignInProvider: googleProvider,
      backendUserSyncRepository: syncRepository,
      deviceIdentityProvider: deviceProvider,
    );

    final result = await useCase();

    expect(result, isA<GoogleAuthFailed>());
    expect(
      (result as GoogleAuthFailed).message,
      GoogleAuthUseCase.unavailableMessage,
    );
    expect(googleProvider.signInCalls, 0);
  });

  test('explicit legacy compatibility returns cancelled when chooser cancels',
      () async {
    googleProvider.resultToReturn = const GoogleSignInCancelled();
    final useCase = GoogleAuthUseCase(
      googleSignInProvider: googleProvider,
      backendUserSyncRepository: syncRepository,
      deviceIdentityProvider: deviceProvider,
      legacyFirebaseEnabled: true,
    );

    final result = await useCase();

    expect(result, isA<GoogleAuthCancelled>());
    expect(googleProvider.signInCalls, 1);
  });

  test('explicit legacy compatibility returns provider failure', () async {
    googleProvider.resultToReturn = const GoogleSignInFailed('error');
    final useCase = GoogleAuthUseCase(
      googleSignInProvider: googleProvider,
      backendUserSyncRepository: syncRepository,
      deviceIdentityProvider: deviceProvider,
      legacyFirebaseEnabled: true,
    );

    final result = await useCase();

    expect(result, isA<GoogleAuthFailed>());
    expect((result as GoogleAuthFailed).message, 'error');
    expect(googleProvider.signInCalls, 1);
  });
}
