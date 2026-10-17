import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final _program = Program(
  id: ProgramId('10000000-0000-4000-8000-000000000001'), name: 'Strength',
);
final _routine = Routine(
  id: RoutineId('20000000-0000-4000-8000-000000000041'),
  programId: _program.id, name: 'Push',
);

final class _DeleteRepo implements RoutineDeleteRepository {
  int reads = 0;
  int writes = 0;
  bool absent = false;
  Future<RoutineDeleteTarget?> Function()? onInspect;
  RoutineDeleteOutcomeUnknown? uncertainty;
  @override
  Future<RoutineDeleteTarget?> inspect({
    required ProgramId programId, required RoutineId routineId,
  }) async {
    reads++;
    if (onInspect != null) return onInspect!();
    if (absent) return null;
    return RoutineDeleteTarget(
      routineId: routineId, programId: programId, name: 'Push',
      expectedRevision: 2, ownerId: 'owner-a', loginCycleId: 'cycle-a',
    );
  }

  @override
  Future<RoutineDeleteResult> delete(RoutineDeleteTarget target) async {
    writes++;
    if (uncertainty case final outcome?) throw outcome;
    return RoutineDeleteResult.confirmed;
  }
}

void main() {
  Future<void> pumpFlow(WidgetTester tester, _DeleteRepo repository,
      RoutineDeleteFlow flow, bool Function() canWrite,
      void Function(bool) onResult) async {
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: Builder(builder: (context) => Center(
        child: TextButton(
          onPressed: () async => onResult(await flow.run(
            context: context, program: _program, routine: _routine,
            repository: repository, canWrite: canWrite,
          )),
          child: const Text('Open Delete'),
        ),
      ))),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('concurrent Delete taps cannot issue a second inspection',
      (tester) async {
    final pendingRead = Completer<RoutineDeleteTarget?>();
    final repository = _DeleteRepo()
      ..onInspect = () => pendingRead.future;
    final flow = RoutineDeleteFlow();
    await pumpFlow(tester, repository, flow, () => true, (_) {});
    await tester.tap(find.text('Open Delete'));
    await tester.pump();
    await tester.tap(find.text('Open Delete'));
    await tester.pump();
    expect(repository.reads, 1);
    expect(repository.writes, 0);
    pendingRead.complete(null);
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
  });
  testWidgets('cancel after fresh inspection never dispatches Delete',
      (tester) async {
    final repository = _DeleteRepo();
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => true,
        (result) => returned = result);
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Routine?'), findsOneWidget);
    expect(find.textContaining('Push'), findsOneWidget);
    expect(repository.reads, 1);
    expect(repository.writes, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(returned, false);
    expect(repository.writes, 0);
  });

  testWidgets('only explicit confirmation dispatches once and refreshes',
      (tester) async {
    final repository = _DeleteRepo();
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => true,
        (result) => returned = result);
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    await tester.tap(find.text('Delete Routine', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(repository.reads, 1);
    expect(repository.writes, 1);
    expect(returned, true);
    expect(find.text('Routine deleted.'), findsOneWidget);
  });

  testWidgets('unknown result asks for refresh without claiming deletion',
      (tester) async {
    final repository = _DeleteRepo()
      ..uncertainty = const RoutineDeleteOutcomeUnknown(
        reason: RoutineDeleteUncertainty.stillPresent,
      );
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => true,
        (result) => returned = result);
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Routine', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(repository.writes, 1);
    expect(returned, true);
    expect(find.textContaining('unconfirmed'), findsOneWidget);
    expect(find.text('Routine deleted.'), findsNothing);
  });

  testWidgets('login-cycle revocation before confirm sends zero RPCs',
      (tester) async {
    final repository = _DeleteRepo();
    var valid = true;
    bool? returned;
    await pumpFlow(tester, repository, RoutineDeleteFlow(), () => valid,
        (result) => returned = result);
    await tester.tap(find.text('Open Delete'));
    await tester.pumpAndSettle();
    valid = false;
    await tester.tap(find.text('Delete Routine', skipOffstage: false));
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    expect(returned, false);
  });
}
