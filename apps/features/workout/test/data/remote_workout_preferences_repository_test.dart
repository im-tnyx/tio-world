import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  group('WorkoutPreferencesDtoMapper', () {
    test('maps complete WorkoutPreferencesData to verified backend JSON schema', () {
      const data = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.home,
        equipment: {WorkoutEquipment.dumbbells, WorkoutEquipment.mat},
        experienceLevel: WorkoutExperienceLevel.intermediate,
        focusAreas: {WorkoutFocusArea.chest, WorkoutFocusArea.arms},
        trainingDays: {
          WorkoutTrainingDay.monday,
          WorkoutTrainingDay.wednesday,
          WorkoutTrainingDay.friday,
        },
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.ppl,
        healthConcerns: 'Lower back stiffness',
        specialEvent: 'Half Marathon',
      );

      const mapper = WorkoutPreferencesDtoMapper();
      final payload = mapper.toRequestPayload(data);

      expect(payload['gymAccess'], 'home');
      expect(payload['equipment'], containsAll(['dumbbells', 'mat']));
      expect(payload['experienceLevel'], 'intermediate');
      expect(payload['focusAreas'], containsAll(['chest', 'arms']));
      expect(payload['trainingDays'], containsAll(['monday', 'wednesday', 'friday']));
      expect(payload['workoutDuration'], '60_mins');
      expect(payload['workoutSplit'], 'ppl');
      expect(payload['healthConcerns'], 'Lower back stiffness');
      expect(payload['specialEvent'], 'Half Marathon');
    });

    test('omits optional fields when null or empty', () {
      const data = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.gym,
        equipment: {},
        experienceLevel: WorkoutExperienceLevel.fresh,
        focusAreas: {WorkoutFocusArea.fullBody},
        trainingDays: {WorkoutTrainingDay.tuesday},
        workoutDuration: WorkoutDuration.thirtyMinutes,
        workoutSplit: WorkoutSplit.auto,
      );

      const mapper = WorkoutPreferencesDtoMapper();
      final payload = mapper.toRequestPayload(data);

      expect(payload.containsKey('equipment'), isFalse);
      expect(payload.containsKey('healthConcerns'), isFalse);
      expect(payload.containsKey('specialEvent'), isFalse);
      expect(payload['workoutDuration'], '30_mins');
      expect(payload['workoutSplit'], 'auto');
    });
  });

  group('RemoteWorkoutPreferencesRepository', () {
    test('delegates mapped payload to remote data source on saveWorkoutPreferences', () async {
      final fakeDataSource = _FakeWorkoutPreferencesRemoteDataSource();
      final repository = RemoteWorkoutPreferencesRepository(
        remoteDataSource: fakeDataSource,
      );

      const data = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.gym,
        equipment: {WorkoutEquipment.barbell},
        experienceLevel: WorkoutExperienceLevel.advanced,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.saturday},
        workoutDuration: WorkoutDuration.ninetyMinutes,
        workoutSplit: WorkoutSplit.upperLower,
      );

      await repository.saveWorkoutPreferences(data);

      expect(fakeDataSource.lastSavedPayload, isNotNull);
      expect(fakeDataSource.lastSavedPayload?['gymAccess'], 'gym');
      expect(fakeDataSource.lastSavedPayload?['workoutDuration'], '90_mins');
      expect(fakeDataSource.lastSavedPayload?['workoutSplit'], 'upper_lower');
      expect(await repository.getWorkoutPreferences(), isNull);
    });
  });
}

class _FakeWorkoutPreferencesRemoteDataSource
    implements WorkoutPreferencesRemoteDataSource {
  Map<String, dynamic>? lastSavedPayload;

  @override
  Future<void> saveWorkoutPreferences(Map<String, dynamic> data) async {
    lastSavedPayload = data;
  }
}
