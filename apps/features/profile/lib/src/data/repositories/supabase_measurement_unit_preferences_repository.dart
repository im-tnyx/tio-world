import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/user_profile_data.dart';
import '../../domain/repositories/measurement_unit_preferences_repository.dart';
import '../../domain/repositories/user_profile_repository.dart';
import 'supabase_user_profile_repository.dart';

/// Canonical measurement-preference adapter backed by `public.user_profiles`.
///
/// Measurement units are part of the common Profile owner. A partial Settings
/// edit therefore reads the current canonical Profile first, preserves all
/// other Profile fields, and writes the new units through [UserProfileRepository].
class SupabaseMeasurementUnitPreferencesRepository
    implements MeasurementUnitPreferencesRepository {
  SupabaseMeasurementUnitPreferencesRepository({
    required SupabaseClient client,
    UserProfileRepository? profileRepository,
  }) : _profileRepository =
            profileRepository ?? SupabaseUserProfileRepository(client: client);

  final UserProfileRepository _profileRepository;

  @override
  Future<void> updateMeasurementUnitPreferences(
    MeasurementUnitPreferences preferences,
  ) async {
    final current = await _profileRepository.read();
    if (current == null) {
      throw StateError(
        'Canonical Profile is not initialized for the current account.',
      );
    }

    await _profileRepository.upsert(
      UserProfileData(
        name: current.name,
        gender: current.gender,
        dateOfBirth: current.dateOfBirth,
        unitPreferences: preferences,
        heightCm: current.heightCm,
        activityLevel: current.activityLevel,
        healthConditions: current.healthConditions,
        otherHealthCondition: current.otherHealthCondition,
      ),
    );
  }
}
