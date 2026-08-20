import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_profile/src/data/mappers/profile_settings_write_mapper.dart';

void main() {
  const mapper = ProfileSettingsWriteMapper();

  test('maps only Profile Settings-owned public.users fields', () {
    final payload = mapper.toPayload(
      ProfileSettingsUpdate(
        name: '  Santosh Jangid  ',
        gender: ProfileGender.male,
        dateOfBirth: DateTime(1995, 6, 5),
        heightCm: 180,
        currentWeightKg: 80,
      ),
      updatedAt: DateTime.utc(2026, 8, 20, 4),
    );

    expect(payload, {
      'name': 'Santosh Jangid',
      'gender': 'male',
      'date_of_birth': '1995-06-05',
      'dob': '1995-06-05',
      'height_cm': 180,
      'current_weight_kg': 80,
      'updated_at': '2026-08-20T04:00:00.000Z',
    });

    for (final forbidden in const [
      'username',
      'mobile',
      'mobile_verified_at',
      'goals',
      'target_weight_kg',
      'activity_level',
      'health_conditions',
      'other_health_condition',
      'avatar_url',
      'profile_image',
      'plan',
      'unit_preferences',
      'account_setup_completed_at',
      'is_onboarded',
    ]) {
      expect(payload, isNot(contains(forbidden)));
    }
  });
}
