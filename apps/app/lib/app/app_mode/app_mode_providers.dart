import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_shared/shared.dart';

import '../network_providers.dart';
import 'app_mode_controller.dart';
import 'supabase_app_preferences_repository.dart';

final appModeControllerProvider =
    ChangeNotifierProvider<AppModeController>((ref) {
  throw StateError(
      'AppModeController must be overridden at the app composition boundary.');
});

/// Canonical authenticated-account App Mode/navigation repository.
///
/// Local SharedPreferences remains a separate cache/staging boundary during O1.
final appPreferencesRepositoryProvider =
    Provider<AppPreferencesRepository?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  if (supabaseClient == null) {
    return null;
  }
  return SupabaseAppPreferencesRepository(client: supabaseClient);
});
