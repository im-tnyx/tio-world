import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/src/domain/domain.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  group('O9C plan/recommendation publication semantics', () {
    for (final variant in _variants) {
      test(variant.name, () async {
        final profileRepo = _FakeUserProfileRepository();
        final bodyRepo = body_owner.InMemoryBodySetupRepository();
        final wellnessRepo = body_owner.InMemoryWellnessTargetsRepository();
        final nutritionProfileRepo =
            nutrition_owner.InMemoryNutritionProfileRepository();
        final nutritionTargetsRepo =
            nutrition_owner.InMemoryNutritionTargetsRepository();
        final workoutProfileRepo =
            workout_owner.InMemoryWorkoutProfileRepository();
        final workoutTargetsRepo =
            workout_owner.InMemoryWorkoutTargetsRepository();

        final useCase = PersistOnboardingOwnerDataUseCase(
          profileRepository: profileRepo,
          bodyRepository: bodyRepo,
          wellnessRepository: wellnessRepo,
          nutritionProfileRepository: nutritionProfileRepo,
          nutritionTargetsRepository: nutritionTargetsRepo,
          workoutProfileRepository: workoutProfileRepo,
          workoutTargetsRepository: workoutTargetsRepo,
        );

        final draft = OnboardingDraft(
          selectedMode: variant.mode,
          workoutIntroChoice: variant.workoutIntroChoice,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.stayFit,
            supportingGoal: GoalIntent.improveEndurance,
          ),
          profile: _validProfile(),
          nutrition: const NutritionOnboardingDraft(
            dietType: NutritionDietType.vegetarian,
            allergyRestrictions: {NutritionAllergyRestriction.none},
          ),
          workout: _validWorkout(),
          targets: _validTargets(),
        );
        final flowPlan = const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: variant.mode,
          workoutIntroChoice: variant.workoutIntroChoice,
        );

        await useCase(draft: draft, flowPlan: flowPlan);

        expect(profileRepo.data, isNotNull);
        expect(bodyRepo.data, isNotNull);
        expect(
          wellnessRepo.data,
          variant.publishesWellness ? isNotNull : isNull,
        );

        final nutritionTargets = await nutritionTargetsRepo.read();
        if (variant.publishesNutritionTargets) {
          expect(nutritionTargets, isNotNull);
          expect(
            nutritionTargets?.customizationState,
            nutrition_owner.NutritionTargetCustomizationState.recommended,
          );
          expect(nutritionTargets?.customizedFields, isEmpty);
          expect(
            nutritionTargets?.recommendationMetadata['source'],
            'onboarding',
          );
          expect(nutritionTargets?.caloriesKcal, greaterThan(0));
          expect(nutritionTargets?.proteinGrams, greaterThan(0));
          expect(nutritionTargets?.carbohydrateGrams, greaterThanOrEqualTo(0));
          expect(nutritionTargets?.fatGrams, greaterThan(0));
          expect(nutritionTargets?.fiberGrams, greaterThan(0));
        } else {
          expect(nutritionTargets, isNull);
        }

        expect(
          await nutritionProfileRepo.read(),
          variant.publishesNutritionProfile ? isNotNull : isNull,
        );

        final workoutProfile = await workoutProfileRepo.read();
        final workoutTargets = await workoutTargetsRepo.read();
        if (variant.publishesWorkout) {
          expect(workoutProfile, isNotNull);
          expect(workoutTargets, isNotNull);
          expect(
            workoutTargets?.primaryWorkoutGoal,
            workout_owner.WorkoutTargetGoal.stayFit,
          );
          expect(
            workoutTargets?.supportingWorkoutGoal,
            workout_owner.WorkoutTargetGoal.improveEndurance,
          );
          expect(workoutTargets?.primaryGoalRank, 1);
          expect(workoutTargets?.supportingGoalRank, 2);
          expect(workoutTargets?.trainingDays, hasLength(2));
          expect(workoutTargets?.preferredDurationMins, 60);
          expect(
            workoutTargets?.splitProgram,
            workout_owner.WorkoutSplit.upperLower,
          );
          expect(workoutTargets?.specialEvent, '10K race');
          expect(workoutTargets?.specialEventDate, isNull);
        } else {
          expect(workoutProfile, isNull);
          expect(workoutTargets, isNull);
        }

        if (variant.workoutIntroChoice == WorkoutIntroChoice.later) {
          expect(draft.workout.gymAccess, WorkoutGymAccess.gym);
          expect(draft.workout.specialEvent, '10K race');
        }
      });
    }
  });
}

class _Variant {
  const _Variant({
    required this.name,
    required this.mode,
    required this.publishesWellness,
    required this.publishesNutritionProfile,
    required this.publishesNutritionTargets,
    required this.publishesWorkout,
    this.workoutIntroChoice,
  });

  final String name;
  final AppMode mode;
  final WorkoutIntroChoice? workoutIntroChoice;
  final bool publishesWellness;
  final bool publishesNutritionProfile;
  final bool publishesNutritionTargets;
  final bool publishesWorkout;
}

const _variants = <_Variant>[
  _Variant(
    name: 'Workout publishes Body and Workout owners only',
    mode: AppMode.workout,
    publishesWellness: false,
    publishesNutritionProfile: false,
    publishesNutritionTargets: false,
    publishesWorkout: true,
  ),
  _Variant(
    name: 'Nutrition publishes Wellness and Nutrition owners only',
    mode: AppMode.nutrition,
    publishesWellness: true,
    publishesNutritionProfile: true,
    publishesNutritionTargets: true,
    publishesWorkout: false,
  ),
  _Variant(
    name: 'Hybrid setupNow publishes Wellness, Nutrition and Workout owners',
    mode: AppMode.hybrid,
    workoutIntroChoice: WorkoutIntroChoice.setupNow,
    publishesWellness: true,
    publishesNutritionProfile: true,
    publishesNutritionTargets: true,
    publishesWorkout: true,
  ),
  _Variant(
    name: 'Hybrid later publishes Wellness and Nutrition with Workout dormant',
    mode: AppMode.hybrid,
    workoutIntroChoice: WorkoutIntroChoice.later,
    publishesWellness: true,
    publishesNutritionProfile: true,
    publishesNutritionTargets: true,
    publishesWorkout: false,
  ),
];

class _FakeUserProfileRepository implements profile_owner.UserProfileRepository {
  profile_owner.UserProfileData? data;

  @override
  Future<profile_owner.UserProfileData?> read() async => data;

  @override
  Future<void> upsert(profile_owner.UserProfileData profile) async {
    data = profile;
  }
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    name: 'Tio User',
    gender: ProfileGender.female,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(1996, 6, 15),
    heightCm: 165,
    currentWeightKg: 60,
    targetWeightKg: 58,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

WorkoutOnboardingDraft _validWorkout() {
  return const WorkoutOnboardingDraft(
    gymAccess: WorkoutGymAccess.gym,
    equipment: {},
    experienceLevel: WorkoutExperienceLevel.intermediate,
    focusAreas: {WorkoutFocusArea.fullBody},
    trainingDays: {WorkoutTrainingDay.monday, WorkoutTrainingDay.thursday},
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.upperLower,
    specialEvent: '10K race',
  );
}

TargetsOnboardingDraft _validTargets() {
  return const TargetsOnboardingDraft(
    dailySteps: 10000,
    sleepTargetMinutes: 480,
    sleepTimeMinutes: 1320,
    wakeTimeMinutes: 360,
    waterMl: 2500,
    goalPaceKgPerWeek: 0.5,
  );
}
