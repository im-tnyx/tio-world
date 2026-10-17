import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final source = Program(
  id: ProgramId('10000000-0000-4000-8000-000000000001'),
  name: 'Strength',
);
final destination = Program(
  id: ProgramId('10000000-0000-4000-8000-000000000002'),
  name: 'Mobility',
);
final routine = Routine(
  id: RoutineId('20000000-0000-4000-8000-000000000001'),
  programId: source.id,
  name: 'Morning',
);
const token = '50000000-0000-4000-8000-000000000001';

final class _Programs implements ProgramRepository {
  List<Program> items = [source, destination];
  int reads = 0;
  Future<List<Program>> Function()? onList;

  @override
  Future<List<Program>> list() async {
    reads++;
    return await (onList?.call() ?? Future.value(items));
  }

  @override
  Future<void> create(Program program) async =>
      throw UnimplementedError('Move never creates a Program');

  @override
  Future<void> rename({required ProgramId id, required String name}) async =>
      throw UnimplementedError('Move never renames a Program');
}

final class _Move implements RoutineMoveRepository {
  int reads = 0;
  int writes = 0;
  RoutineMoveTarget? target = RoutineMoveTarget(
    routineId: routine.id, sourceProgramId: source.id,
    name: routine.name, expectedRevision: 4,
    ownerId: 'owner-a', loginCycleId: 'cycle-a',
  );
  Future<RoutineMoveTarget?> Function()? onInspect;
  Future<RoutineMoveResult> Function()? onMove;
  ProgramId? chosenDestination;
  String? mutationId;
  RoutineMoveTarget? passedTarget;

  @override
  Future<RoutineMoveTarget?> inspect({
    required ProgramId sourceProgramId,
    required RoutineId routineId,
  }) async {
    reads++;
    expect(sourceProgramId, source.id);
    expect(routineId, routine.id);
    return await (onInspect?.call() ?? Future.value(target));
  }

