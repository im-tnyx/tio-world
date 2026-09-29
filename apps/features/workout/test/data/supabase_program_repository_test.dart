import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const idValue = '550e8400-e29b-41d4-a716-446655440000';

  group('SupabaseProgramRepository', () {
    test('signed-out list is empty and writes fail before gateway access',
        () async {
      final gateway = _FakeProgramGateway();
      final repository = _repository(gateway: gateway, userId: null);
      final program = Program(id: ProgramId(idValue), name: 'Program 1');

      expect(await repository.list(), isEmpty);
      await expectLater(() => repository.create(program), throwsStateError);
      await expectLater(
        () => repository.rename(id: program.id, name: 'Renamed'),
        throwsStateError,
      );
      expect(gateway.listUserIds, isEmpty);
      expect(gateway.insertPayloads, isEmpty);
      expect(gateway.renameCalls, isEmpty);
    });

    test('list maps canonical rows to Programs', () async {
      final gateway = _FakeProgramGateway(
        rows: [
          {'id': idValue, 'name': 'Program 1'},
        ],
      );
      final repository = _repository(gateway: gateway);

      final programs = await repository.list();

      expect(programs, [
        Program(id: ProgramId(idValue), name: 'Program 1'),
      ]);
      expect(gateway.listUserIds, ['user-1']);
    });

    test('malformed canonical rows fail closed', () async {
      for (final row in <Map<String, dynamic>>[
        {'id': 1, 'name': 'Program 1'},
        {'id': idValue, 'name': null},
        {'id': 'not-a-uuid', 'name': 'Program 1'},
        {'id': idValue, 'name': '   '},
      ]) {
        final repository = _repository(
          gateway: _FakeProgramGateway(rows: [row]),
        );
        await expectLater(repository.list(), throwsA(anything));
      }
    });

    test('create writes only approved Program columns', () async {
      final gateway = _FakeProgramGateway();
      final repository = _repository(gateway: gateway);

      await repository.create(
        Program(id: ProgramId(idValue), name: ' Program 1 '),
      );

      expect(gateway.insertPayloads, [
        {
          'id': idValue,
          'user_id': 'user-1',
          'name': ' Program 1 ',
        }
      ]);
    });

    test('rename validates name and scopes update to owner plus Program id',
        () async {
      final gateway = _FakeProgramGateway();
      final repository = _repository(gateway: gateway);
      final id = ProgramId(idValue);

      await repository.rename(id: id, name: 'Renamed');

      expect(gateway.renameCalls, [
        (userId: 'user-1', programId: idValue, name: 'Renamed'),
      ]);

      await expectLater(
        () => repository.rename(id: id, name: '   '),
        throwsArgumentError,
      );
      expect(gateway.renameCalls, hasLength(1));
    });
  });
}

SupabaseProgramRepository _repository({
  required _FakeProgramGateway gateway,
  String? userId = 'user-1',
}) {
  return SupabaseProgramRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    currentUserId: () => userId,
  );
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}

class _FakeProgramGateway implements ProgramTableGateway {
  _FakeProgramGateway({this.rows = const []});

  final List<Map<String, dynamic>> rows;
  final List<String> listUserIds = [];
  final List<Map<String, dynamic>> insertPayloads = [];
  final List<({String userId, String programId, String name})> renameCalls = [];

  @override
  Future<List<Map<String, dynamic>>> listRows(String userId) async {
    listUserIds.add(userId);
    return rows;
  }

  @override
  Future<void> insertRow(Map<String, dynamic> payload) async {
    insertPayloads.add(Map<String, dynamic>.from(payload));
  }

  @override
  Future<void> renameRow({
    required String userId,
    required String programId,
    required String name,
  }) async {
    renameCalls.add((
      userId: userId,
      programId: programId,
      name: name,
    ));
  }
}
