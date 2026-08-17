import 'dart:async';

import 'package:tio_core/core.dart';

import '../domain/models/profile_setup_data.dart';
import '../domain/repositories/measurement_unit_preferences_repository.dart';
import '../domain/repositories/profile_setup_repository.dart';

/// Thread-safe in-memory implementation of profile and unit-preference owners.
class InMemoryProfileSetupRepository
    implements ProfileSetupRepository, MeasurementUnitPreferencesRepository {
  InMemoryProfileSetupRepository({ProfileSetupData? initialData})
      : _data = initialData;

  ProfileSetupData? _data;
  final _controller = StreamController<ProfileSetupData?>.broadcast();

  @override
  Future<void> saveProfileSetup(ProfileSetupData data) async {
    _data = data;
    _controller.add(_data);
  }

  @override
  Future<void> updateMeasurementUnitPreferences(
    MeasurementUnitPreferences preferences,
  ) async {
    final current = _data;
    if (current == null) return;
    _data = _copyWith(
      current,
      unitPreferences: preferences,
    );
    _controller.add(_data);
  }

  @override
  Future<ProfileSetupData?> getProfileSetup() async {
    return _data;
  }

  @override
  Stream<ProfileSetupData?> watchProfileSetup() => _controller.stream;

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) async {
    final url = 'memory://$fileName';
    if (_data case final current?) {
      _data = _copyWith(current, avatarUrl: url);
      _controller.add(_data);
    }
    return url;
  }

  @override
  Future<void> deleteAvatarImage() async {
    if (_data case final current?) {
      _data = _copyWith(current, clearAvatarUrl: true);
      _controller.add(_data);
    }
  }

  @override
  Future<void> updateAvatarFrame(String frame) async {
    if (_data case final current?) {
      _data = _copyWith(current, avatarFrame: frame);
      _controller.add(_data);
    }
  }

  ProfileSetupData _copyWith(
    ProfileSetupData data, {
    String? avatarUrl,
    bool clearAvatarUrl = false,
    String? avatarFrame,
    MeasurementUnitPreferences? unitPreferences,
  }) {
    return ProfileSetupData(
      name: data.name,
      username: data.username,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? data.avatarUrl,
      avatarFrame: avatarFrame ?? data.avatarFrame,
      plan: data.plan,
      gender: data.gender,
      goals: data.goals,
      dateOfBirth: data.dateOfBirth,
      heightCm: data.heightCm,
      currentWeightKg: data.currentWeightKg,
      targetWeightKg: data.targetWeightKg,
      unitPreferences: unitPreferences ?? data.unitPreferences,
      activityLevel: data.activityLevel,
      healthConditions: data.healthConditions,
      otherHealthCondition: data.otherHealthCondition,
      mobile: data.mobile,
      isMobileVerified: data.isMobileVerified,
    );
  }
}
