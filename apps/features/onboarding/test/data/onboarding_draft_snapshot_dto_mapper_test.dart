import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('OnboardingDraftSnapshotDtoMapper', () {
    const mapper = OnboardingDraftSnapshotDtoMapper();

    test('serializes and deserializes canonical draft losslessly', () {
      final draft = OnboardingDraft(
        status: OnboardingStatus.inProgress,
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        currentStepId: OnboardingStepId.profileBasics,
        completedStepIds: {OnboardingStepId.mode},
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.measurementUnits,
          name: 'Sarah Connor',
          gender: ProfileGender.female,
          goals: {ProfileGoal.buildMuscle, ProfileGoal.loseWeight},
          dateOfBirth: DateTime.utc(1995, 5, 20),
          heightCm: 168.5,
          unitPreferences: const MeasurementUnitPreferences(
            weightUnit: WeightUnit.kg,
            heightUnit: HeightUnit.ftIn,
            distanceUnit: DistanceUnit.mi,
            volumeUnit: VolumeUnit.flOz,
          ),
          currentWeightKg: 64.2,
          targetWeightKg: 58.0,
          activityLevel: ProfileActivityLevel.active,
          healthConditions: {ProfileHealthCondition.lowBloodPressure},
          otherHealthCondition: 'Asthma',
          mobile: '+1234567890',
          isMobileVerified: true,
        ),
        workout: const WorkoutOnboardingDraft(
          currentStepId: WorkoutStepId.equipment,
          gymAccess: WorkoutGymAccess.home,
          equipment: {WorkoutEquipment.dumbbells, WorkoutEquipment.bands},
          experienceLevel: WorkoutExperienceLevel.intermediate,
          focusAreas: {WorkoutFocusArea.fullBody, WorkoutFocusArea.abs},
          trainingDays: {
            WorkoutTrainingDay.monday,
            WorkoutTrainingDay.wednesday,
          },
          workoutDuration: WorkoutDuration.sixtyMinutes,
          workoutSplit: WorkoutSplit.fullBody,
          healthConcerns: 'Knee injury',
          specialEvent: 'Marathon next year',
        ),
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.waterTarget,
          dailySteps: 12000,
          sleepTargetMinutes: 450,
          sleepTimeMinutes: 1380,
          wakeTimeMinutes: 450,
          waterMl: 3200,
          goalPaceKgPerWeek: 0.75,
        ),
      );

      final snapshot = OnboardingDraftSnapshot(
        draft: draft,
        updatedAt: DateTime.utc(2026, 8, 14, 12),
      );

      final json = mapper.toJson(snapshot);

      expect(json['schema_version'], OnboardingDraftSnapshot.currentSchemaVersion);
      expect(json['status'], 'inProgress');
      expect(json['selected_mode'], 'hybrid');
      expect(json['workout_intro_choice'], 'setupNow');
      expect(json['current_step_id'], 'profileBasics');
      final profileJson = json['profile'] as Map<String, dynamic>;
      expect(profileJson['weight_unit'], 'kg');
      expect(profileJson['height_unit'], 'ft_in');
      expect(profileJson['distance_unit'], 'mi');
      expect(profileJson['volume_unit'], 'fl_oz');

      final deserialized = mapper.fromJson(json);

      expect(
        deserialized.schemaVersion,
        equals(OnboardingDraftSnapshot.currentSchemaVersion),
      );
      expect(deserialized.draft.selectedMode, equals(AppMode.hybrid));
      expect(
        deserialized.draft.workoutIntroChoice,
        equals(WorkoutIntroChoice.setupNow),
      );
      expect(
        deserialized.draft.currentStepId,
        equals(OnboardingStepId.profileBasics),
      );
      expect(
        deserialized.draft.completedStepIds,
        contains(OnboardingStepId.mode),
      );

      expect(deserialized.draft.profile.name, equals('Sarah Connor'));
      expect(deserialized.draft.profile.gender, equals(ProfileGender.female));
      expect(
        deserialized.draft.profile.goals,
        contains(ProfileGoal.buildMuscle),
      );
      expect(deserialized.draft.profile.heightCm, equals(168.5));
      expect(deserialized.draft.profile.currentWeightKg, equals(64.2));
      expect(deserialized.draft.profile.targetWeightKg, equals(58.0));
      expect(
        deserialized.draft.profile.unitPreferences,
        const MeasurementUnitPreferences(
          weightUnit: WeightUnit.kg,
          heightUnit: HeightUnit.ftIn,
          distanceUnit: DistanceUnit.mi,
          volumeUnit: VolumeUnit.flOz,
        ),
      );
      expect(deserialized.draft.profile.otherHealthCondition, equals('Asthma'));
      expect(deserialized.draft.profile.mobile, equals('+1234567890'));
      expect(deserialized.draft.profile.isMobileVerified, isTrue);

      expect(
        deserialized.draft.workout.gymAccess,
        equals(WorkoutGymAccess.home),
      );
      expect(
        deserialized.draft.workout.equipment,
        contains(WorkoutEquipment.dumbbells),
      );
      expect(
        deserialized.draft.workout.experienceLevel,
        equals(WorkoutExperienceLevel.intermediate),
      );
      expect(
        deserialized.draft.workout.trainingDays,
        contains(WorkoutTrainingDay.monday),
      );
      expect(deserialized.draft.workout.healthConcerns, equals('Knee injury'));

      expect(deserialized.draft.targets.dailySteps, equals(12000));
      expect(deserialized.draft.targets.sleepTargetMinutes, equals(450));
      expect(deserialized.draft.targets.sleepTimeMinutes, equals(1380));
      expect(deserialized.draft.targets.wakeTimeMinutes, equals(450));
      expect(deserialized.draft.targets.waterMl, equals(3200));
      expect(deserialized.draft.targets.goalPaceKgPerWeek, equals(0.75));
    });

    test('legacy schema v1 draft defaults missing units to metric', () {
      final legacy = <String, dynamic>{
        'schema_version': 1,
        'status': 'inProgress',
        'current_step_id': 'profileBasics',
        'profile': <String, dynamic>{
          'current_step_id': 'height',
          'height_cm': 170.0,
          'current_weight_kg': 70.0,
        },
      };

      final snapshot = mapper.fromJson(legacy);

      expect(snapshot.schemaVersion, 1);
      expect(
        snapshot.draft.profile.unitPreferences,
        MeasurementUnitPreferences.metric,
      );
    });

    test('legacy aliases normalize to typed storage values', () {
      final legacy = <String, dynamic>{
        'schema_version': 1,
        'profile': <String, dynamic>{
          'weight_unit': 'lbs',
          'height_unit': 'ft',
        },
      };

      final snapshot = mapper.fromJson(legacy);

      expect(snapshot.draft.profile.unitPreferences.weightUnit, WeightUnit.lb);
      expect(
        snapshot.draft.profile.unitPreferences.heightUnit,
        HeightUnit.ftIn,
      );
    });

    test('throws UnsupportedError for unknown future schema version', () {
      final futureJson = {
        'schema_version': 99,
        'selected_mode': 'workout',
      };

      expect(
        () => mapper.fromJson(futureJson),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
