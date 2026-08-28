import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/profile_activity_level.dart';
import '../../domain/models/profile_gender.dart';
import '../../domain/models/profile_health_condition.dart';
import '../../domain/models/user_profile_data.dart';
import '../../domain/repositories/user_profile_repository.dart';

typedef CurrentUserProfileUserId = String? Function();

abstract interface class UserProfileTableGateway {
  Future<Map<String, dynamic>?> readRow(String userId);

  Future<void> upsertRow(Map<String, dynamic> payload);
}

final class SupabaseUserProfileTableGateway implements UserProfileTableGateway {
  const SupabaseUserProfileTableGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    return _client
        .from('user_profiles')
        .select(
          'name, gender, date_of_birth, height_cm, activity_level, '
          'health_conditions, other_health_condition, unit_preferences',
        )
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    await _client.from('user_profiles').upsert(payload, onConflict: 'user_id');
  }
}

/// Supabase adapter for the canonical common personal Profile owner.
///
/// It intentionally knows nothing about Account/contact, App Mode, Body,
/// Wellness, Nutrition, Workout, avatar or plan state.
final class SupabaseUserProfileRepository implements UserProfileRepository {
  SupabaseUserProfileRepository({
    required SupabaseClient client,
    UserProfileTableGateway? gateway,
    CurrentUserProfileUserId? currentUserId,
  })  : _gateway = gateway ?? SupabaseUserProfileTableGateway(client),
        _currentUserId = currentUserId ?? (() => client.auth.currentUser?.id);

  final UserProfileTableGateway _gateway;
  final CurrentUserProfileUserId _currentUserId;

