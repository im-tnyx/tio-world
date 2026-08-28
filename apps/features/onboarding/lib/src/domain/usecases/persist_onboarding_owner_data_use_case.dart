import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;

import '../models/models.dart';
import 'body_setup_mapper.dart';
import 'nutrition_profile_mapper.dart';
import 'nutrition_targets_mapper.dart';
import 'user_profile_mapper.dart';
import 'wellness_targets_mapper.dart';
import 'workout_profile_mapper.dart';
import 'workout_targets_mapper.dart';

/// Completion coordinator that maps onboarding answers into durable canonical
/// owner repositories. Onboarding remains orchestration-only; each feature owns
/// its persisted data contract.
class PersistOnboardingOwnerDataUseCase {
  const PersistOnboardingOwnerDataUseCase({
    required Object profileRepository,
    required body_owner.BodySetupRepository bodyRepository,
    body_owner.WellnessTargetsRepository? wellnessRepository,
    required nutrition_owner.NutritionProfileRepository
        nutritionProfileRepository,
    required workout_owner.WorkoutProfileRepository workoutProfileRepository,
    required workout_owner.WorkoutTargetsRepository workoutTargetsRepository,
    required nutrition_owner.NutritionTargetsRepository
        nutritionTargetsRepository,
    this.profileMapper = const UserProfileMapper(),
    this.bodyMapper = const BodySetupMapper(),
    this.wellnessMapper = const WellnessTargetsMapper(),
    this.nutritionProfileMapper = const NutritionProfileMapper(),
    this.workoutProfileMapper = const WorkoutProfileMapper(),
    this.workoutTargetsMapper = const WorkoutTargetsMapper(),
    this.nutritionTargetsMapper = const NutritionTargetsMapper(),
  })  : _profileRepository = profileRepository,
        _bodyRepository = bodyRepository,
        _wellnessRepository = wellnessRepository ??
            (bodyRepository is body_owner.WellnessTargetsRepository
                ? bodyRepository as body_owner.WellnessTargetsRepository
                : null),
        _nutritionProfileRepository = nutritionProfileRepository,
        _workoutProfileRepository = workoutProfileRepository,
        _workoutTargetsRepository = workoutTargetsRepository,
        _nutritionTargetsRepository = nutritionTargetsRepository;

  /// Kept as [Object] only so legacy composition/tests can fail closed at the
  /// owner boundary instead of forcing an unsafe broad-interface cast.
  /// Production composition must provide an object that implements
  /// [profile_owner.UserProfileRepository].
  final Object _profileRepository;
  final body_owner.BodySetupRepository _bodyRepository;
  final body_owner.WellnessTargetsRepository? _wellnessRepository;
  final nutrition_owner.NutritionProfileRepository _nutritionProfileRepository;
  final workout_owner.WorkoutProfileRepository _workoutProfileRepository;
  final workout_owner.WorkoutTargetsRepository _workoutTargetsRepository;
  final nutrition_owner.NutritionTargetsRepository _nutritionTargetsRepository;

  final UserProfileMapper profileMapper;
  final BodySetupMapper bodyMapper;
  final WellnessTargetsMapper wellnessMapper;
  final NutritionProfileMapper nutritionProfileMapper;
  final WorkoutProfileMapper workoutProfileMapper;
  final WorkoutTargetsMapper workoutTargetsMapper;
  final NutritionTargetsMapper nutritionTargetsMapper;

  Future<void> call({
    required OnboardingDraft draft,
    required OnboardingFlowPlan flowPlan,
  }) async {
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

    final requiresWellness =
        flowPlan.stepIds.contains(OnboardingStepId.wellnessGoals);
    if (requiresWellness) {
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
    }

    final requiresNutritionProfile =
        flowPlan.stepIds.contains(OnboardingStepId.nutritionProfile);
    if (requiresNutritionProfile) {
      final nutrition_owner.NutritionProfileData nutritionProfileData;
      try {
        nutritionProfileData = nutritionProfileMapper.map(draft.nutrition);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.nutritionProfile,
          message: 'Failed to map canonical Nutrition Profile data: $e',
          cause: e,
          stackTrace: st,
        );
      }

      try {
        await _nutritionProfileRepository.upsert(nutritionProfileData);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.nutritionProfile,
          message: 'Failed to persist canonical Nutrition Profile data: $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    final requiresWorkoutProfile =
        flowPlan.stepIds.contains(OnboardingStepId.workoutProfile);
    if (requiresWorkoutProfile) {
      final workout_owner.WorkoutProfileData workoutProfileData;
      try {
        workoutProfileData = workoutProfileMapper.map(draft.workout);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.workoutProfile,
          message: 'Failed to map canonical Workout Profile data: $e',
          cause: e,
          stackTrace: st,
        );
      }

      try {
        await _workoutProfileRepository.upsert(workoutProfileData);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.workoutProfile,
          message: 'Failed to persist canonical Workout Profile data: $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    final requiresWorkoutTargets =
        flowPlan.stepIds.contains(OnboardingStepId.workoutTargets);
    if (requiresWorkoutTargets) {
      final workout_owner.WorkoutTargetsData workoutTargetsData;
      try {
        workoutTargetsData = workoutTargetsMapper.map(draft);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.workoutTargets,
          message: 'Failed to map canonical Workout Targets data: $e',
          cause: e,
          stackTrace: st,
        );
      }

      try {
        await _workoutTargetsRepository.upsert(workoutTargetsData);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.workoutTargets,
          message: 'Failed to persist canonical Workout Targets data: $e',
          cause: e,
          stackTrace: st,
        );
      }
    }

    final requiresNutritionTargets =
        flowPlan.stepIds.contains(OnboardingStepId.nutritionGoals);
    if (requiresNutritionTargets) {
      final nutrition_owner.NutritionTargetsData nutritionTargetsData;
      try {
        nutritionTargetsData = nutritionTargetsMapper.map(draft);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.nutritionTargets,
          message: 'Failed to map canonical Nutrition Targets data: $e',
          cause: e,
          stackTrace: st,
        );
      }

      try {
        await _nutritionTargetsRepository.upsert(nutritionTargetsData);
      } catch (e, st) {
        throw OwnerPersistenceException(
          owner: OwnerPersistenceTarget.nutritionTargets,
          message: 'Failed to persist canonical Nutrition Targets data: $e',
          cause: e,
          stackTrace: st,
        );
      }
    }
  }
}

enum OwnerPersistenceTarget {
  profile,
  body,
  wellness,
  nutritionProfile,
  workoutProfile,
  workoutTargets,
  nutritionTargets,

  /// Retained only as a compatibility enum value for older serialized/test
  /// references. O6D no longer emits this owner from Product Onboarding.
  workout,

  /// Retained only as a compatibility enum value for older serialized/test
  /// references. O5D no longer emits this owner from Product Onboarding.
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
