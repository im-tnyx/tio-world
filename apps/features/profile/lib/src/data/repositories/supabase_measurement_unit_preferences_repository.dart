import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';

import '../../domain/repositories/measurement_unit_preferences_repository.dart';

/// Field-specific Supabase owner for measurement display/input preferences.
class SupabaseMeasurementUnitPreferencesRepository
    implements MeasurementUnitPreferencesRepository {
  const SupabaseMeasurementUnitPreferencesRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Future<void> updateMeasurementUnitPreferences(
    MeasurementUnitPreferences preferences,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('User is not authenticated');
    }

    await _client.from('users').update({
      'weight_unit': preferences.weightUnit.storageValue,
      'height_unit': preferences.heightUnit.storageValue,
      'distance_unit': preferences.distanceUnit.storageValue,
      'volume_unit': preferences.volumeUnit.storageValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userId);
  }
}
