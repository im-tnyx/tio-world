import 'dart:async';

import '../domain/models/profile_setup_data.dart';
import '../domain/repositories/profile_setup_repository.dart';

/// Thread-safe in-memory implementation of [ProfileSetupRepository].
class InMemoryProfileSetupRepository implements ProfileSetupRepository {
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
    if (_data != null) {
      _data = ProfileSetupData(
        name: _data!.name,
        username: _data!.username,
        avatarUrl: url,
        avatarFrame: _data!.avatarFrame,
        plan: _data!.plan,
        gender: _data!.gender,
        goals: _data!.goals,
        dateOfBirth: _data!.dateOfBirth,
        heightCm: _data!.heightCm,
        currentWeightKg: _data!.currentWeightKg,
        targetWeightKg: _data!.targetWeightKg,
        activityLevel: _data!.activityLevel,
        healthConditions: _data!.healthConditions,
        otherHealthCondition: _data!.otherHealthCondition,
      );
      _controller.add(_data);
    }
    return url;
  }

  @override
  Future<void> deleteAvatarImage() async {
    if (_data != null) {
      _data = ProfileSetupData(
        name: _data!.name,
        username: _data!.username,
        avatarUrl: null,
        avatarFrame: _data!.avatarFrame,
        plan: _data!.plan,
        gender: _data!.gender,
        goals: _data!.goals,
        dateOfBirth: _data!.dateOfBirth,
        heightCm: _data!.heightCm,
        currentWeightKg: _data!.currentWeightKg,
        targetWeightKg: _data!.targetWeightKg,
        activityLevel: _data!.activityLevel,
        healthConditions: _data!.healthConditions,
        otherHealthCondition: _data!.otherHealthCondition,
      );
      _controller.add(_data);
    }
  }

  @override
  Future<void> updateAvatarFrame(String frame) async {
    if (_data != null) {
      _data = ProfileSetupData(
        name: _data!.name,
        username: _data!.username,
        avatarUrl: _data!.avatarUrl,
        avatarFrame: frame,
        plan: _data!.plan,
        gender: _data!.gender,
        goals: _data!.goals,
        dateOfBirth: _data!.dateOfBirth,
        heightCm: _data!.heightCm,
        currentWeightKg: _data!.currentWeightKg,
        targetWeightKg: _data!.targetWeightKg,
        activityLevel: _data!.activityLevel,
        healthConditions: _data!.healthConditions,
        otherHealthCondition: _data!.otherHealthCondition,
      );
      _controller.add(_data);
    }
  }
}
