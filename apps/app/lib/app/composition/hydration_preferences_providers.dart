import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_settings/settings.dart';

import '../hydration_preferences_session_boundary.dart';

/// Settings-owned, device-local Default Glass Size preference.
final hydrationPreferencesRepositoryProvider =
    Provider<HydrationPreferencesRepository>(
  (ref) => SharedPreferencesHydrationPreferencesRepository(),
);

final hydrationPreferencesSessionBoundaryProvider =
    Provider<HydrationPreferencesSessionBoundary>(
  (ref) => HydrationPreferencesSessionBoundary(
    ref.watch(hydrationPreferencesRepositoryProvider),
  ),
);

final hydrationPreferencesDataProvider =
    FutureProvider.autoDispose<HydrationPreferences>((ref) async {
  final repository = ref.watch(hydrationPreferencesRepositoryProvider);
  return repository.read();
});
