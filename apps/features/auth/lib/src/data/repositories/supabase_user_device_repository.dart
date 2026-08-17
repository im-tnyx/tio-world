import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/user_device_repository.dart';

/// Supabase-backed implementation of [UserDeviceRepository].
///
/// Upserts the current device identity into `public.user_devices`.
class SupabaseUserDeviceRepository implements UserDeviceRepository {
  SupabaseUserDeviceRepository({
    required SupabaseClient client,
    required DeviceIdentityProvider deviceIdentityProvider,
  })  : _client = client,
        _deviceIdentityProvider = deviceIdentityProvider;

  final SupabaseClient _client;
  final DeviceIdentityProvider _deviceIdentityProvider;

  @override
  Future<void> syncCurrentDevice() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      developer.log('SupabaseUserDeviceRepository: No authenticated user, skipping device sync');
      return;
    }

    try {
      final identity = await _deviceIdentityProvider.getIdentity();
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final payload = <String, dynamic>{
        'user_id': user.id,
        'device_id': identity.deviceId,
        'device_fingerprint': identity.deviceFingerprint,
        'platform': identity.platform ?? 'unknown',
        if (identity.osVersion != null) 'os_version': identity.osVersion,
        if (identity.appVersion != null) 'app_version': identity.appVersion,
        if (identity.appBuild != null) 'app_build': identity.appBuild,
        if (identity.fcmToken != null) 'fcm_token': identity.fcmToken,
        'last_login_at': nowIso,
        'last_active_at': nowIso,
        'created_at': nowIso,
      };

      await _client.from('user_devices').upsert(
        payload,
        onConflict: 'user_id,device_id',
      );
      developer.log('SupabaseUserDeviceRepository: Device ${identity.deviceId} synced for user ${user.id}');
    } catch (e, st) {
      developer.log(
        'SupabaseUserDeviceRepository: Error syncing device',
        error: e,
        stackTrace: st,
      );
      // Non-blocking: device sync failures should not crash user authentication/interaction
    }
  }
}

/// No-op implementation of [UserDeviceRepository] for tests or unconfigured environments.
class NoOpUserDeviceRepository implements UserDeviceRepository {
  const NoOpUserDeviceRepository();

  @override
  Future<void> syncCurrentDevice() async {}
}
