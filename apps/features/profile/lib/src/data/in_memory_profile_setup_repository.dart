import 'dart:async';

import 'package:tio_core/core.dart';

import '../domain/models/profile_setup_data.dart';
import '../domain/models/user_profile_data.dart';
import '../domain/repositories/measurement_unit_preferences_repository.dart';
import '../domain/repositories/profile_setup_repository.dart';
import '../domain/repositories/user_profile_repository.dart';

/// Thread-safe in-memory implementation used by local/test compatibility
/// surfaces. Canonical common Profile state is tracked separately from the
/// legacy broad setup snapshot.
class InMemoryProfileSetupRepository implements
    ProfileSetupRepository,
    MeasurementUnitPreferencesRepository,
    UserProfileRepository {
  InMemoryProfileSetupRepository({ProfileSetupData? initialData})
      : _data = initialData,
        _canonicalData = initialData == null ? null : _canonicalFromLegacy(initialData);

  ProfileSetupData? _data;
  UserProfileData? _canonicalData;
  final _controller = StreamController<ProfileSetupData?>.broadcast();

  @override
  Future<void> saveProfileSetup(ProfileSetupData data) async {
    _data = data;
    _canonicalData = _canonicalFromLegacy(data);
    _controller.add(_data);
  }

  @override
  Future<UserProfileData?> read() async => _canonicalData;

  @override
  Future<void> upsert(UserProfileData profile) async {
    _canonicalData = profile;

    // Compatibility projection for legacy tests/local readers only. Product
    // Onboarding's canonical write boundary is [UserProfileRepository]; Body
    // values are not persisted through this projection.
    final current = _data;
    _data = ProfileSetupData(
      name: profile.name,
      username: current?.username,
      avatarUrl: current?.avatarUrl,
      avatarFrame: current?.avatarFrame ?? 'none',
      plan: current?.plan ?? 'free',
      gender: profile.gender,
      goals: current?.goals ?? const {},
      dateOfBirth: profile.dateOfBirth,
      heightCm: profile.heightCm,
      currentWeightKg: current?.currentWeightKg ?? 0,
      targetWeightKg: current?.targetWeightKg,
      unitPreferences: profile.unitPreferences,
      activityLevel: profile.activityLevel,
      healthConditions: profile.healthConditions,
      otherHealthCondition: profile.otherHealthCondition,
      mobile: current?.mobile,
      isMobileVerified: current?.isMobileVerified ?? false,
    );
    _controller.add(_data);
  }

  @override
  Future<void> updateMeasurementUnitPreferences(
    MeasurementUnitPreferences preferences,
  ) async {
    final canonical = _canonicalData;
    if (canonical != null) {
      _canonicalData = UserProfileData(
        name: canonical.name,
        gender: canonical.gender,
        dateOfBirth: canonical.dateOfBirth,
        unitPreferences: preferences,
        heightCm: canonical.heightCm,
        activityLevel: canonical.activityLevel,
        healthConditions: canonical.healthConditions,
        otherHealthCondition: canonical.otherHealthCondition,
      );
    }

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

UserProfileData _canonicalFromLegacy(ProfileSetupData data) {
  return UserProfileData(
    name: data.name,
    gender: data.gender,
    dateOfBirth: data.dateOfBirth,
    unitPreferences: data.unitPreferences,
    heightCm: data.heightCm,
    activityLevel: data.activityLevel,
    healthConditions: data.healthConditions,
    otherHealthCondition: data.otherHealthCondition,
  );
}
