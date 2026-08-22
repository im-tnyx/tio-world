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
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.getStronger,
        ),
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
          targetWeightDirection: GoalWeightDirection.loss,
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
      expect(
        json['goal_selection'],
        {
          'primary_goal': 'loseWeight',
          'supporting_goal': 'getStronger',
        },
      );
      final profileJson = json['profile'] as Map<String, dynamic>;
      expect(profileJson['weight_unit'], 'kg');
      expect(profileJson['height_unit'], 'ft_in');
      expect(profileJson['distance_unit'], 'mi');
      expect(profileJson['volume_unit'], 'fl_oz');
      expect(profileJson['target_weight_direction'], 'loss');
      final targetsJson = json['targets'] as Map<String, dynamic>;
      expect(targetsJson['daily_steps_known'], isTrue);
      expect(targetsJson['sleep_target_minutes_known'], isTrue);
      expect(targetsJson['sleep_time_minutes_known'], isTrue);
      expect(targetsJson['wake_time_minutes_known'], isTrue);
      expect(targetsJson['water_ml_known'], isTrue);

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
        deserialized.draft.goalSelection,
        const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.getStronger,
        ),
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
        deserialized.draft.profile.targetWeightDirection,
        GoalWeightDirection.loss,
      );
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
      expect(deserialized.draft.targets.hasDailyStepsValue, isTrue);
      expect(deserialized.draft.targets.hasSleepTargetMinutesValue, isTrue);
      expect(deserialized.draft.targets.hasSleepTimeMinutesValue, isTrue);
      expect(deserialized.draft.targets.hasWakeTimeMinutesValue, isTrue);
      expect(deserialized.draft.targets.hasWaterMlValue, isTrue);
    });

    test('schema v3 target restores without inventing direction in DTO layer', () {
      final legacy = <String, dynamic>{
        'schema_version': 3,
        'selected_mode': 'nutrition',
        'goal_selection': <String, dynamic>{
          'primary_goal': 'loseWeight',
          'supporting_goal': null,
        },
        'profile': <String, dynamic>{
          'current_step_id': 'targetWeight',
          'current_weight_kg': 70.0,
          'target_weight_kg': 64.0,
        },
      };

      final snapshot = mapper.fromJson(legacy);

      expect(snapshot.schemaVersion, 3);
      expect(snapshot.draft.profile.targetWeightKg, 64.0);
      expect(snapshot.draft.profile.targetWeightDirection, isNull);
    });

    test('legacy schema v1 draft defaults missing units and goal selection', () {
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
      expect(snapshot.draft.goalSelection, const GoalIntentSelection());
      expect(snapshot.draft.targets.dailySteps, 10000);
      expect(snapshot.draft.targets.waterMl, 2500);
      expect(snapshot.draft.targets.hasDailyStepsValue, isFalse);
      expect(snapshot.draft.targets.hasSleepTargetMinutesValue, isFalse);
      expect(snapshot.draft.targets.hasSleepTimeMinutesValue, isFalse);
      expect(snapshot.draft.targets.hasWakeTimeMinutesValue, isFalse);
      expect(snapshot.draft.targets.hasWaterMlValue, isFalse);
    });

    test('missing Wellness fields keep UI defaults but remain unknown on autosave',
        () {
      final legacy = <String, dynamic>{
        'schema_version': 2,
        'selected_mode': 'nutrition',
        'current_step_id': 'review',
        'targets': <String, dynamic>{
          'current_step_id': 'nutritionTarget',
          'goal_pace_kg_per_week': 0.5,
        },
      };

      final restored = mapper.fromJson(legacy);
      final targets = restored.draft.targets;

      expect(targets.dailySteps, 10000);
      expect(targets.sleepTargetMinutes, 480);
      expect(targets.sleepTimeMinutes, 1320);
      expect(targets.wakeTimeMinutes, 360);
      expect(targets.waterMl, 2500);
      expect(targets.hasDailyStepsValue, isFalse);
      expect(targets.hasSleepTargetMinutesValue, isFalse);
      expect(targets.hasSleepTimeMinutesValue, isFalse);
      expect(targets.hasWakeTimeMinutesValue, isFalse);
      expect(targets.hasWaterMlValue, isFalse);

      final autosaved = mapper.toJson(restored);
      final autosavedTargets = autosaved['targets'] as Map<String, dynamic>;
      expect(autosavedTargets['daily_steps'], 10000);
      expect(autosavedTargets['daily_steps_known'], isFalse);
      expect(autosavedTargets['sleep_target_minutes_known'], isFalse);
      expect(autosavedTargets['sleep_time_minutes_known'], isFalse);
      expect(autosavedTargets['wake_time_minutes_known'], isFalse);
      expect(autosavedTargets['water_ml_known'], isFalse);

      final reloaded = mapper.fromJson(autosaved).draft.targets;
      expect(reloaded.hasDailyStepsValue, isFalse);
      expect(reloaded.hasSleepTargetMinutesValue, isFalse);
      expect(reloaded.hasSleepTimeMinutesValue, isFalse);
      expect(reloaded.hasWakeTimeMinutesValue, isFalse);
      expect(reloaded.hasWaterMlValue, isFalse);
    });

    test('partial legacy Wellness fields preserve provenance independently', () {
      final legacy = <String, dynamic>{
        'schema_version': 2,
        'targets': <String, dynamic>{
          'daily_steps': 8700,
          'sleep_time_minutes': 1410,
          'goal_pace_kg_per_week': 0.4,
        },
      };

      final targets = mapper.fromJson(legacy).draft.targets;

      expect(targets.dailySteps, 8700);
      expect(targets.hasDailyStepsValue, isTrue);
      expect(targets.sleepTargetMinutes, 480);
      expect(targets.hasSleepTargetMinutesValue, isFalse);
      expect(targets.sleepTimeMinutes, 1410);
      expect(targets.hasSleepTimeMinutesValue, isTrue);
      expect(targets.wakeTimeMinutes, 360);
      expect(targets.hasWakeTimeMinutesValue, isFalse);
      expect(targets.waterMl, 2500);
      expect(targets.hasWaterMlValue, isFalse);
    });

    test('editing an unknown Wellness value marks only that value known', () {
      const legacyTargets = TargetsOnboardingDraft(
        hasDailyStepsValue: false,
        hasSleepTargetMinutesValue: false,
        hasSleepTimeMinutesValue: false,
        hasWakeTimeMinutesValue: false,
        hasWaterMlValue: false,
      );

      final edited = legacyTargets.copyWith(dailySteps: 9200, waterMl: 2800);

      expect(edited.hasDailyStepsValue, isTrue);
      expect(edited.hasWaterMlValue, isTrue);
      expect(edited.hasSleepTargetMinutesValue, isFalse);
      expect(edited.hasSleepTimeMinutesValue, isFalse);
      expect(edited.hasWakeTimeMinutesValue, isFalse);
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

    test('round-trips future top-level ids with current schema version', () {
      final snapshot = OnboardingDraftSnapshot(
        draft: OnboardingDraft(
          currentStepId: OnboardingStepId.bodyGoal,
          completedStepIds: const {
            OnboardingStepId.userProfile,
            OnboardingStepId.workoutIntro,
          },
        ),
        updatedAt: DateTime.utc(2026, 8, 20, 12),
      );

      final json = mapper.toJson(snapshot);

      expect(json['schema_version'], OnboardingDraftSnapshot.currentSchemaVersion);
      expect(json['current_step_id'], 'bodyGoal');
      expect(
        json['completed_step_ids'],
        containsAll(<String>['userProfile', 'workoutIntro']),
      );

      final restored = mapper.fromJson(json);

      expect(
        restored.schemaVersion,
        OnboardingDraftSnapshot.currentSchemaVersion,
      );
      expect(restored.draft.currentStepId, OnboardingStepId.bodyGoal);
      expect(
        restored.draft.completedStepIds,
        containsAll(<OnboardingStepId>[
          OnboardingStepId.userProfile,
          OnboardingStepId.workoutIntro,
        ]),
      );
    });

    test('ignores unknown completed ids and falls back for unknown current id', () {
      final json = <String, dynamic>{
        'schema_version': 2,
        'current_step_id': 'unknownFutureStep',
        'completed_step_ids': <String>['profileBasics', 'unknownFutureStep'],
      };

      final restored = mapper.fromJson(json);

      expect(restored.draft.currentStepId, OnboardingStepId.mode);
      expect(
        restored.draft.completedStepIds,
        const {OnboardingStepId.profileBasics},
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
