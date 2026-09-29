import 'package:flutter_test/flutter_test.dart';
import 'package:tio_shared/shared.dart';
import 'package:workout/src/data/repositories/supabase_routine_repository.dart';

void main() {
  const userId = '11111111-1111-4111-8111-111111111111';
  final programId = ProgramId('22222222-2222-4222-8222-222222222222');
  final routineId = RoutineId('33333333-3333-4333-8333-333333333333');

  group('SupabaseRoutineRepository', () {
    test('signed-out list returns empty without querying gateway', () async {
      final gateway = _FakeRoutineGateway();
      final repository = SupabaseRoutineRepository(
        gateway: gateway,
        currentUserId: () => null,
      );

      expect(await repository.list(programId), isEmpty);
      expect(gateway.listCalls, 0);
    });

    test('list scopes by user and Program and maps rows', () async {
      final gateway = _FakeRoutineGateway()
        ..rows = [
          {
            'id': routineId.value,
            'program_id': programId.value,
            'name': 'Routine 1',
          },
        ];
      final repository = SupabaseRoutineRepository(
        gateway: gateway,
        currentUserId: () => userId,
      );

      final routines = await repository.list(programId);

      expect(routines, [
        Routine(id: routineId, programId: programId, name: 'Routine 1'),
      ]);
      expect(gateway.lastUserId, userId);
      expect(gateway.lastProgramId, programId.value);
    });

    test('list rejects malformed rows', () async {
      final gateway = _FakeRoutineGateway()
        ..rows = [
          {'id': routineId.value, 'program_id': 42, 'name': 'Routine 1'},
        ];
      final repository = SupabaseRoutineRepository(
        gateway: gateway,
        currentUserId: () => userId,
      );

      expect(repository.list(programId), throwsFormatException);
    });

    test('create writes only approved Routine fields', () async {
      final gateway = _FakeRoutineGateway();
      final repository = SupabaseRoutineRepository(
        gateway: gateway,
        currentUserId: () => userId,
      );
      final routine = Routine(
        id: routineId,
        programId: programId,
        name: ' Routine 1 ',
      );

      await repository.create(routine);

      expect(gateway.inserted, {
        'id': routineId.value,
        'user_id': userId,
        'program_id': programId.value,
        'name': ' Routine 1 ',
      });
    });

    test('signed-out create and rename fail before gateway writes', () async {
      final gateway = _FakeRoutineGateway();
      final repository = SupabaseRoutineRepository(
        gateway: gateway,
        currentUserId: () => null,
      );

      expect(
        repository.create(
          Routine(id: routineId, programId: programId, name: 'Routine 1'),
        ),
        throwsStateError,
      );
      expect(
        repository.rename(id: routineId, name: 'Strength'),
        throwsStateError,
      );
      expect(gateway.inserted, isNull);
      expect(gateway.renamed, isNull);
    });

    test('rename rejects blank name and scopes write by owner', () async {
      final gateway = _FakeRoutineGateway();
      final repository = SupabaseRoutineRepository(
        gateway: gateway,
        currentUserId: () => userId,
      );

      expect(
        repository.rename(id: routineId, name: '   '),
        throwsArgumentError,
      );
      expect(gateway.renamed, isNull);

      await repository.rename(id: routineId, name: ' Strength ');

      expect(gateway.renamed, {
        'user_id': userId,
        'routine_id': routineId.value,
        'name': ' Strength ',
      });
    });
  });
}

final class _FakeRoutineGateway implements RoutineTableGateway {
  List<Map<String, dynamic>> rows = const [];
  int listCalls = 0;
  String? lastUserId;
  String? lastProgramId;
  Map<String, dynamic>? inserted;
  Map<String, dynamic>? renamed;

  @override
  Future<List<Map<String, dynamic>>> listRows({
    required String userId,
    required String programId,
  }) async {
    listCalls += 1;
    lastUserId = userId;
    lastProgramId = programId;
    return rows;
  }

  @override
  Future<void> insertRow(Map<String, dynamic> values) async {
    inserted = values;
  }

  @override
  Future<void> renameRow({
    required String userId,
    required String routineId,
    required String name,
  }) async {
    renamed = {
      'user_id': userId,
      'routine_id': routineId,
      'name': name,
    };
  }
}
