import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _ownerUserId = '11111111-1111-4111-8111-111111111111';

void main() {
  final exerciseId =
      UserCreatedExerciseRef('22222222-2222-4222-8222-222222222222');
  final sourceRef = CatalogExerciseRef('ex_barbell_bench_press');

  group('SupabaseUserExerciseRepository', () {
    test('signed-out list is empty and writes fail before gateway access',
        () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway, currentUserId: null);

      expect(await repository.list(), isEmpty);
      await expectLater(
        () => repository.create(
          id: exerciseId,
          displayName: 'My Exercise',
        ),
        throwsStateError,
      );
      await expectLater(
        () => repository.rename(
          id: exerciseId,
          displayName: 'Renamed',
        ),
        throwsStateError,
      );
      await expectLater(
        () => repository.archive(exerciseId),
        throwsStateError,
      );
      await expectLater(
        () => repository.updateDefinition(
          id: exerciseId,
          definition: UserExerciseDefinition(),
        ),
        throwsStateError,
      );

      expect(gateway.listCalls, isEmpty);
      expect(gateway.insertPayloads, isEmpty);
      expect(gateway.renameCalls, isEmpty);
      expect(gateway.archiveCalls, isEmpty);
      expect(gateway.definitionCalls, isEmpty);
    });

    test('list maps active and archived rows to canonical Exercises', () async {
      final gateway = _FakeUserExerciseGateway(
        rows: [
          {
            'id': exerciseId.value,
            'display_name': 'My Exercise',
            'status': 'active',
            'description': null,
            'exercise_type': null,
            'primary_muscle': null,
            'secondary_muscles': <String>[],
            'primary_equipment': null,
          },
          {
            'id': '33333333-3333-4333-8333-333333333333',
            'display_name': 'Old Exercise',
            'status': 'archived',
            'description': null,
            'exercise_type': null,
            'primary_muscle': null,
            'secondary_muscles': <String>[],
            'primary_equipment': null,
          },
        ],
      );
      final repository = _repository(gateway: gateway);

      final exercises = await repository.list(includeArchived: true);

      expect(exercises, [
        Exercise(
          ref: exerciseId,
          displayName: 'My Exercise',
          status: ExerciseStatus.active,
        ),
        Exercise(
          ref: ExerciseRef.userCreated(
            '33333333-3333-4333-8333-333333333333',
          ),
          displayName: 'Old Exercise',
          status: ExerciseStatus.archived,
        ),
      ]);
      expect(gateway.listCalls, [
        (userId: _ownerUserId, includeArchived: true),
      ]);
    });

    test('list maps dynamic Supabase arrays and optional definition fields',
        () async {
      final secondary = <dynamic>['triceps_brachii', 'deltoid_anterior'];
      final repository = _repository(
          gateway: _FakeUserExerciseGateway(rows: [
        {
          'id': exerciseId.value,
          'display_name': 'Tempo Press',
          'status': 'active',
          'description': 'Tempo focus',
          'exercise_type': 'dumbbell_x2_simultaneous',
          'primary_muscle': 'pectoralis_major_sternal_head',
          'secondary_muscles': secondary,
          'primary_equipment': 'dumbbell',
        },
      ]));
      final exercise = (await repository.list()).single;
      expect(exercise.description, 'Tempo focus');
      expect(exercise.exerciseType, ExerciseType.dumbbellX2Simultaneous);
      expect(exercise.primaryMuscles, ['pectoralis_major_sternal_head']);
      expect(
          exercise.secondaryMuscles, ['triceps_brachii', 'deltoid_anterior']);
      expect(exercise.primaryEquipment, 'dumbbell');
      secondary.clear();
      expect(exercise.secondaryMuscles, hasLength(2));
    });

    test('malformed definition rows fail closed', () async {
      for (final invalid in <Map<String, dynamic>>[
        {'description': 42},
        {'description': ' \t\n '},
        {'exercise_type': 'unknown'},
        {'exercise_type': 1},
        {'primary_muscle': '1'},
        {'primary_equipment': 'unknown'},
        {'secondary_muscles': null},
        {'secondary_muscles': 'triceps_brachii'},
        {
          'secondary_muscles': <dynamic>[null]
        },
        {
          'secondary_muscles': <dynamic>[1]
        },
        {
          'secondary_muscles': ['unknown']
        },
        {
          'secondary_muscles': ['triceps_brachii', 'triceps_brachii']
        },
        {
          'primary_muscle': 'triceps_brachii',
          'secondary_muscles': ['triceps_brachii'],
        },
      ]) {
        final repository = _repository(
            gateway: _FakeUserExerciseGateway(rows: [
          {
            'id': exerciseId.value,
            'display_name': 'Malformed',
            'status': 'active',
            'secondary_muscles': <dynamic>[],
            ...invalid,
          },
        ]));
        await expectLater(repository.list(), throwsA(anything));
      }
    });

    test('updateDefinition rejects zero affected rows', () async {
      final gateway = _FakeUserExerciseGateway(definitionAffectsRow: false);
      final repository = _repository(gateway: gateway);
      await expectLater(
        repository.updateDefinition(
          id: exerciseId,
          definition: UserExerciseDefinition(),
        ),
        throwsStateError,
      );
    });

    test('list excludes archived by default at gateway boundary', () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway);

      await repository.list();

      expect(gateway.listCalls, [
        (userId: _ownerUserId, includeArchived: false),
      ]);
    });

    test('malformed rows fail closed', () async {
      for (final row in <Map<String, dynamic>>[
        {
          'id': 42,
          'display_name': 'My Exercise',
          'status': 'active',
        },
        {
          'id': exerciseId.value,
          'display_name': null,
          'status': 'active',
        },
        {
          'id': 'not-a-uuid',
          'display_name': 'My Exercise',
          'status': 'active',
        },
        {
          'id': exerciseId.value,
          'display_name': '   ',
          'status': 'active',
        },
        {
          'id': exerciseId.value,
          'display_name': 'My Exercise',
          'status': 'deleted',
        },
      ]) {
        final repository = _repository(
          gateway: _FakeUserExerciseGateway(rows: [row]),
        );
        await expectLater(
          repository.list(includeArchived: true),
          throwsA(anything),
        );
      }
    });

    test('create writes only approved columns and optional source lineage',
        () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway);

      await repository.create(
        id: exerciseId,
        displayName: ' My Paused Bench ',
        basedOnCatalogExercise: sourceRef,
      );

      expect(gateway.insertPayloads, [
        {
          'id': exerciseId.value,
          'user_id': _ownerUserId,
          'display_name': ' My Paused Bench ',
          'based_on_catalog_exercise_id': sourceRef.value,
        },
      ]);
    });

    test('create without source lineage omits the lineage column', () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway);

      await repository.create(
        id: exerciseId,
        displayName: 'My Exercise',
      );

      expect(gateway.insertPayloads, [
        {
          'id': exerciseId.value,
          'user_id': _ownerUserId,
          'display_name': 'My Exercise',
        },
      ]);
    });

    test('create round-trips approved structured definition fields', () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway);
      final definition = UserExerciseDefinition(
        description: ' Tempo focus ',
        exerciseType: ExerciseType.weightReps,
        primaryMuscle: 'pectoralis_major_sternal_head',
        secondaryMuscles: const ['triceps_brachii', 'deltoid_anterior'],
        primaryEquipment: 'dumbbell',
      );

      await repository.create(
        id: exerciseId,
        displayName: 'Incline Dumbbell Press',
        definition: definition,
      );

      expect(gateway.insertPayloads.single, {
        'id': exerciseId.value,
        'user_id': _ownerUserId,
        'display_name': 'Incline Dumbbell Press',
        'description': 'Tempo focus',
        'exercise_type': 'weight_reps',
        'primary_muscle': 'pectoralis_major_sternal_head',
        'secondary_muscles': ['triceps_brachii', 'deltoid_anterior'],
        'primary_equipment': 'dumbbell',
      });
    });

    test('updateDefinition writes only mutable definition columns', () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway);
      final definition = UserExerciseDefinition(
        exerciseType: ExerciseType.duration,
        primaryMuscle: 'rectus_abdominis',
      );

      await repository.updateDefinition(id: exerciseId, definition: definition);

      final call = gateway.definitionCalls.single;
      expect(call.userId, _ownerUserId);
      expect(call.exerciseId, exerciseId.value);
      expect(call.definition, {
        'description': null,
        'exercise_type': 'duration',
        'primary_muscle': 'rectus_abdominis',
        'secondary_muscles': <String>[],
        'primary_equipment': null,
      });
    });

    test('create and rename reject blank names before gateway writes',
        () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway);

      await expectLater(
        () => repository.create(id: exerciseId, displayName: '   '),
        throwsArgumentError,
      );
      await expectLater(
        () => repository.rename(id: exerciseId, displayName: '   '),
        throwsArgumentError,
      );

      expect(gateway.insertPayloads, isEmpty);
      expect(gateway.renameCalls, isEmpty);
    });

    test('rename and archive fail when no durable row is affected', () async {
      final renameGateway = _FakeUserExerciseGateway(
        renameAffectsRow: false,
      );
      final renameRepository = _repository(gateway: renameGateway);

      await expectLater(
        () => renameRepository.rename(
          id: exerciseId,
          displayName: 'Renamed',
        ),
        throwsStateError,
      );

      final archiveGateway = _FakeUserExerciseGateway(
        archiveAffectsRow: false,
      );
      final archiveRepository = _repository(gateway: archiveGateway);

      await expectLater(
        () => archiveRepository.archive(exerciseId),
        throwsStateError,
      );
    });

    test('rename and archive scope writes to owner plus Exercise id', () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway);

      await repository.rename(
        id: exerciseId,
        displayName: ' Renamed ',
      );
      await repository.archive(exerciseId);

      expect(gateway.renameCalls, [
        (
          userId: _ownerUserId,
          exerciseId: exerciseId.value,
          displayName: ' Renamed ',
        ),
      ]);
      expect(gateway.archiveCalls, [
        (userId: _ownerUserId, exerciseId: exerciseId.value),
      ]);
    });
  });
}

