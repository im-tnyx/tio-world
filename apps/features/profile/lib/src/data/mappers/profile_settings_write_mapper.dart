import '../../domain/models/profile_settings_update.dart';

/// Maps Profile Settings-owned values to the exact `public.users` partial
/// update payload. Keeping this mapping narrow prevents accidental field loss.
class ProfileSettingsWriteMapper {
  const ProfileSettingsWriteMapper();

  Map<String, dynamic> toPayload(
    ProfileSettingsUpdate update, {
    required DateTime updatedAt,
  }) {
    final name = update.name.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(update.name, 'name', 'Name is required.');
    }

    final dobIso = update.dateOfBirth.toIso8601String().split('T').first;
    return <String, dynamic>{
      'name': name,
      'gender': update.gender.name,
      'date_of_birth': dobIso,
      'dob': dobIso,
      'height_cm': update.heightCm,
      'current_weight_kg': update.currentWeightKg,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