  @override
  Future<RoutineMoveResult> move({
    required RoutineMoveTarget target,
    required ProgramId destinationProgramId,
    required String mutationId,
  }) async {
    writes++;
    passedTarget = target;
    chosenDestination = destinationProgramId;
    this.mutationId = mutationId;
    return await (onMove?.call() ?? Future.value(RoutineMoveResult.confirmed));
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required RoutineMoveFlow flow,
  required _Move move,
  required _Programs programs,
  required bool Function() canWrite,
  required void Function(bool) onResult,
  Routine? selectedRoutine,
}) async {
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => TioTheme(
      config: const TioThemeConfig(mode: TioThemeMode.light),
      child: child ?? const SizedBox.shrink(),
    ),
    home: Scaffold(
      body: Builder(builder: (context) => Center(
        child: TextButton(
          onPressed: () async => onResult(await flow.run(
            context: context,
            sourceProgram: source,
            routine: selectedRoutine ?? routine,
            programs: programs,
            repository: move,
            canWrite: canWrite,
          )),
          child: const Text('Open Move'),
        ),
      )),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester) async {
  expect(find.text('Move Routine'), findsOneWidget);
  await tester.tap(find.byKey(
      ValueKey('routine-move-destination-${destination.id.value}')));
  await tester.pumpAndSettle();
  expect(find.text('Move Routine?'), findsOneWidget);
  expect(find.textContaining('Morning'), findsOneWidget);
  expect(find.textContaining('Mobility'), findsOneWidget);
}

void main() {
  testWidgets('selection and confirmation use one existing owner Program RPC',
      (tester) async {
    final programs = _Programs();
    final gateway = _Move();
    bool? result;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: gateway, programs: programs, canWrite: () => true,
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(programs.reads, 1);
    expect(gateway.reads, 1);
    expect(gateway.writes, 0);
    expect(find.text('Strength'), findsNothing,
      reason: 'Current Program cannot be a Move destination');
    await _choose(tester);
    expect(gateway.writes, 0);
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(gateway.writes, 1);
    expect(gateway.chosenDestination, destination.id);
    expect(gateway.mutationId, token);
    expect(gateway.passedTarget, same(gateway.target));
    expect(find.byKey(const ValueKey('routine-move-confirmed-feedback')),
        findsOneWidget);
  });

  testWidgets('dismiss selector is read-only', (tester) async {
    final g = _Move();
    bool? result;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(), canWrite: () => true,
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byKey(
      ValueKey('routine-move-destinations-${routine.id.value}'),
    ))).pop();
    await tester.pumpAndSettle();
    expect(result, false);
    expect(g.writes, 0);
  });

  testWidgets('cancel confirmation does not dispatch', (tester) async {
    final g = _Move();
    bool? result;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(), canWrite: () => true,
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, false);
    expect(g.writes, 0);
  });

  testWidgets('signed-out, stale source and missing owner target deny flow',
      (tester) async {
    final g = _Move();
    final programs = _Programs();
    var allowed = false;
    await _pump(tester,
      flow: RoutineMoveFlow(), move: g, programs: programs,
      canWrite: () => allowed, onResult: (_) {},
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(g.reads, 0);
    allowed = true;
    g.target = null;
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(g.reads, 1);
    expect(programs.reads, 0);
    expect(g.writes, 0);
  });

  testWidgets('no destination and duplicate Program IDs fail closed',
      (tester) async {
    final g = _Move();
    final programs = _Programs()..items = [source];
    await _pump(tester, flow: RoutineMoveFlow(), move: g,
      programs: programs, canWrite: () => true, onResult: (_) {});
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Create another Program'), findsOneWidget);
    expect(g.writes, 0);
    programs.items = [source, destination, destination];
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not verify Programs'), findsOneWidget);
    expect(g.writes, 0);
  });

  testWidgets('auth revocation between selection and confirmation denies RPC',
      (tester) async {
    final g = _Move();
    var authorized = true;
    bool? result;
    await _pump(tester, flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(),
      canWrite: () => authorized, onResult: (v) => result = v);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    authorized = false;
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(result, false);
    expect(g.writes, 0);
  });

  testWidgets('destination removed during confirmation dispatches no RPC',
      (tester) async {
    final moves = _Move();
    final programs = _Programs();
    bool? result;
    await _pump(tester, flow: RoutineMoveFlow(newMutationId: () => token),
      move: moves, programs: programs, canWrite: () => true,
      onResult: (v) => result = v);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    programs.items = [source];
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(programs.reads, 2,
        reason: 'Owner destinations must be re-read after confirmation');
    expect(moves.writes, 0);
    expect(result, true, reason: 'A stale selection requests refresh');
    expect(find.textContaining('changed'), findsOneWidget);
    expect(find.text('Routine moved.'), findsNothing);
  });

  testWidgets('unknown result requests refresh without claiming success',
      (tester) async {
    final g = _Move()
      ..onMove = () async => throw const RoutineMoveOutcomeUnknown(
        reason: RoutineMoveUncertainty.stillPresent,
      );
    bool? result;
    await _pump(tester, flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(), canWrite: () => true,
      onResult: (v) => result = v);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(result, true, reason: 'Refresh, not a success ACK');
    expect(g.writes, 1);
    expect(find.textContaining('unconfirmed'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-move-confirmed-feedback')),
        findsNothing);
  });

  testWidgets('revision conflict remains a rejected Move requiring refresh',
      (tester) async {
    final g = _Move()
      ..onMove = () async => throw const RoutineMoveException(
        RoutineMoveFailureKind.revisionConflict);
    bool? result;
    await _pump(tester, flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(), canWrite: () => true,
      onResult: (v) => result = v);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    expect(result, true);
    expect(g.writes, 1);
    expect(find.textContaining('changed'), findsOneWidget);
    expect(find.text('Routine moved.'), findsNothing);
  });

  testWidgets('simultaneous taps cannot reopen one Routine inspection',
      (tester) async {
    final inspect = Completer<RoutineMoveTarget?>();
    final g = _Move()..onInspect = () => inspect.future;
    await _pump(tester, flow: RoutineMoveFlow(), move: g,
      programs: _Programs(), canWrite: () => true, onResult: (_) {});
    await tester.tap(find.text('Open Move'));
    await tester.pump();
    await tester.tap(find.text('Open Move'));
    await tester.pump();
    expect(g.reads, 1);
    inspect.complete(null);
    await tester.pumpAndSettle();
    expect(g.writes, 0);
  });
}
