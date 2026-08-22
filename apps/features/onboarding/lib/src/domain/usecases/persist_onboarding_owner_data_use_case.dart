import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;

import '../models/models.dart';
import 'body_setup_mapper.dart';
import 'targets_setup_mapper.dart';
import 'user_profile_mapper.dart';
import 'weight_goal_flow_policy.dart';
import 'wellness_targets_mapper.dart';
import 'workout_preferences_mapper.dart';

/// Completion coordinator that maps onboarding answers into durable owner
/// repositories. Onboarding remains orchestration-only; each feature owns its
/// persisted data contract.
class PersistOnboardingOwnerDataUseCase {
  const PersistOnboardingOwnerDataUseCase({
    required Object profileRepository,
    required body_owner.BodySetupRepository bodyRepository,
    body_owner.WellnessTargetsRepository? wellnessRepository,
    required workout_owner.WorkoutPreferencesRepository workoutRepository,
    required nutrition_owner.TargetsSetupRepository targetsRepository,
    this.profileMapper = const UserProfileMapper(),
    this.bodyMapper = const BodySetupMapper(),
    this.wellnessMapper = const WellnessTargetsMapper(),
    this.workoutMapper = const WorkoutPreferencesMapper(),
    this.targetsMapper = const TargetsSetupMapper(),
    this.weightGoalPolicy = const WeightGoalFlowPolicy(),
  })  : _profileRepository = profileRepository,
        _bodyRepository = bodyRepository,
        _wellnessRepository = wellnessRepository ??
            (bodyRepository is body_owner.WellnessTargetsRepository
                ? bodyRepository as body_owner.WellnessTargetsRepository
                : null),
        _workoutRepository = workoutRepository,
        _targetsRepository = targetsRepository;

  /// Kept as [Object] only so legacy composition/tests can fail closed at the
  /// owner boundary instead of forcing an unsafe broad-interface cast.
  /// Production O2C composition must provide an object that implements
  /// [profile_owner.UserProfileRepository].
  final Object _profileRepository;
  final body_owner.BodySetupRepository _bodyRepository;
  final body_owner.WellnessTargetsRepository? _wellnessRepository;
  final workout_owner.WorkoutPreferencesRepository _workoutRepository;
  final nutrition_owner.TargetsSetupRepository _targetsRepository;

  final UserProfileMapper profileMapper;
  final BodySetupMapper bodyMapper;
  final WellnessTargetsMapper wellnessMapper;
  final WorkoutPreferencesMapper workoutMapper;
  final TargetsSetupMapper targetsMapper;
  final WeightGoalFlowPolicy weightGoalPolicy;

  Future<void> call({
    required OnboardingDraft draft,
    required OnboardingFlowPlan flowPlan,
  }) async {
    final activeWeightDirection = weightGoalPolicy.directionFor(
      mode: draft.selectedMode,
      selection: draft.goalSelection,
    );

    final profile_owner.UserProfileData profileData;
    try {
      profileData = profileMapper.map(draft.profile);
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.profile,
        message: 'Failed to map canonical common Profile data: $e',
        cause: e,
        stackTrace: st,
      );
    }

    try {
      final profileRepository = _profileRepository;
      if (profileRepository is! profile_owner.UserProfileRepository) {
        throw StateError(
          'Product Onboarding requires the canonical UserProfileRepository.',
        );
      }
      await profileRepository.upsert(profileData);
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.profile,
        message: 'Failed to persist canonical common Profile data: $e',
        cause: e,
        stackTrace: st,
      );
    }

    final body_owner.BodySetupData bodyData;
    try {
      bodyData = bodyMapper.map(draft);
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.body,
        message: 'Failed to map Body setup data: $e',
        cause: e,
        stackTrace: st,
      );
    }

    try {
      await _bodyRepository.saveBodySetup(bodyData);
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.body,
        message: 'Failed to persist Body setup data: $e',
        cause: e,
        stackTrace: st,
      );
    }

    final body_owner.WellnessTargetsData wellnessData;
    try {
      wellnessData = wellnessMapper.map(draft.targets);
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.wellness,
        message: 'Failed to map canonical Wellness targets: $e',
        cause: e,
        stackTrace: st,
      );
    }

    try {
      final wellnessRepository = _wellnessRepository;
      if (wellnessRepository == null) {
        throw StateError(
          'Product Onboarding requires the canonical WellnessTargetsRepository.',
        );
      }
      await wellnessRepository.upsert(wellnessData);
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.wellness,
        message: 'Failed to persist canonical Wellness targets: $e',
        cause: e,
        stackTrace: st,
      );
    }

    final requiresWorkout =
        flowPlan.stepIds.contains(OnboardingStepId.workoutPreferences);
    if (requiresWorkout) {
      final workout_owner.WorkoutPreferencesData workoutData;
      try {
        workoutData = workoutMapper.map(draft.workout);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.workout,
          message: 'Failed to map workout preferences data: $e',
          cause: e,
          stackTrace: st,
        );
      }

      try {
        await _workoutRepository.saveWorkoutPreferences(workoutData);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.workout,
          message: 'Failed to persist workout preferences data: $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    final nutrition_owner.TargetsSetupData targetsData;
    try {
      targetsData = targetsMapper.map(
        targetsDraft: draft.targets,
        profileDraft: draft.profile,
        activeWeightDirection: activeWeightDirection,
      );
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.targets,
        message: 'Failed to map targets setup data: $e',
        cause: e,
        stackTrace: st,
      );
    }

    try {
      await _targetsRepository.saveTargetsSetup(targetsData);
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.targets,
        message: 'Failed to persist targets setup data: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }
}

enum OwnerPersistenceTarget {
  profile,
  body,
  wellness,
  workout,
  targets,
}

class OwnerPersistenceException implements Exception {
  const OwnerPersistenceException({
    required this.owner,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final OwnerPersistenceTarget owner;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'OwnerPersistenceException($owner): $message';
}
