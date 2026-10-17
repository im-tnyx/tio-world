import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final source = Program(id: ProgramId('10000000-0000-4000-8000-000000000001'), name: 'Strength');
final target = Program(id: ProgramId('10000000-0000-4000-8000-000000000002'), name: 'Endurance');
final alternate = Program(id: ProgramId('10000000-0000-4000-8000-000000000003'), name: 'Recovery');
final routineId = RoutineId('20000000-0000-4000-8000-000000000001');
const mutationId = '30000000-0000-4000-8000-000000000001';

final class FakePrograms implements ProgramRepository {
  List<Program> rows = [source, target, alternate];
  int reads = 0;
  void Function()? onRead;
  Future<List<Program>> Function()? onList;
  @override
  Future<List<Program>> list() async {
    reads++;
    onRead?.call();
    if (onList != null) return onList!();
    return rows;
  }
  @override
  Future<void> create(Program program) async => rows = [...rows, program];
  @override
  Future<void> rename({required ProgramId id, required String name}) async {}
}

final class FakeMoves implements RoutineMoveRepository {
  int inspections = 0, dispatches = 0;
  ProgramId? destinationId;
  RoutineMoveOutcomeUnknown? unknown;
  @override
  Future<RoutineMoveTarget?> inspect({
    required ProgramId sourceProgramId,
    required RoutineId routineId,
  }) async {
    inspections++;
    return RoutineMoveTarget(
      routineId: routineId,
      sourceProgramId: sourceProgramId,
      name: 'Push',
      expectedRevision: 4,
      ownerId: '11111111-1111-4111-8111-111111111111',
      loginCycleId: 'cycle-a',
    );
  }
  @override
  Future<RoutineMoveResult> move({
    required RoutineMoveTarget target,
    required ProgramId destinationProgramId,
    required String mutationId,
  }) async {
    dispatches++;
    destinationId = destinationProgramId;
    if (unknown != null) throw unknown!;
    return RoutineMoveResult.confirmed;
  }
}

RoutineMoveDestinationController controller(FakePrograms programs, FakeMoves moves,
    bool Function() canWrite) => RoutineMoveDestinationController(
  programs: programs, moves: moves, canWrite: canWrite,
);

Future<RoutineMoveSelection> inspect(RoutineMoveDestinationController c) async =>
    (await c.inspect(sourceProgramId: source.id, routineId: routineId))!;

Future<RoutineMoveResult> confirmed(
    RoutineMoveDestinationController c, RoutineMoveSelection selection,
    ProgramId destination) => c.dispatchConfirmed(
  selection: selection,
  destinationProgramId: destination,
  mutationId: mutationId,
);

