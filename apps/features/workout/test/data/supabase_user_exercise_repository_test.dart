import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const userId = '11111111-1111-4111-8111-111111111111';
  final exerciseId =
      UserCreatedExerciseRef('22222222-2222-4222-8222-222222222222');
  final sourceRef = CatalogExerciseRef('ex_barbell_bench_press');

  group('SupabaseUserExerciseRepository', () {
    test('signed-out list is empty and writes fail before gateway access',
        () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway, userId: null);

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

      expect(gateway.listCalls, isEmpty);
      expect(gateway.insertPayloads, isEmpty);
      expect(gateway.renameCalls, isEmpty);
      expect(gateway.archiveCalls, isEmpty);
    });

    test('list maps active and archived rows to canonical Exercises', () async {
      final gateway = _FakeUserExerciseGateway(
        rows: [
          {
            'id': exerciseId.value,
            'display_name': 'My Exercise',
            'status': 'active',
          },
          {
            'id': '33333333-3333-4333-8333-333333333333',
            'display_name': 'Old Exercise',
            'status': 'archived',
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
        (userId: userId, includeArchived: true),
      ]);
    });

    test('list excludes archived by default at gateway boundary', () async {
      final gateway = _FakeUserExerciseGateway();
      final repository = _repository(gateway: gateway);

      await repository.list();

      expect(gateway.listCalls, [
        (userId: userId, includeArchived: false),
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
          'user_id': userId,
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
          'user_id': userId,
          'display_name': 'My Exercise',
        },
      ]);
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
          userId: userId,
          exerciseId: exerciseId.value,
          displayName: ' Renamed ',
        ),
      ]);
      expect(gateway.archiveCalls, [
        (userId: userId, exerciseId: exerciseId.value),
      ]);
    });
  });
}

SupabaseUserExerciseRepository _repository({
  required _FakeUserExerciseGateway gateway,
  String? userId = userId,
}) {
  return SupabaseUserExerciseRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeUserExerciseGateway implements UserExerciseTableGateway {
  _FakeUserExerciseGateway({this.rows = const []});

  final List<Map<String, dynamic>> rows;
  final List<({String userId, bool includeArchived})> listCalls = [];
  final List<Map<String, dynamic>> insertPayloads = [];
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
  Future<void> renameRow({
    required String userId,
    required String exerciseId,
    required String displayName,
  }) async {
    renameCalls.add((
      userId: userId,
      exerciseId: exerciseId,
      displayName: displayName,
    ));
  }

  @override
  Future<void> archiveRow({
    required String userId,
    required String exerciseId,
  }) async {
    archiveCalls.add((
      userId: userId,
      exerciseId: exerciseId,
    ));
  }
}
