import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

typedef CurrentAppPreferencesUserId = String? Function();

abstract interface class AppPreferencesTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);

  Future<void> upsertRow(Map<String, dynamic> payload);
}

final class SupabaseAppPreferencesTableGateway
    implements AppPreferencesTableGateway {
  const SupabaseAppPreferencesTableGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    return _client
        .from('user_app_preferences')
        .select('app_mode, active_tabs')
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await _client
        .from('user_app_preferences')
        .upsert(payload, onConflict: 'user_id');
  }
}

/// Supabase adapter for the canonical account-level App Mode/navigation owner.
///
/// This adapter intentionally does not read onboarding drafts or local
/// SharedPreferences. O1C/O1D own those orchestration/cache concerns.
final class SupabaseAppPreferencesRepository
    implements AppPreferencesRepository {
  SupabaseAppPreferencesRepository({
    required SupabaseClient client,
    AppPreferencesTableGateway? gateway,
    CurrentAppPreferencesUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseAppPreferencesTableGateway(client),
        _currentUserId =
            currentUserId ?? (() => client.auth.currentUser?.id);

  final AppPreferencesTableGateway _gateway;
  final CurrentAppPreferencesUserId _currentUserId;

  @override
  Future<AppPreferencesState> read() async {
    final userId = _requireUserId();
    final row = await _gateway.readRow(userId);
    if (row == null) return const AppPreferencesState.missing();

    final appMode = _parseAppMode(row['app_mode']);
    final activeTabs = _parseActiveTabs(row['active_tabs']);

    try {
      return AppPreferencesState.present(
        appMode: appMode,
        activeTabs: activeTabs,
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        'Invalid canonical user_app_preferences row: ${error.message}',
      );
    }
  }

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    final userId = _requireUserId();
    await _gateway.upsertRow({
      'user_id': userId,
      'app_mode': preferences.appMode.storageValue,
      'active_tabs': [
        for (final destination in preferences.activeTabs)
          destination.storageValue,
      ],
    });
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to access App preferences.');
    }
    return userId;
  }

  AppMode? _parseAppMode(Object? raw) {
    if (raw == null) return null;
    if (raw is! String) {
      throw const FormatException(
        'Invalid canonical app_mode: expected string or null.',
      );
    }
    final parsed = AppMode.fromStorageValue(raw);
    if (parsed == null) {
      throw FormatException('Invalid canonical app_mode: $raw.');
    }
    return parsed;
  }

  List<AppDestination>? _parseActiveTabs(Object? raw) {
    if (raw == null) return null;
    if (raw is! List) {
      throw const FormatException(
        'Invalid canonical active_tabs: expected list or null.',
      );
    }

    final parsed = <AppDestination>[];
    for (final value in raw) {
      if (value is! String) {
        throw const FormatException(
          'Invalid canonical active_tabs: every item must be a string.',
        );
      }
      final destination = AppDestination.fromStorageValue(value);
      if (destination == null) {
        throw FormatException(
          'Invalid canonical active_tabs destination: $value.',
        );
      }
      parsed.add(destination);
    }
    return parsed;
  }
}
