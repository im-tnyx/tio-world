import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SupabaseRuntimeKeySource { none, publishable, legacyAnon }

typedef SupabaseRuntimeInitializer = Future<void> Function({
  required String url,
  required String publishableKey,
});

/// One resolved source of truth for client-safe Supabase runtime configuration.
final class SupabaseRuntimeConfig {
  const SupabaseRuntimeConfig._({
    required this.url,
    required this.publishableKey,
    required this.keySource,
    required this.isRelease,
  });

  factory SupabaseRuntimeConfig.fromEnvironment({
    bool isRelease = kReleaseMode,
  }) {
    return SupabaseRuntimeConfig.resolve(
      url: const String.fromEnvironment('SUPABASE_URL'),
      publishableKey:
          const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      legacyAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
      isRelease: isRelease,
    );
  }

  factory SupabaseRuntimeConfig.resolve({
    required String url,
    required String publishableKey,
    required String legacyAnonKey,
    required bool isRelease,
  }) {
    final normalizedUrl = url.trim();
    final normalizedPublishableKey = publishableKey.trim();
    final normalizedLegacyAnonKey = legacyAnonKey.trim();
    final hasAnyKey = normalizedPublishableKey.isNotEmpty ||
        normalizedLegacyAnonKey.isNotEmpty;

    if (normalizedUrl.isEmpty && !hasAnyKey) {
      if (isRelease) {
        throw StateError(
          'Release Supabase configuration is missing. Provide SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
        );
      }
      return const SupabaseRuntimeConfig._(
        url: '',
        publishableKey: '',
        keySource: SupabaseRuntimeKeySource.none,
        isRelease: false,
      );
    }

    if (normalizedUrl.isEmpty || !hasAnyKey) {
      throw StateError(
        'Supabase configuration is partial. SUPABASE_URL and a client-safe publishable/anon key must be supplied together.',
      );
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw StateError('SUPABASE_URL must be a valid http(s) URL.');
    }

    if (normalizedPublishableKey.startsWith('sb_secret_') ||
        normalizedLegacyAnonKey.startsWith('sb_secret_')) {
      throw StateError(
        'Supabase secret keys must never be used by the public Flutter client.',
      );
    }

    if (normalizedPublishableKey.isNotEmpty &&
        !normalizedPublishableKey.startsWith('sb_publishable_')) {
      throw StateError(
        'SUPABASE_PUBLISHABLE_KEY must use the sb_publishable_ key format. Use SUPABASE_ANON_KEY only for explicit legacy anon compatibility.',
      );
    }

    if (normalizedLegacyAnonKey.isNotEmpty &&
        !_isLegacyAnonJwt(normalizedLegacyAnonKey)) {
      throw StateError(
        'SUPABASE_ANON_KEY must be a legacy Supabase JWT whose role claim is anon.',
      );
    }

    final selectedKey = normalizedPublishableKey.isNotEmpty
        ? normalizedPublishableKey
        : normalizedLegacyAnonKey;
    final source = normalizedPublishableKey.isNotEmpty
        ? SupabaseRuntimeKeySource.publishable
        : SupabaseRuntimeKeySource.legacyAnon;

    return SupabaseRuntimeConfig._(
      url: normalizedUrl,
      publishableKey: selectedKey,
      keySource: source,
      isRelease: isRelease,
    );
  }

  final String url;
  final String publishableKey;
  final SupabaseRuntimeKeySource keySource;
  final bool isRelease;

  bool get isConfigured => keySource != SupabaseRuntimeKeySource.none;
}

bool _isLegacyAnonJwt(String key) {
  final parts = key.split('.');
  if (parts.length != 3) return false;

  try {
    final payloadBytes = base64Url.decode(base64Url.normalize(parts[1]));
    final payload = jsonDecode(utf8.decode(payloadBytes));
    return payload is Map<String, dynamic> && payload['role'] == 'anon';
  } catch (_) {
    return false;
  }
}

/// Initializes the global Supabase client when this build is explicitly
/// configured. Release initialization errors propagate; debug/test harnesses
/// may remain unconfigured or degrade to their existing no-Supabase fallbacks.
Future<bool> initializeSupabaseRuntime({
  required SupabaseRuntimeConfig config,
  SupabaseRuntimeInitializer? initializer,
}) async {
  if (!config.isConfigured) return false;

  final initialize = initializer ??
      ({required String url, required String publishableKey}) async {
        await Supabase.initialize(
          url: url,
          publishableKey: publishableKey,
        );
      };

  try {
    await initialize(
      url: config.url,
      publishableKey: config.publishableKey,
    );
    return true;
  } catch (_) {
    if (config.isRelease) rethrow;
    return false;
  }
}
