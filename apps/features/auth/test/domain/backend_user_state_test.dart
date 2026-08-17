import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/domain/models/backend_user_state.dart';

void main() {
  test('BackendUserState equality and hashCode', () {
    const unknown1 = BackendUserUnknown();
    const unknown2 = BackendUserUnknown();
    expect(unknown1, equals(unknown2));
    expect(unknown1.hashCode, equals(unknown2.hashCode));

    const syncing1 = BackendUserSyncing();
    const syncing2 = BackendUserSyncing();
    expect(syncing1, equals(syncing2));
    expect(syncing1.hashCode, equals(syncing2.hashCode));

    const ready1 = BackendUserReady(
      userId: 'u1',
      referralCode: 'r1',
      isOnboarded: true,
    );
    const ready2 = BackendUserReady(
      userId: 'u1',
      referralCode: 'r1',
      isOnboarded: true,
    );
    const ready3 = BackendUserReady(
      userId: 'u2',
      referralCode: 'r1',
      isOnboarded: true,
    );
    expect(ready1, equals(ready2));
    expect(ready1.hashCode, equals(ready2.hashCode));
    expect(ready1, isNot(equals(ready3)));

    const unauth = BackendSyncUnauthenticated();
    const failed1 = BackendUserFailed(unauth);
    const failed2 = BackendUserFailed(BackendSyncUnauthenticated());
    const failed3 = BackendUserFailed(BackendSyncNetworkFailure());
    expect(failed1, equals(failed2));
    expect(failed1.hashCode, equals(failed2.hashCode));
    expect(failed1, isNot(equals(failed3)));
  });

  test('BackendUserState toString', () {
    expect(
      const BackendUserReady(userId: 'u1', referralCode: 'r1', isOnboarded: true).toString(),
      'BackendUserReady(userId: u1, isOnboarded: true)',
    );
    expect(
      const BackendUserFailed(BackendSyncUnauthenticated()).toString(),
      'BackendUserFailed(BackendSyncUnauthenticated())',
    );
  });
}
