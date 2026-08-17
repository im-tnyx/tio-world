import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('SupabaseUserDeviceRepository', () {
    test('instantiates with client and device identity provider', () {
      expect(
        () => SupabaseUserDeviceRepository(
          client: FakeSupabaseClient(),
          deviceIdentityProvider: FakeDeviceIdentityProvider(),
        ),
        returnsNormally,
      );
    });

    test('syncCurrentDevice skips sync when user is unauthenticated', () async {
      final fakePostgrest = FakePostgrestClient();
      final repository = SupabaseUserDeviceRepository(
        client: FakeSupabaseClient(currentUser: null, postgrestClient: fakePostgrest),
        deviceIdentityProvider: FakeDeviceIdentityProvider(),
      );

      await repository.syncCurrentDevice();
      expect(fakePostgrest.upsertCalled, isFalse);
    });

    test('syncCurrentDevice upserts device payload when user is authenticated', () async {
      final fakeUser = User(
        id: 'usr-999',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final fakePostgrest = FakePostgrestClient();
      const fakeIdentity = DeviceIdentity(
        deviceId: 'dev-12345',
        deviceFingerprint: 'fp-sha256',
        platform: 'android',
        osVersion: '14',
        appVersion: '1.0.0',
        appBuild: 1,
      );

      final repository = SupabaseUserDeviceRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: fakePostgrest),
        deviceIdentityProvider: FakeDeviceIdentityProvider(identity: fakeIdentity),
      );

      await repository.syncCurrentDevice();
      expect(fakePostgrest.upsertCalled, isTrue);
      expect(fakePostgrest.lastTable, 'user_devices');
      expect(fakePostgrest.lastPayload?['user_id'], 'usr-999');
      expect(fakePostgrest.lastPayload?['device_id'], 'dev-12345');
      expect(fakePostgrest.lastPayload?['device_fingerprint'], 'fp-sha256');
      expect(fakePostgrest.lastPayload?['platform'], 'android');
      expect(fakePostgrest.lastPayload?['os_version'], '14');
      expect(fakePostgrest.lastPayload?['app_version'], '1.0.0');
      expect(fakePostgrest.lastPayload?['app_build'], 1);
      expect(fakePostgrest.lastPayload?['last_login_at'], isNotNull);
      expect(fakePostgrest.lastPayload?['last_active_at'], isNotNull);
      expect(fakePostgrest.lastPayload?['created_at'], isNotNull);
    });

    test('syncCurrentDevice handles error gracefully without throwing', () async {
      final fakeUser = User(
        id: 'usr-999',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final throwingPostgrest = ThrowingFakePostgrestClient();
      final repository = SupabaseUserDeviceRepository(
        client: FakeSupabaseClient(currentUser: fakeUser, postgrestClient: throwingPostgrest),
        deviceIdentityProvider: FakeDeviceIdentityProvider(),
      );

      await expectLater(repository.syncCurrentDevice(), completes);
    });
  });
}

class FakeDeviceIdentityProvider implements DeviceIdentityProvider {
  FakeDeviceIdentityProvider({this.identity});
  final DeviceIdentity? identity;

  @override
  Future<DeviceIdentity> getIdentity() async {
    return identity ??
        const DeviceIdentity(
          deviceId: 'default-dev-id',
          deviceFingerprint: 'default-fp',
          platform: 'android',
          osVersion: '14',
        );
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient({
    this.currentUser,
    FakeGoTrueClient? goTrueClient,
    FakePostgrestClient? postgrestClient,
  })  : _goTrueClient = goTrueClient ?? FakeGoTrueClient(currentUser: currentUser),
        _postgrestClient = postgrestClient ?? FakePostgrestClient();

  final User? currentUser;
  final FakeGoTrueClient _goTrueClient;
  final FakePostgrestClient _postgrestClient;

  @override
  GoTrueClient get auth => _goTrueClient;

  @override
  SupabaseQueryBuilder from(String table) => _postgrestClient.from(table);
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  FakeGoTrueClient({this.currentUser});

  @override
  final User? currentUser;
}

class FakePostgrestClient extends Fake {
  bool upsertCalled = false;
  String? lastTable;
  Map<String, dynamic>? lastPayload;

  SupabaseQueryBuilder from(String table) {
    lastTable = table;
    return FakeSupabaseQueryBuilder(this, table);
  }
}

class ThrowingFakePostgrestClient extends FakePostgrestClient {
  @override
  SupabaseQueryBuilder from(String table) {
    throw const PostgrestException(message: 'Simulated network error');
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  FakeSupabaseQueryBuilder(this._client, this._table);
  final FakePostgrestClient _client;
  final String _table;

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    _client.upsertCalled = true;
    _client.lastTable = _table;
    if (values is Map<String, dynamic>) {
      _client.lastPayload = values;
    }
    return FakePostgrestFilterBuilder();
  }
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) async {
    return onValue(<dynamic>[]);
  }
}
