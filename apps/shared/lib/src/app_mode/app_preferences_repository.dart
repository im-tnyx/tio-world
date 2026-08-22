import 'app_preferences_state.dart';

/// Backend-neutral durable owner boundary for account-level App Mode/navigation.
///
/// Concrete Supabase/HTTP adapters belong outside this shared domain contract.
abstract interface class AppPreferencesRepository {
  Future<AppPreferencesState> read();

  Future<void> upsert(AppPreferencesUpdate preferences);
}
