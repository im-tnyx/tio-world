import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  group('canonical Workout Profile contract', () {
    test('in-memory owner preserves unknown and explicit empty context', () async {
      final repository = InMemoryWorkoutProfileRepository();

      await repository.upsert(const WorkoutProfileData());
      final unknown = await repository.read();
      expect(unknown?.workoutLocation, isNull);
      expect(unknown?.availableEquipment, isNull);
      expect(unknown?.experienceLevel, isNull);
      expect(unknown?.focusAreas, isNull);
      expect(unknown?.healthConcerns, isNull);

      await repository.upsert(
        const WorkoutProfileData(
          workoutLocation: WorkoutGymAccess.home,
          availableEquipment: {},
          experienceLevel: WorkoutExperienceLevel.beginner,
          focusAreas: {},
          healthConcerns: {},
        ),
      );
      final explicit = await repository.read();
      expect(explicit?.workoutLocation, WorkoutGymAccess.home);
      expect(explicit?.availableEquipment, isEmpty);
      expect(explicit?.experienceLevel, WorkoutExperienceLevel.beginner);
      expect(explicit?.focusAreas, isEmpty);
      expect(explicit?.healthConcerns, isEmpty);
    });
  });

  group('canonical Workout Targets contract', () {
    test('Workout target goal storage mapping is strict and lossless', () {
      const expected = <WorkoutTargetGoal, String>{
        WorkoutTargetGoal.buildMuscle: 'build_muscle',
        WorkoutTargetGoal.getStronger: 'get_stronger',
        WorkoutTargetGoal.improveEndurance: 'improve_endurance',
        WorkoutTargetGoal.stayFit: 'stay_fit',
      };

      for (final entry in expected.entries) {
        expect(entry.key.storageValue, entry.value);
        expect(parseWorkoutTargetGoal(entry.value), entry.key);
      }

      expect(() => parseWorkoutTargetGoal('lose_weight'), throwsFormatException);
      expect(() => parseWorkoutTargetGoal(null), throwsFormatException);
    });

    test('validation mirrors live goal, rank and duration constraints', () {
      final invalid = <WorkoutTargetsData>[
        const WorkoutTargetsData(primaryGoalRank: 1),
        const WorkoutTargetsData(supportingGoalRank: 2),
        const WorkoutTargetsData(
          supportingWorkoutGoal: WorkoutTargetGoal.stayFit,
        ),
        const WorkoutTargetsData(
          primaryWorkoutGoal: WorkoutTargetGoal.getStronger,
          supportingWorkoutGoal: WorkoutTargetGoal.getStronger,
        ),
        const WorkoutTargetsData(
          primaryWorkoutGoal: WorkoutTargetGoal.getStronger,
          primaryGoalRank: 1,
          supportingWorkoutGoal: WorkoutTargetGoal.stayFit,
          supportingGoalRank: 1,
        ),
        const WorkoutTargetsData(
          primaryWorkoutGoal: WorkoutTargetGoal.getStronger,
          primaryGoalRank: 3,
        ),
        const WorkoutTargetsData(preferredDurationMins: 0),
      ];

      for (final value in invalid) {
        expect(value.validate, throwsArgumentError);
      }
    });

    test('in-memory owner preserves a complete canonical target', () async {
      final repository = InMemoryWorkoutTargetsRepository();
      final eventDate = DateTime.utc(2027, 3, 14);
      final targets = WorkoutTargetsData(
        primaryWorkoutGoal: WorkoutTargetGoal.buildMuscle,
        primaryGoalRank: 1,
        supportingWorkoutGoal: WorkoutTargetGoal.getStronger,
        supportingGoalRank: 2,
        trainingDays: const {
          WorkoutTrainingDay.monday,
          WorkoutTrainingDay.thursday,
        },
        preferredDurationMins: 60,
        splitProgram: WorkoutSplit.upperLower,
        specialEvent: 'Strength meet',
        specialEventDate: eventDate,
      );

      await repository.upsert(targets);
      final stored = await repository.read();

      expect(stored?.primaryWorkoutGoal, WorkoutTargetGoal.buildMuscle);
      expect(stored?.primaryGoalRank, 1);
      expect(stored?.supportingWorkoutGoal, WorkoutTargetGoal.getStronger);
      expect(stored?.supportingGoalRank, 2);
      expect(stored?.trainingDays, {
        WorkoutTrainingDay.monday,
        WorkoutTrainingDay.thursday,
      });
      expect(stored?.preferredDurationMins, 60);
      expect(stored?.splitProgram, WorkoutSplit.upperLower);
      expect(stored?.specialEvent, 'Strength meet');
      expect(stored?.specialEventDate, eventDate);
    });
  });
}