void main() {
  test('only existing owner Programs other than source are selectable', () async {
    final c = controller(FakePrograms(), FakeMoves(), () => true);
    final selection = await inspect(c);
    expect(selection.target.expectedRevision, 4);
    expect(selection.destinations.map((p) => p.id), [target.id, alternate.id]);
    expect(selection.destinations.any((p) => p.id == source.id), isFalse);
  });

  test('confirmed destination invokes exactly one protected Move', () async {
    final moves = FakeMoves();
    final programs = FakePrograms();
    final c = controller(programs, moves, () => true);
    final selection = await inspect(c);
    expect(await confirmed(c, selection, target.id), RoutineMoveResult.confirmed);
    expect(moves.dispatches, 1);
    expect(moves.destinationId, target.id);
    await expectLater(confirmed(c, selection, target.id),
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.staleTarget)));
    expect(moves.dispatches, 1);
    expect(programs.reads, 2);
  });

  test('source and unlisted destination fail without RPC', () async {
    final moves = FakeMoves();
    final c = controller(FakePrograms(), moves, () => true);
    final first = await inspect(c);
    await expectLater(confirmed(c, first, source.id),
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.invalidRequest)));
    final second = await inspect(c);
    final unseen = ProgramId('10000000-0000-4000-8000-000000000099');
    await expectLater(confirmed(c, second, unseen),
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.invalidRequest)));
    expect(moves.dispatches, 0);
  });

  test('deleted destination after selection cannot dispatch', () async {
    final moves = FakeMoves();
    final programs = FakePrograms();
    final c = controller(programs, moves, () => true);
    final selection = await inspect(c);
    programs.rows = [source];
    await expectLater(confirmed(c, selection, target.id),
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.staleTarget)));
    expect(moves.dispatches, 0);
  });

  test('abandon during confirmed destination revalidation denies Move',
      () async {
    final pending = Completer<List<Program>>();
    final programs = FakePrograms();
    programs.onList = () => programs.reads == 2
        ? pending.future
        : Future.value(programs.rows);
    final moves = FakeMoves();
    final c = controller(programs, moves, () => true);
    final selection = await inspect(c);
    final dispatch = confirmed(c, selection, target.id);
    expect(programs.reads, 2);
    c.abandon();
    pending.complete([source, target]);
    await expectLater(dispatch,
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.staleTarget)));
    expect(moves.dispatches, 0);
  });

  test('login-cycle lost during owner Program listing blocks inspect', () async {
    var valid = true;
    final moves = FakeMoves();
    final programs = FakePrograms()..onRead = () => valid = false;
    final c = controller(programs, moves, () => valid);
    await expectLater(inspect(c),
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.unauthorized)));
    expect(moves.dispatches, 0);
  });

  test('login-cycle lost during reinspection blocks dispatch', () async {
    var valid = true;
    final moves = FakeMoves();
    final programs = FakePrograms();
    final c = controller(programs, moves, () => valid);
    final selection = await inspect(c);
    programs.onRead = () => valid = false;
    await expectLater(confirmed(c, selection, target.id),
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.unauthorized)));
    expect(moves.dispatches, 0);
  });

  test('duplicate owner Program IDs fail closed', () async {
    final programs = FakePrograms()..rows = [source, target, target];
    final moves = FakeMoves();
    await expectLater(inspect(controller(programs, moves, () => true)),
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.malformedData)));
    expect(moves.dispatches, 0);
  });

  test('new inspection invalidates a prior selector capability', () async {
    final moves = FakeMoves();
    final c = controller(FakePrograms(), moves, () => true);
    final old = await inspect(c);
    final newer = await inspect(c);
    await expectLater(confirmed(c, old, target.id),
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.staleTarget)));
    expect(await confirmed(c, newer, target.id), RoutineMoveResult.confirmed);
    expect(moves.dispatches, 1);
  });

  test('cancel clears prepared target and issues no Move', () async {
    final moves = FakeMoves();
    final c = controller(FakePrograms(), moves, () => true);
    final prepared = await inspect(c);
    c.abandon();
    await expectLater(confirmed(c, prepared, target.id),
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.staleTarget)));
    expect(moves.dispatches, 0);
  });

  test('unknown outcome is never converted to success', () async {
    final moves = FakeMoves()
      ..unknown = const RoutineMoveOutcomeUnknown();
    final c = controller(FakePrograms(), moves, () => true);
    final prepared = await inspect(c);
    await expectLater(confirmed(c, prepared, target.id),
        throwsA(isA<RoutineMoveOutcomeUnknown>()));
    expect(moves.dispatches, 1);
  });

  test('abandon during a pending owner read invalidates its late response',
      () async {
    final pending = Completer<List<Program>>();
    final programs = FakePrograms()..onList = () => pending.future;
    final moves = FakeMoves();
    final c = controller(programs, moves, () => true);
    final inspecting = inspect(c);
    await Future<void>.delayed(Duration.zero);
    expect(programs.reads, 1);
    c.abandon();
    pending.complete([source, target]);
    await expectLater(inspecting,
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.staleTarget)));
    expect(moves.dispatches, 0);
  });

  test('older parallel inspection cannot replace newer destination context',
      () async {
    final pending = Completer<List<Program>>();
    final programs = FakePrograms();
    var calls = 0;
    programs.onList = () {
      calls++;
      if (calls == 1) return pending.future;
      return Future.value([source, target]);
    };
    final moves = FakeMoves();
    final c = controller(programs, moves, () => true);
    final oldInspection = c.inspect(
      sourceProgramId: source.id, routineId: routineId);
    await Future<void>.delayed(Duration.zero);
    expect(programs.reads, 1);
    final secondRoutine = RoutineId('20000000-0000-4000-8000-000000000002');
    final newSelection = (await c.inspect(
      sourceProgramId: source.id, routineId: secondRoutine))!;
    pending.complete([source, target]);
    await expectLater(oldInspection,
        throwsA(isA<RoutineMoveException>()
            .having((e) => e.kind, 'kind', RoutineMoveFailureKind.staleTarget)));
    expect(newSelection.target.routineId, secondRoutine);
    expect(await confirmed(c, newSelection, target.id),
        RoutineMoveResult.confirmed);
    expect(moves.dispatches, 1);
  });
}
