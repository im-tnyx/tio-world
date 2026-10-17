import 'package:flutter_test/flutter_test.dart';
import 'package:tio_shared/shared.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  const userId = '11111111-1111-4111-8111-111111111111';
  final programId = ProgramId('22222222-2222-4222-8222-222222222222');
  final routineId = RoutineId('33333333-3333-4333-8333-333333333333');

  group('SupabaseRoutineRepository', () {
    test('signed-out or blank-user list returns empty without gateway', () async {
      final gateway = _FakeRoutineGateway();
      final repository = SupabaseRoutineRepository(
        gateway: gateway, currentUserId: () => null);
      expect(await repository.list(programId), isEmpty);
      expect(await repository.listVersioned(programId), isEmpty);
      final blankRepository = SupabaseRoutineRepository(
        gateway: gateway, currentUserId: () => '   ');
      expect(await blankRepository.list(programId), isEmpty);
      expect(gateway.listCalls, 0);
    });

    test('list freezes owner-scoped Program and revision', () async {
      final gateway = _FakeRoutineGateway()
        ..rows = [
          {
            'id': routineId.value,
            'program_id': programId.value,
            'name': 'Routine 1',
            'composition_revision': 7,
          },
        ];
      final repository = SupabaseRoutineRepository(
        gateway: gateway, currentUserId: () => userId);
      final snapshots = await repository.listVersioned(programId);
      expect(snapshots.single.routine,
        Routine(id: routineId, programId: programId, name: 'Routine 1'));
      expect(snapshots.single.revision, 7);
      expect(gateway.lastUserId, userId);
      expect(gateway.lastProgramId, programId.value);
      expect(await repository.list(programId), [snapshots.single.routine]);
    });

    test('missing or invalid revision and foreign Program fail closed', () async {
      final gateway = _FakeRoutineGateway();
      final repository = SupabaseRoutineRepository(
        gateway: gateway, currentUserId: () => userId);
      for (final row in [
        {'id': routineId.value, 'program_id': 42, 'name': 'One',
         'composition_revision': 0},
        {'id': routineId.value, 'program_id': programId.value,
         'name': 'One'},
        {'id': routineId.value, 'program_id': programId.value,
         'name': 'One', 'composition_revision': -1},
        {'id': routineId.value,
         'program_id': '44444444-4444-4444-8444-444444444444',
         'name': 'One', 'composition_revision': 1},
      ]) {
        gateway.rows = [row];
        await expectLater(repository.listVersioned(programId),
          throwsFormatException);
      }
    });

    test('user switch after list network response rejects old rows', () async {
      String? user = userId;
      final gateway = _FakeRoutineGateway()
        ..onList = () => user = '55555555-5555-4555-8555-555555555555';
      final repository = SupabaseRoutineRepository(
        gateway: gateway, currentUserId: () => user);
      await expectLater(repository.listVersioned(programId), throwsStateError);
    });

    test('create still writes only approved fields', () async {
      final gateway = _FakeRoutineGateway();
      final repository = SupabaseRoutineRepository(
        gateway: gateway, currentUserId: () => userId);
      final routine = Routine(id: routineId, programId: programId,
        name: ' Routine 1 ');
      await repository.create(routine);
      expect(gateway.inserted, {
        'id': routineId.value,
        'user_id': userId,
        'program_id': programId.value,
        'name': ' Routine 1 ',
      });
    });

    test('signed-out create and both Rename variants reject', () async {
      final gateway = _FakeRoutineGateway();
      final updates = _FakeAggregateUpdates();
      final repository = SupabaseRoutineRepository(
        gateway: gateway, currentUserId: () => null,
        aggregateUpdates: updates);
      await expectLater(repository.create(Routine(id: routineId,
        programId: programId, name: 'Routine 1')), throwsStateError);
      await expectLater(repository.rename(id: routineId, name: 'Strength'),
        throwsStateError);
      await expectLater(repository.renameVersioned(_rename(routineId,
        programId, 'Strength')), throwsStateError);
      expect(gateway.inserted, isNull);
      expect(updates.command, isNull);
    });

    test('legacy unversioned Rename never invokes direct UPDATE', () async {
      final gateway = _FakeRoutineGateway();
      final updates = _FakeAggregateUpdates();
      final repository = SupabaseRoutineRepository(
        gateway: gateway, currentUserId: () => userId,
        aggregateUpdates: updates);
      await expectLater(repository.rename(id: routineId, name: '   '),
        throwsArgumentError);
      await expectLater(repository.rename(id: routineId, name: 'Strength'),
        throwsStateError);
      expect(updates.command, isNull);
    });

    test('versioned Rename delegates only frozen name-only RPC', () async {
      final updates = _FakeAggregateUpdates();
      final repository = SupabaseRoutineRepository(
        gateway: _FakeRoutineGateway(), currentUserId: () => userId,
        aggregateUpdates: updates);
      final command = _rename(routineId, programId, 'Strength');
      expect(await repository.renameVersioned(command), 5);
      expect(identical(updates.command, command), isTrue);
      expect(command.programId, programId);
      expect(command.expectedRevision, 4);
      expect(command.expectedName, 'Morning');
      expect(command.entries, isNull);
    });

    test('versioned Rename cannot supply composition replacement', () async {
      final updates = _FakeAggregateUpdates();
      final repository = SupabaseRoutineRepository(
        gateway: _FakeRoutineGateway(), currentUserId: () => userId,
        aggregateUpdates: updates);
      final invalid = RoutineAggregateUpdate(
        routineId: routineId, programId: programId, expectedRevision: 4,
        expectedName: 'Morning', mutationId:
        '66666666-6666-4666-8666-666666666666',
        name: 'Strength', entries: const []);
      await expectLater(repository.renameVersioned(invalid), throwsArgumentError);
      expect(updates.command, isNull);
    });
  });
}

RoutineAggregateUpdate _rename(RoutineId id, ProgramId programId, String name) =>
    RoutineAggregateUpdate(
      routineId: id,
      programId: programId,
      expectedRevision: 4,
      expectedName: 'Morning',
      mutationId: '77777777-7777-4777-8777-777777777777',
      name: name,
    );

final class _FakeAggregateUpdates implements RoutineAggregateUpdateRepository {
  RoutineAggregateUpdate? command;

  @override
  Future<int> updateAggregate(RoutineAggregateUpdate value) async {
    command = value;
    return value.expectedRevision + 1;
  }
}

final class _FakeRoutineGateway implements RoutineTableGateway {
  List<Map<String, dynamic>> rows = const [];
  int listCalls = 0;
  String? lastUserId;
  String? lastProgramId;
  Map<String, dynamic>? inserted;
  void Function()? onList;

  @override
  Future<List<Map<String, dynamic>>> listRows({
    required String userId,
    required String programId,
  }) async {
    listCalls++;
    lastUserId = userId;
    lastProgramId = programId;
    onList?.call();
    return rows;
  }

  @override
  Future<void> insertRow(Map<String, dynamic> values) async {
    inserted = values;
  }
}
