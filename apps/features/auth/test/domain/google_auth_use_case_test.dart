import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/domain/usecases/google_auth_use_case.dart';
import 'package:tio_feature_auth/src/domain/models/auth_session.dart';
import 'package:tio_feature_auth/src/domain/models/backend_user_state.dart';
import 'package:tio_feature_auth/src/domain/repositories/backend_user_sync_repository.dart';
import 'package:tio_feature_auth/src/data/google_sign_in_provider.dart';
import 'package:tio_shared/shared.dart';

class _FakeGoogleSignInProvider extends GoogleSignInProvider {
  GoogleSignInResult resultToReturn = const GoogleSignInCancelled();

  @override
  Future<GoogleSignInResult> signIn() async => resultToReturn;
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
  late GoogleAuthUseCase useCase;

  setUp(() {
    googleProvider = _FakeGoogleSignInProvider();
    syncRepository = _FakeBackendUserSyncRepository();
    deviceProvider = _FakeDeviceIdentityProvider();
    // Since FirebaseAuth is heavily sealed, we cannot mock it perfectly without mokito.
    // However, we can test the failure paths that don't require the internal Firebase mocks.
    useCase = GoogleAuthUseCase(
      googleSignInProvider: googleProvider,
      backendUserSyncRepository: syncRepository,
      deviceIdentityProvider: deviceProvider,
    );
  });

  test('call returns GoogleAuthCancelled if sign in is cancelled', () async {
    googleProvider.resultToReturn = const GoogleSignInCancelled();
    final result = await useCase();
    expect(result, isA<GoogleAuthCancelled>());
  });

  test('call returns GoogleAuthFailed if sign in fails', () async {
    googleProvider.resultToReturn = const GoogleSignInFailed('error');
    final result = await useCase();
    expect(result, isA<GoogleAuthFailed>());
  });
}
