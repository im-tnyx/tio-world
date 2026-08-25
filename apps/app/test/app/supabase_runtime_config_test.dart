import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/supabase_runtime_config.dart';

void main() {
  group('SupabaseRuntimeConfig', () {
    test('debug/test missing config stays explicitly unconfigured', () {
      final config = SupabaseRuntimeConfig.resolve(
        url: '',
        publishableKey: '',
        legacyAnonKey: '',
        isRelease: false,
      );

      expect(config.isConfigured, isFalse);
      expect(config.url, isEmpty);
      expect(config.publishableKey, isEmpty);
      expect(config.keySource, SupabaseRuntimeKeySource.none);
      expect(config.isRelease, isFalse);
    });

    test('release missing config fails closed', () {
      expect(
        () => SupabaseRuntimeConfig.resolve(
          url: '',
          publishableKey: '',
          legacyAnonKey: '',
          isRelease: true,
        ),
        throwsStateError,
      );
    });

    test('partial config fails in every build mode', () {
      expect(
        () => SupabaseRuntimeConfig.resolve(
          url: 'https://example.supabase.co',
          publishableKey: '',
          legacyAnonKey: '',
          isRelease: false,
        ),
        throwsStateError,
      );
      expect(
        () => SupabaseRuntimeConfig.resolve(
          url: '',
          publishableKey: 'sb_publishable_example',
          legacyAnonKey: '',
          isRelease: false,
        ),
        throwsStateError,
      );
    });

    test('modern publishable key is canonical and wins over legacy anon', () {
      final config = SupabaseRuntimeConfig.resolve(
        url: ' https://example.supabase.co ',
        publishableKey: ' sb_publishable_primary ',
        legacyAnonKey: 'legacy-anon-token',
        isRelease: true,
      );

      expect(config.isConfigured, isTrue);
      expect(config.url, 'https://example.supabase.co');
      expect(config.publishableKey, 'sb_publishable_primary');
      expect(config.keySource, SupabaseRuntimeKeySource.publishable);
      expect(config.isRelease, isTrue);
    });

    test('explicit legacy anon key remains a bounded compatibility path', () {
      final config = SupabaseRuntimeConfig.resolve(
        url: 'https://example.supabase.co',
        publishableKey: '',
        legacyAnonKey: 'legacy-anon-token',
        isRelease: true,
      );

      expect(config.isConfigured, isTrue);
      expect(config.publishableKey, 'legacy-anon-token');
      expect(config.keySource, SupabaseRuntimeKeySource.legacyAnon);
    });

    test('publishable env rejects wrong key format and client secret keys', () {
      expect(
        () => SupabaseRuntimeConfig.resolve(
          url: 'https://example.supabase.co',
          publishableKey: 'legacy-anon-token',
          legacyAnonKey: '',
          isRelease: false,
        ),
        throwsStateError,
      );
      expect(
        () => SupabaseRuntimeConfig.resolve(
          url: 'https://example.supabase.co',
          publishableKey: 'sb_secret_never-client',
          legacyAnonKey: '',
          isRelease: false,
        ),
        throwsStateError,
      );
      expect(
        () => SupabaseRuntimeConfig.resolve(
          url: 'https://example.supabase.co',
          publishableKey: '',
          legacyAnonKey: 'sb_secret_never-client',
          isRelease: false,
        ),
        throwsStateError,
      );
    });

    test('invalid Supabase URL is rejected', () {
      expect(
        () => SupabaseRuntimeConfig.resolve(
          url: 'not-a-url',
          publishableKey: 'sb_publishable_example',
          legacyAnonKey: '',
          isRelease: false,
        ),
        throwsStateError,
      );
    });

    test('provider default does not fabricate Supabase readiness in tests', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final config = container.read(supabaseConfigProvider);
      expect(config.isConfigured, isFalse);
      expect(container.read(supabaseClientProvider), isNull);
    });
  });

  group('initializeSupabaseRuntime', () {
    test('unconfigured debug/test build skips initializer', () async {
      final config = SupabaseRuntimeConfig.resolve(
        url: '',
        publishableKey: '',
        legacyAnonKey: '',
        isRelease: false,
      );
      var calls = 0;

      final initialized = await initializeSupabaseRuntime(
        config: config,
        isRelease: false,
        initializer: ({required url, required publishableKey}) async {
          calls += 1;
        },
      );

      expect(initialized, isFalse);
      expect(calls, 0);
    });

    test('successful initialization forwards resolved URL and key', () async {
      final config = SupabaseRuntimeConfig.resolve(
        url: 'https://example.supabase.co',
        publishableKey: 'sb_publishable_example',
        legacyAnonKey: '',
        isRelease: true,
      );
      String? receivedUrl;
      String? receivedKey;

      final initialized = await initializeSupabaseRuntime(
        config: config,
        isRelease: true,
        initializer: ({required url, required publishableKey}) async {
          receivedUrl = url;
          receivedKey = publishableKey;
        },
      );

      expect(initialized, isTrue);
      expect(receivedUrl, 'https://example.supabase.co');
      expect(receivedKey, 'sb_publishable_example');
    });

    test('debug initialization failure keeps existing unavailable fallback',
        () async {
      final config = SupabaseRuntimeConfig.resolve(
        url: 'https://example.supabase.co',
        publishableKey: 'sb_publishable_example',
        legacyAnonKey: '',
        isRelease: false,
      );

      final initialized = await initializeSupabaseRuntime(
        config: config,
        isRelease: false,
        initializer: ({required url, required publishableKey}) async {
          throw StateError('synthetic init failure');
        },
      );

      expect(initialized, isFalse);
    });

    test('release initialization failure propagates', () async {
      final config = SupabaseRuntimeConfig.resolve(
        url: 'https://example.supabase.co',
        publishableKey: 'sb_publishable_example',
        legacyAnonKey: '',
        isRelease: true,
      );

      await expectLater(
        initializeSupabaseRuntime(
          config: config,
          isRelease: true,
          initializer: ({required url, required publishableKey}) async {
            throw StateError('synthetic init failure');
          },
        ),
        throwsStateError,
      );
    });
  });
}
