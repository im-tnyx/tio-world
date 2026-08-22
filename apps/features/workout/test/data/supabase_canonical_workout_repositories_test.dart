import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  group('SupabaseWorkoutProfileRepository', () {
    test('signed-out read is null and write fails before gateway access',
        () async {
      final gateway = _FakeProfileGateway();
      final repository = _profileRepository(gateway: gateway, userId: null);

      expect(await repository.read(), isNull);
      await expectLater(
        () => repository.upsert(const WorkoutProfileData()),
        throwsStateError,
      );
      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('read preserves unknown versus explicit empty Profile collections',
        () async {
      final unknown = _profileRepository(
        gateway: _FakeProfileGateway(
          readResult: {
            'workout_location': null,
            'available_equipment': null,
            'experience_level': null,
            'focus_areas': null,
            'health_concerns': null,
          },
        ),
      );
      final unknownData = await unknown.read();
      expect(unknownData?.workoutLocation, isNull);
      expect(unknownData?.availableEquipment, isNull);
      expect(unknownData?.experienceLevel, isNull);
      expect(unknownData?.focusAreas, isNull);
      expect(unknownData?.healthConcerns, isNull);

      final explicit = _profileRepository(
        gateway: _FakeProfileGateway(
          readResult: {
            'workout_location': 'home',
            'available_equipment': <dynamic>[],
            'experience_level': 'beginner',
            'focus_areas': <dynamic>[],
            'health_concerns': <dynamic>[],
          },
        ),
      );
      final explicitData = await explicit.read();
      expect(explicitData?.workoutLocation, WorkoutGymAccess.home);
      expect(explicitData?.availableEquipment, isEmpty);
      expect(explicitData?.experienceLevel, WorkoutExperienceLevel.beginner);
      expect(explicitData?.focusAreas, isEmpty);
      expect(explicitData?.healthConcerns, isEmpty);
    });

    test('strictly parses complete canonical Workout Profile row', () async {
      final repository = _profileRepository(
        gateway: _FakeProfileGateway(
          readResult: {
            'workout_location': 'gym',
            'available_equipment': <dynamic>['dumbbells', 'bench'],
            'experience_level': 'intermediate',
            'focus_areas': <dynamic>['fullBody', 'back'],
            'health_concerns': <dynamic>['knee'],
          },
        ),
      );

      final data = await repository.read();
      expect(data?.workoutLocation, WorkoutGymAccess.gym);
      expect(data?.availableEquipment, {
        WorkoutEquipment.dumbbells,
        WorkoutEquipment.bench,
      });
      expect(data?.experienceLevel, WorkoutExperienceLevel.intermediate);
      expect(data?.focusAreas, {
        WorkoutFocusArea.fullBody,
        WorkoutFocusArea.back,
      });
      expect(data?.healthConcerns, {'knee'});
    });

    test('malformed canonical Workout Profile rows fail closed', () async {
      final invalidRows = <Map<String, dynamic>>[
        {
          ..._validProfileRow(),
          'workout_location': 'park',
        },
        {
          ..._validProfileRow(),
          'available_equipment': 'dumbbells',
        },
        {
          ..._validProfileRow(),
          'available_equipment': <dynamic>['future_equipment'],
        },
        {
          ..._validProfileRow(),
          'experience_level': 'expert',
        },
        {
          ..._validProfileRow(),
          'focus_areas': <dynamic>[1],
        },
        {
          ..._validProfileRow(),
          'health_concerns': <dynamic>[1],
        },
      ];

      for (final row in invalidRows) {
        final repository = _profileRepository(
          gateway: _FakeProfileGateway(readResult: row),
        );
        await expectLater(repository.read(), throwsFormatException);
      }
    });

    test('write touches canonical Workout Profile context columns only',
        () async {
      final gateway = _FakeProfileGateway();
      final repository = _profileRepository(gateway: gateway);

      await repository.upsert(
        const WorkoutProfileData(
          workoutLocation: WorkoutGymAccess.home,
          availableEquipment: {
            WorkoutEquipment.mat,
            WorkoutEquipment.dumbbells,
          },
          experienceLevel: WorkoutExperienceLevel.advanced,
          focusAreas: {
            WorkoutFocusArea.fullBody,
            WorkoutFocusArea.chest,
          },
          healthConcerns: {'shoulder', 'knee'},
        ),
      );

      expect(gateway.upsertPayloads, [
        {
          'user_id': 'user-1',
          'workout_location': 'home',
          'available_equipment': ['dumbbells', 'mat'],
          'experience_level': 'advanced',
          'focus_areas': ['chest', 'fullBody'],
          'health_concerns': ['knee', 'shoulder'],
        }
      ]);
      expect(
        gateway.upsertPayloads.single.keys,
        isNot(contains('training_days')),
      );
      expect(
        gateway.upsertPayloads.single.keys,
        isNot(contains('split_program')),
      );
    });
  });

  group('SupabaseWorkoutTargetsRepository', () {
    test('signed-out read is null and write fails before gateway access',
        () async {
      final gateway = _FakeTargetsGateway();
      final repository = _targetsRepository(gateway: gateway, userId: null);

      expect(await repository.read(), isNull);
      await expectLater(
        () => repository.upsert(const WorkoutTargetsData()),
        throwsStateError,
      );
      expect(gateway.readUserIds, isEmpty);
      expect(gateway.upsertPayloads, isEmpty);
    });

    test('strictly parses complete canonical Workout Targets row', () async {
      final repository = _targetsRepository(
        gateway: _FakeTargetsGateway(
          readResult: {
            'primary_workout_goal': 'build_muscle',
            'primary_goal_rank': 1,
            'supporting_workout_goal': 'get_stronger',
            'supporting_goal_rank': 2,
            'training_days': <dynamic>['monday', 'thursday'],
            'preferred_duration_mins': 60,
            'split_program': 'upperLower',
            'special_event': 'Strength meet',
            'special_event_date': '2027-03-14',
          },
        ),
      );

      final data = await repository.read();
      expect(data?.primaryWorkoutGoal, WorkoutTargetGoal.buildMuscle);
      expect(data?.primaryGoalRank, 1);
      expect(data?.supportingWorkoutGoal, WorkoutTargetGoal.getStronger);
      expect(data?.supportingGoalRank, 2);
      expect(data?.trainingDays, {
        WorkoutTrainingDay.monday,
        WorkoutTrainingDay.thursday,
      });
      expect(data?.preferredDurationMins, 60);
      expect(data?.splitProgram, WorkoutSplit.upperLower);
      expect(data?.specialEvent, 'Strength meet');
      expect(data?.specialEventDate, DateTime.utc(2027, 3, 14));
    });

    test('malformed canonical Workout Targets rows fail closed', () async {
      final invalidRows = <Map<String, dynamic>>[
        {
          ..._validTargetsRow(),
          'primary_workout_goal': 'lose_weight',
        },
        {
          ..._validTargetsRow(),
          'primary_goal_rank': 3,
        },
        {
          ..._validTargetsRow(),
          'training_days': null,
        },
        {
          ..._validTargetsRow(),
          'training_days': <dynamic>['funday'],
        },
        {
          ..._validTargetsRow(),
          'preferred_duration_mins': 0,
        },
        {
          ..._validTargetsRow(),
          'split_program': 'future_split',
        },
        {
          ..._validTargetsRow(),
          'special_event_date': '2027-02-30',
        },
        {
          ..._validTargetsRow(),
          'primary_workout_goal': null,
          'primary_goal_rank': null,
          'supporting_workout_goal': 'stay_fit',
          'supporting_goal_rank': 2,
        },
      ];

      for (final row in invalidRows) {
        final repository = _targetsRepository(
          gateway: _FakeTargetsGateway(readResult: row),
        );
        await expectLater(repository.read(), throwsFormatException);
      }
    });

    test('write touches canonical Workout Targets columns only', () async {
      final gateway = _FakeTargetsGateway();
      final repository = _targetsRepository(gateway: gateway);

      await repository.upsert(
        WorkoutTargetsData(
          primaryWorkoutGoal: WorkoutTargetGoal.getStronger,
          primaryGoalRank: 1,
          supportingWorkoutGoal: WorkoutTargetGoal.stayFit,
          supportingGoalRank: 2,
          trainingDays: const {
            WorkoutTrainingDay.thursday,
            WorkoutTrainingDay.monday,
          },
          preferredDurationMins: 45,
          splitProgram: WorkoutSplit.fullBody,
          specialEvent: 'Trail race',
          specialEventDate: DateTime.utc(2027, 10, 5),
        ),
      );

      expect(gateway.upsertPayloads, [
        {
          'user_id': 'user-1',
          'primary_workout_goal': 'get_stronger',
          'primary_goal_rank': 1,
          'supporting_workout_goal': 'stay_fit',
          'supporting_goal_rank': 2,
          'training_days': ['monday', 'thursday'],
          'preferred_duration_mins': 45,
          'split_program': 'fullBody',
          'special_event': 'Trail race',
          'special_event_date': '2027-10-05',
        }
      ]);
      expect(
        gateway.upsertPayloads.single.keys,
        isNot(contains('workout_location')),
      );
      expect(
        gateway.upsertPayloads.single.keys,
        isNot(contains('experience_level')),
      );
    });

    test('invalid target write fails before canonical gateway access', () async {
      final gateway = _FakeTargetsGateway();
      final repository = _targetsRepository(gateway: gateway);

      await expectLater(
        () => repository.upsert(
          const WorkoutTargetsData(preferredDurationMins: 0),
        ),
        throwsArgumentError,
      );
      expect(gateway.upsertPayloads, isEmpty);
    });
  });
}

SupabaseWorkoutProfileRepository _profileRepository({
  required _FakeProfileGateway gateway,
  String? userId = 'user-1',
}) {
  return SupabaseWorkoutProfileRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

SupabaseWorkoutTargetsRepository _targetsRepository({
  required _FakeTargetsGateway gateway,
  String? userId = 'user-1',
}) {
  return SupabaseWorkoutTargetsRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

Map<String, dynamic> _validProfileRow() => {
      'workout_location': 'gym',
      'available_equipment': <dynamic>['dumbbells'],
      'experience_level': 'beginner',
      'focus_areas': <dynamic>['fullBody'],
      'health_concerns': <dynamic>[],
    };

Map<String, dynamic> _validTargetsRow() => {
      'primary_workout_goal': 'get_stronger',
      'primary_goal_rank': 1,
      'supporting_workout_goal': null,
      'supporting_goal_rank': null,
      'training_days': <dynamic>['monday'],
      'preferred_duration_mins': 45,
      'split_program': 'fullBody',
      'special_event': null,
      'special_event_date': null,
    };

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeProfileGateway implements WorkoutProfileTableGateway {
  _FakeProfileGateway({this.readResult});

  final Map<String, dynamic>? readResult;
  final List<String> readUserIds = [];
  final List<Map<String, dynamic>> upsertPayloads = [];

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    readUserIds.add(userId);
    return readResult;
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    upsertPayloads.add(Map<String, dynamic>.from(payload));
  }
}

class _FakeTargetsGateway implements WorkoutTargetsTableGateway {
  _FakeTargetsGateway({this.readResult});

  final Map<String, dynamic>? readResult;
  final List<String> readUserIds = [];
  final List<Map<String, dynamic>> upsertPayloads = [];

  @override
  Future<Map<String, dynamic>?> readRow(String userId) async {
    readUserIds.add(userId);
    return readResult;
  }

  @override
  Future<void> upsertRow(Map<String, dynamic> payload) async {
    upsertPayloads.add(Map<String, dynamic>.from(payload));
  }
}