  @override
  Future<UserProfileData?> read() async {
    final userId = _requireUserId();
    final row = await _gateway.readRow(userId);
    if (row == null) return null;

    try {
      return UserProfileData(
        name: _requireString(row, 'name'),
        gender: _parseGender(row['gender']),
        dateOfBirth: _parseDate(row['date_of_birth']),
        unitPreferences: _parseUnitPreferences(row['unit_preferences']),
        heightCm: _parseHeight(row['height_cm']),
        activityLevel: _parseActivityLevel(row['activity_level']),
        healthConditions: _parseHealthConditions(row['health_conditions']),
        otherHealthCondition: _parseOptionalString(
          row['other_health_condition'],
          'other_health_condition',
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(
        'Invalid canonical user_profiles row: ${error.message}',
      );
    }
  }

  @override
  Future<void> upsert(UserProfileData profile) async {
    final userId = _requireUserId();
    await _gateway.upsertRow({
      'user_id': userId,
      'name': profile.name,
      'gender': profile.gender.name,
      'date_of_birth': _dateOnly(profile.dateOfBirth),
      'height_cm': profile.heightCm,
      'activity_level': _activityStorage(profile.activityLevel),
      'health_conditions': [
        for (final condition in ProfileHealthCondition.values)
          if (profile.healthConditions.contains(condition))
            _healthConditionStorage(condition),
      ],
      'other_health_condition': profile.otherHealthCondition,
      'unit_preferences': profile.unitPreferences.toJson(),
    });
  }

  String _requireUserId() {
    final userId = _currentUserId()?.trim();
    if (userId == null || userId.isEmpty) {
      throw StateError('Please sign in to access your Profile.');
    }
    return userId;
  }
}

String _requireString(Map<String, dynamic> row, String key) {
  final raw = row[key];
  if (raw is! String || raw.trim().isEmpty) {
    throw FormatException('Invalid canonical $key: expected non-empty string.');
  }
  return raw;
}

String? _parseOptionalString(Object? raw, String key) {
  if (raw == null) return null;
  if (raw is! String) {
    throw FormatException('Invalid canonical $key: expected string or null.');
  }
  final normalized = raw.trim();
  return normalized.isEmpty ? null : normalized;
}

ProfileGender _parseGender(Object? raw) {
  if (raw is! String) {
    throw const FormatException('Invalid canonical gender: expected string.');
  }
  return switch (raw) {
    'male' => ProfileGender.male,
    'female' => ProfileGender.female,
    'other' => ProfileGender.other,
    _ => throw FormatException('Invalid canonical gender: $raw.'),
  };
}

DateTime _parseDate(Object? raw) {
  if (raw is! String) {
    throw const FormatException(
      'Invalid canonical date_of_birth: expected date string.',
    );
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw FormatException('Invalid canonical date_of_birth: $raw.');
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

double _parseHeight(Object? raw) {
  if (raw is! num) {
    throw const FormatException('Invalid canonical height_cm: expected number.');
  }
  final value = raw.toDouble();
  if (!value.isFinite || value <= 0) {
    throw FormatException('Invalid canonical height_cm: $raw.');
  }
  return value;
}

ProfileActivityLevel _parseActivityLevel(Object? raw) {
  if (raw is! String) {
    throw const FormatException(
      'Invalid canonical activity_level: expected string.',
    );
  }
  return switch (raw) {
    'sedentary' => ProfileActivityLevel.sedentary,
    'light' => ProfileActivityLevel.light,
    'active' => ProfileActivityLevel.active,
    'very_active' => ProfileActivityLevel.veryActive,
    'dynamic' => ProfileActivityLevel.dynamic,
    _ => throw FormatException('Invalid canonical activity_level: $raw.'),
  };
}

Set<ProfileHealthCondition> _parseHealthConditions(Object? raw) {
  if (raw is! List) {
    throw const FormatException(
      'Invalid canonical health_conditions: expected list.',
    );
  }

  final result = <ProfileHealthCondition>{};
  for (final value in raw) {
    if (value is! String) {
      throw const FormatException(
        'Invalid canonical health_conditions: every item must be a string.',
      );
    }
    final condition = switch (value) {
      'none' => ProfileHealthCondition.none,
      'diabetes' => ProfileHealthCondition.diabetes,
      'hypertension' => ProfileHealthCondition.hypertension,
      'low_blood_pressure' => ProfileHealthCondition.lowBloodPressure,
      'other' => ProfileHealthCondition.other,
      _ => throw FormatException(
          'Invalid canonical health_conditions value: $value.',
        ),
    };
    if (!result.add(condition)) {
      throw FormatException(
        'Invalid canonical health_conditions duplicate: $value.',
      );
    }
  }
  if (result.contains(ProfileHealthCondition.none) && result.length > 1) {
    throw const FormatException(
      'Invalid canonical health_conditions: none cannot be combined.',
    );
  }
  return result;
}

UnitPreferences _parseUnitPreferences(Object? raw) {
  if (raw is! Map) {
    throw const FormatException(
      'Invalid canonical unit_preferences: expected object.',
    );
  }

  String requireUnit(String key) {
    final value = raw[key];
    if (value is! String) {
      throw FormatException(
        'Invalid canonical unit_preferences.$key: expected string.',
      );
    }
    return value;
  }

  final weight = requireUnit('weight');
  final height = requireUnit('height');
  final distance = requireUnit('distance');
  final volume = requireUnit('volume');

  return UnitPreferences(
    weightUnit: switch (weight) {
      'kg' => WeightUnit.kg,
      'lb' => WeightUnit.lb,
      _ => throw FormatException(
          'Invalid canonical unit_preferences.weight: $weight.',
        ),
    },
    heightUnit: switch (height) {
      'cm' => HeightUnit.cm,
      'ft_in' => HeightUnit.ftIn,
      _ => throw FormatException(
          'Invalid canonical unit_preferences.height: $height.',
        ),
    },
    distanceUnit: switch (distance) {
      'km' => DistanceUnit.km,
      'mi' => DistanceUnit.mi,
      _ => throw FormatException(
          'Invalid canonical unit_preferences.distance: $distance.',
        ),
    },
    volumeUnit: switch (volume) {
      'ml' => VolumeUnit.ml,
      'fl_oz' => VolumeUnit.flOz,
      _ => throw FormatException(
          'Invalid canonical unit_preferences.volume: $volume.',
        ),
    },
  );
}

String _activityStorage(ProfileActivityLevel level) => switch (level) {
      ProfileActivityLevel.sedentary => 'sedentary',
      ProfileActivityLevel.light => 'light',
      ProfileActivityLevel.active => 'active',
      ProfileActivityLevel.veryActive => 'very_active',
      ProfileActivityLevel.dynamic => 'dynamic',
    };

String _healthConditionStorage(ProfileHealthCondition condition) =>
    switch (condition) {
      ProfileHealthCondition.none => 'none',
      ProfileHealthCondition.diabetes => 'diabetes',
      ProfileHealthCondition.hypertension => 'hypertension',
      ProfileHealthCondition.lowBloodPressure => 'low_blood_pressure',
      ProfileHealthCondition.other => 'other',
    };

String _dateOnly(DateTime value) {
  String two(int component) => component.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-${two(value.month)}-${two(value.day)}';
}
