import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;

import '../models/models.dart';
import 'profile_setup_mapper.dart';
import 'targets_setup_mapper.dart';
import 'workout_preferences_mapper.dart';

/// Dedicated completion coordinator that validates and persists active onboarding answers
/// atomically across canonical owner repositories (Profile, Workout, Targets).
class PersistOnboardingOwnerDataUseCase {
  const PersistOnboardingOwnerDataUseCase({
    required profile_owner.ProfileSetupRepository profileRepository,
    required workout_owner.WorkoutPreferencesRepository workoutRepository,
    required nutrition_owner.TargetsSetupRepository targetsRepository,
    this.profileMapper = const ProfileSetupMapper(),
    this.workoutMapper = const WorkoutPreferencesMapper(),
    this.targetsMapper = const TargetsSetupMapper(),
  })  : _profileRepository = profileRepository,
        _workoutRepository = workoutRepository,
        _targetsRepository = targetsRepository;

  final profile_owner.ProfileSetupRepository _profileRepository;
  final workout_owner.WorkoutPreferencesRepository _workoutRepository;
  final nutrition_owner.TargetsSetupRepository _targetsRepository;

  final ProfileSetupMapper profileMapper;
  final WorkoutPreferencesMapper workoutMapper;
  final TargetsSetupMapper targetsMapper;

  /// Persists owner data according to the active mode and flow plan.
  ///
  /// Invariant:
  /// - Profile data is always persisted.
  /// - Workout data is persisted ONLY IF [flowPlan] contains [OnboardingStepId.workoutPreferences].
  /// - Targets data is always persisted.
  ///
  /// Throws [OwnerPersistenceException] if mapping or writing to any owner fails.
  Future<void> call({
    required OnboardingDraft draft,
    required OnboardingFlowPlan flowPlan,
  }) async {
    // 1. Map and persist Profile owner data
    final profile_owner.ProfileSetupData profileData;
    try {
      profileData = profileMapper.map(draft.profile);
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.profile,
        message: 'Failed to map profile setup data: $e',
        cause: e,
        stackTrace: st,
      );
    }

    try {
      await _profileRepository.saveProfileSetup(profileData);
    } catch (e, st) {
      throw OwnerPersistenceException(
        owner: OwnerPersistenceTarget.profile,
        message: 'Failed to persist profile setup data.',
        cause: e,
        stackTrace: st,
      );
    }

    // 2. Map and persist Workout owner data (Mode-Aware: only if active in flowPlan)
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
          message: 'Failed to persist workout preferences data.',
          cause: e,
          stackTrace: st,
        );
      }
    }

    // 3. Map and persist Targets & Nutrition owner data
    final nutrition_owner.TargetsSetupData targetsData;
    try {
      targetsData = targetsMapper.map(
        targetsDraft: draft.targets,
        profileDraft: draft.profile,
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
        message: 'Failed to persist targets setup data.',
        cause: e,
        stackTrace: st,
      );
    }
  }
}

enum OwnerPersistenceTarget {
  profile,
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
