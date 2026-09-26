import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../startup/supabase_runtime_config.dart';

final supabaseConfigProvider = Provider<SupabaseRuntimeConfig>((ref) {
  return SupabaseRuntimeConfig.fromEnvironment();
});

/// Provider for injected or initialized [SupabaseClient].
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  final config = ref.watch(supabaseConfigProvider);
  if (!config.isConfigured) return null;

  try {
    return Supabase.instance.client;
  } catch (_) {
    if (config.isRelease) rethrow;
    return null;
  }
});

/// Provider for global API configuration (base URL and timeouts).
final apiConfigProvider = Provider<ApiConfig>((ref) {
  const baseUrl = String.fromEnvironment(
    'TIO_API_BASE_URL',
    defaultValue: 'https://api.tnyx.app',
  );
  return const ApiConfig(baseUrl: baseUrl);
});

final publicApiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  return DioApiClient.public(config: config);
});
