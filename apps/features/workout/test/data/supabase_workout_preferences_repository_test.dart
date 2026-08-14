import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  group('SupabaseWorkoutPreferencesRepository', () {
    test('instantiates with client', () {
      expect(
        () => SupabaseWorkoutPreferencesRepository(
          client: FakeSupabaseClient(),
        ),
        returnsNormally,
      );
    });

    test('saveWorkoutPreferences throws StateError when user is unauthenticated', () async {
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      const data = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.gym,
        equipment: {WorkoutEquipment.dumbbells, WorkoutEquipment.bench},
        experienceLevel: WorkoutExperienceLevel.intermediate,
        focusAreas: {WorkoutFocusArea.chest, WorkoutFocusArea.arms},
        trainingDays: {WorkoutTrainingDay.monday, WorkoutTrainingDay.friday},
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.upperLower,
      );

      expect(
        () => repository.saveWorkoutPreferences(data),
        throwsStateError,
      );
    });

    test('getWorkoutPreferences returns null when user is unauthenticated', () async {
      final repository = SupabaseWorkoutPreferencesRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      final result = await repository.getWorkoutPreferences();
      expect(result, isNull);
    });
  });
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient({this.currentUser});

  final User? currentUser;

  @override
  GoTrueClient get auth => FakeGoTrueClient(currentUser: currentUser);
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  FakeGoTrueClient({this.currentUser});

  @override
  final User? currentUser;
}