SupabaseUserExerciseRepository _repository({
  required _FakeUserExerciseGateway gateway,
  String? currentUserId = _ownerUserId,
}) {
  return SupabaseUserExerciseRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => currentUserId,
  );
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeUserExerciseGateway implements UserExerciseTableGateway {
  _FakeUserExerciseGateway({
    this.rows = const [],
    this.renameAffectsRow = true,
    this.archiveAffectsRow = true,
    this.definitionAffectsRow = true,
  });

  final List<Map<String, dynamic>> rows;
  final bool renameAffectsRow;
  final bool archiveAffectsRow;
  final bool definitionAffectsRow;
  final List<({String userId, bool includeArchived})> listCalls = [];
  final List<Map<String, dynamic>> insertPayloads = [];
  final List<
          ({String userId, String exerciseId, Map<String, dynamic> definition})>
      definitionCalls = [];
  final List<
      ({
        String userId,
        String exerciseId,
        String displayName,
      })> renameCalls = [];
  final List<({String userId, String exerciseId})> archiveCalls = [];

  @override
  Future<List<Map<String, dynamic>>> listRows({
    required String userId,
    required bool includeArchived,
  }) async {
    listCalls.add((
      userId: userId,
      includeArchived: includeArchived,
    ));
    return rows;
  }

  @override
  Future<void> insertRow(Map<String, dynamic> payload) async {
    insertPayloads.add(Map<String, dynamic>.from(payload));
  }

  @override
  Future<bool> updateDefinitionRow({
    required String userId,
    required String exerciseId,
    required Map<String, dynamic> definition,
  }) async {
    definitionCalls.add((
      userId: userId,
      exerciseId: exerciseId,
      definition: Map<String, dynamic>.from(definition),
    ));
    return definitionAffectsRow;
  }

  @override
  Future<bool> renameRow({
    required String userId,
    required String exerciseId,
    required String displayName,
  }) async {
    renameCalls.add((
      userId: userId,
      exerciseId: exerciseId,
      displayName: displayName,
    ));
    return renameAffectsRow;
  }

  @override
  Future<bool> archiveRow({
    required String userId,
    required String exerciseId,
  }) async {
    archiveCalls.add((
      userId: userId,
      exerciseId: exerciseId,
    ));
    return archiveAffectsRow;
  }
}
