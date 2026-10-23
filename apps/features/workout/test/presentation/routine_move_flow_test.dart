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
  int creates = 0;
  Future<List<Program>> Function()? onList;

  @override
  Future<List<Program>> list() async {
    reads++;
    return await (onList?.call() ?? Future.value(items));
  }

  @override
  Future<void> create(Program program) async {
    creates++;
    throw UnimplementedError('Move never creates a Program');
  }

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

/// Explicit optional verifier: legacy Move repositories do not implement
/// readback, and must continue showing UNKNOWN without another write.
final class _VerifyingMove extends _Move implements RoutineMoveUnknownVerifier {
  int verifications = 0;
  Future<RoutineMoveReadback> Function()? onVerify;

  @override
  Future<RoutineMoveReadback> verifyUnknown({
    required RoutineId routineId,
    required String mutationId,
  }) async {
    verifications++;
    expect(routineId, routine.id);
    expect(mutationId, token,
        reason: 'Only the current confirmed attempt may be verified');
    return await (onVerify?.call() ?? Future.value(
      const RoutineMoveReadback(kind: RoutineMoveReadbackKind.notConfirmed)));
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
  RoutineCreateMoveCallback? createAndMove,
  bool previewOnly = false,
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
            createAndMove: createAndMove,
            previewOnly: previewOnly,
          )),
          child: const Text('Open Move'),
        ),
      )),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester) async {
  expect(find.text('Select Program'), findsOneWidget);
  await tester.tap(find.byKey(
      ValueKey('routine-move-destination-${destination.id.value}')));
  await tester.pumpAndSettle();
  expect(find.text('Move Routine?'), findsNothing);
}

void main() {

  testWidgets('Select Program opens while verified destination reads are pending',
      (tester) async {
    final header = Completer<RoutineMoveTarget?>();
    final rows = Completer<List<Program>>();
    final move = _Move()..onInspect = () => header.future;
    final programs = _Programs()..onList = () => rows.future;
    var atomicCalls = 0;
    await _pump(tester, flow: RoutineMoveFlow(), move: move,
      programs: programs, canWrite: () => true, onResult: (_) {},
      createAndMove: ({
        required RoutineMoveTarget target,
        required ProgramId newProgramId,
        required String newProgramName,
        required String mutationId,
      }) async {
        atomicCalls++;
        throw StateError('A selector tap must not dispatch a write');
      },
    );

    await tester.tap(find.text('Open Move'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Select Program'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-move-destinations-loading')),
        findsOneWidget,
        reason: 'The sheet should open before the Routine header is fetched');
    expect(find.byKey(const ValueKey('routine-move-new-program')),
        findsNothing);
    expect(programs.reads, 0);
    expect(move.writes, 0);

    header.complete(move.target);
    await tester.pump();
    expect(programs.reads, 1);
    expect(find.byKey(const ValueKey('routine-move-destinations-loading')),
        findsOneWidget,
        reason: 'Owner Program list must also verify before options appear');
    expect(find.byKey(const ValueKey('routine-move-new-program')),
        findsNothing);
    rows.complete([source, destination]);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-move-destinations-loading')),
        findsNothing);
    expect(find.byKey(const ValueKey('routine-move-new-program')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-move-program-divider')),
        findsOneWidget);
    expect(find.byKey(ValueKey(
        'routine-move-destination-${destination.id.value}')), findsOneWidget);
    expect(move.writes, 0);
    expect(atomicCalls, 0);
    Navigator.of(tester.element(find.byKey(
        ValueKey('routine-move-destinations-${routine.id.value}')))).pop();
    await tester.pumpAndSettle();
    expect(move.writes, 0);
  });

  testWidgets('dismissal during slow owner read never revives a stale selector',
      (tester) async {
    final header = Completer<RoutineMoveTarget?>();
    final move = _Move()..onInspect = () => header.future;
    final programs = _Programs();
    bool? needsRefresh;
    await _pump(tester, flow: RoutineMoveFlow(), move: move,
      programs: programs, canWrite: () => true,
      onResult: (v) => needsRefresh = v);
    await tester.tap(find.text('Open Move'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('routine-move-destinations-loading')),
        findsOneWidget);
    Navigator.of(tester.element(find.byKey(
        ValueKey('routine-move-destinations-${routine.id.value}')))).pop();
    await tester.pump();
    header.complete(move.target);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey(
        'routine-move-destination-${destination.id.value}')), findsNothing);
    expect(move.writes, 0);
    expect(needsRefresh, false);
  });




  testWidgets('debug preview existing destination confirms with zero Move writes',
      (tester) async {
    final move = _Move();
    final programs = _Programs();
    bool? needsRefresh;
    await _pump(tester, flow: RoutineMoveFlow(), move: move,
      programs: programs, canWrite: () => true, previewOnly: true,
      onResult: (value) => needsRefresh = value,
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(move.writes, 0);
    expect(programs.creates, 0);
    expect(needsRefresh, false,
        reason: 'Preview must never report a committed Move or request refresh');
    expect(find.text('Preview only · No changes'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-move-confirmed-feedback')),
        findsNothing);
    final preview = tester.widget<SnackBar>(
        find.byKey(const ValueKey('routine-move-preview-feedback')));
    expect(preview.behavior, SnackBarBehavior.floating);
    expect(preview.shape, isA<StadiumBorder>());
    expect(preview.duration, const Duration(seconds: 5));
    expect(preview.persist, isFalse,
        reason: 'Undo must not prevent five-second automatic dismissal');
    expect(preview.action?.label, 'Undo');
    final colors = Theme.of(tester.element(
        find.byKey(const ValueKey('routine-move-preview-feedback'))))
        .colorScheme;
    expect(preview.action?.backgroundColor, colors.onInverseSurface);
    expect(preview.action?.textColor, colors.inverseSurface);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-move-preview-feedback')),
        findsNothing, reason: 'Preview Undo only dismisses its feedback');
    expect(move.writes, 0);
    expect(programs.creates, 0);
  });

  testWidgets('debug preview Create & Move confirms without either write',
      (tester) async {
    final move = _Move();
    final programs = _Programs()..items = [source];
    var atomicCalls = 0;
    bool? needsRefresh;
    await _pump(tester, flow: RoutineMoveFlow(), move: move,
      programs: programs, canWrite: () => true, previewOnly: true,
      onResult: (value) => needsRefresh = value,
      createAndMove: ({
        required RoutineMoveTarget target,
        required ProgramId newProgramId,
        required String newProgramName,
        required String mutationId,
      }) async {
        atomicCalls++;
        throw StateError('Preview must never dispatch Create & Move');
      },
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-move-new-program')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-move-program-divider')),
        findsNothing,
        reason: 'One source Program has no eligible existing destinations');
    await tester.tap(find.byKey(const ValueKey('routine-move-new-program')));
    await tester.pumpAndSettle();
    expect(find.text('Create Program'), findsOneWidget);
    expect(find.widgetWithText(TioButton, 'Save & Move'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('program-create-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Create Program & Move Routine?'), findsNothing);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(atomicCalls, 0);
    expect(move.writes, 0);
    expect(programs.creates, 0);
    expect(needsRefresh, false);
    expect(find.text('Preview only · No changes'),
        findsOneWidget);
    final preview = tester.widget<SnackBar>(
        find.byKey(const ValueKey('routine-move-preview-feedback')));
    expect(preview.behavior, SnackBarBehavior.floating);
    expect(preview.shape, isA<StadiumBorder>());
    expect(preview.duration, const Duration(seconds: 5));
    expect(preview.persist, isFalse);
    expect(preview.action?.label, 'Undo');
    final colors = Theme.of(tester.element(
        find.byKey(const ValueKey('routine-move-preview-feedback'))))
        .colorScheme;
    expect(preview.action?.backgroundColor, colors.onInverseSurface);
    expect(preview.action?.textColor, colors.inverseSurface);
    expect(find.byKey(const ValueKey('routine-move-confirmed-feedback')),
        findsNothing);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-move-preview-feedback')),
        findsNothing, reason: 'Preview pill must auto-dismiss after five seconds');
    expect(atomicCalls, 0);
    expect(move.writes, 0);
  });

  testWidgets('atomic Create & Move retains refresh after auth switch',
      (tester) async {
    final completion = Completer<RoutineMoveResult>();
    final g = _Move();
    var authorized = true;
    bool? needsRefresh;
    var atomicCalls = 0;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs()..items = [source],
      canWrite: () => authorized,
      onResult: (value) => needsRefresh = value,
      createAndMove: ({
        required RoutineMoveTarget target,
        required ProgramId newProgramId,
        required String newProgramName,
        required String mutationId,
      }) {
        atomicCalls++;
        return completion.future;
      },
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-move-new-program')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('program-create-submit')));
    await tester.pumpAndSettle();
    expect(atomicCalls, 1);
    expect(needsRefresh, isNull);
    authorized = false;
    completion.complete(RoutineMoveResult.confirmed);
    await tester.pumpAndSettle();
    expect(needsRefresh, true, reason: 'Dispatched writes need owner-safe refresh');
    expect(find.text('Routine moved.'), findsNothing,
        reason: 'Never show old-owner success after login-cycle change');
    expect(g.writes, 0);
  });

  testWidgets('atomic uncertain result after auth switch still signals refresh',
      (tester) async {
    final completion = Completer<RoutineMoveResult>();
    var authorized = true;
    bool? needsRefresh;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: _Move(), programs: _Programs()..items = [source],
      canWrite: () => authorized,
      onResult: (value) => needsRefresh = value,
      createAndMove: ({
        required RoutineMoveTarget target,
        required ProgramId newProgramId,
        required String newProgramName,
        required String mutationId,
      }) => completion.future,
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-move-new-program')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('program-create-submit')));
    await tester.pumpAndSettle();
    expect(needsRefresh, isNull);
    authorized = false;
    completion.completeError(const RoutineMoveOutcomeUnknown(
      reason: RoutineMoveUncertainty.sessionChanged,
    ));
    await tester.pumpAndSettle();
    expect(needsRefresh, true);
    expect(find.textContaining('unconfirmed'), findsNothing,
        reason: 'Do not show stale-session feedback');
  });

  testWidgets('existing Move retains refresh signal after auth switch',
      (tester) async {
    final completion = Completer<RoutineMoveResult>();
    final g = _Move()..onMove = () => completion.future;
    var authorized = true;
    bool? needsRefresh;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(),
      canWrite: () => authorized,
      onResult: (value) => needsRefresh = value,
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    expect(g.writes, 1);
    expect(needsRefresh, isNull);
    authorized = false;
    completion.complete(RoutineMoveResult.confirmed);
    await tester.pumpAndSettle();
    expect(needsRefresh, true);
    expect(find.text('Routine moved.'), findsNothing);
  });

  testWidgets('New Program first row submits edited canonical name, no pre-create',
      (tester) async {
    final programs = _Programs()..items = [source, destination];
    final moves = _Move();
    var createCalls = 0;
    ProgramId? createdId;
    String? createdName;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: moves, programs: programs, canWrite: () => true,
      onResult: (_) {},
      createAndMove: ({
        required RoutineMoveTarget target,
        required ProgramId newProgramId,
        required String newProgramName,
        required String mutationId,
      }) async {
        createCalls++;
        expect(target.routineId, routine.id);
        expect(newProgramId, isNot(source.id));
        expect(mutationId, token);
        createdId = newProgramId;
        createdName = newProgramName;
        return RoutineMoveResult.confirmed;
      },
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-move-new-program')),
        findsOneWidget);
    expect(find.byKey(ValueKey('routine-move-destination-${destination.id.value}')),
        findsOneWidget);
    expect(find.text('New Program'), findsOneWidget);
    expect(find.text('+ New Program'), findsNothing,
        reason: 'The leading add icon must be the only plus');
    expect(find.byKey(const ValueKey('routine-move-program-divider')),
        findsOneWidget);
    final newOption = tester.widget<ListTile>(
        find.byKey(const ValueKey('routine-move-new-program')));
    expect(newOption.leading, isA<Icon>());
    final newTop = tester.getTopLeft(
      find.byKey(const ValueKey('routine-move-new-program')));
    final oldTop = tester.getTopLeft(
      find.byKey(ValueKey('routine-move-destination-${destination.id.value}')));
    expect(newTop.dy, lessThan(oldTop.dy));

    await tester.tap(find.byKey(const ValueKey('routine-move-new-program')));
    await tester.pumpAndSettle();
    expect(find.text('Create Program'), findsOneWidget);
    final nameField = find.byKey(const ValueKey('program-name-field'));
    expect(nameField, findsOneWidget);
    final editable = find.descendant(
      of: nameField, matching: find.byType(EditableText));
    expect(tester.widget<EditableText>(editable).controller.text, 'Program 1',
        reason: 'Reuse the existing generated default Program name');
    await tester.enterText(editable, 'Cardio Focus');
    await tester.pumpAndSettle();
    expect(moves.writes, 0);
    expect(programs.creates, 0,
        reason: 'The name editor must not create a standalone Program');

    expect(find.widgetWithText(TioButton, 'Save & Move'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('program-create-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Create Program & Move Routine?'), findsNothing);
    expect(createCalls, 1);
    expect(createdId, isNotNull);
    expect(createdName, 'Cardio Focus');
    expect(programs.creates, 0);
    expect(moves.writes, 0);
  });

  testWidgets('source-only selector shows only New Program, cancel writes zero',
      (tester) async {
    final programs = _Programs()..items = [source];
    final moves = _Move();
    var createCalls = 0;
    await _pump(tester, flow: RoutineMoveFlow(), move: moves,
      programs: programs, canWrite: () => true,
      onResult: (_) {},
      createAndMove: ({
        required RoutineMoveTarget target,
        required ProgramId newProgramId,
        required String newProgramName,
        required String mutationId,
      }) async {
        createCalls++;
        return RoutineMoveResult.confirmed;
      },
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-move-new-program')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-move-program-divider')),
        findsNothing);
    expect(find.textContaining('Create another Program'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('routine-move-new-program')));
    await tester.pumpAndSettle();
    expect(find.text('Create Program'), findsOneWidget);
    Navigator.of(tester.element(find.byKey(
        const ValueKey('program-name-field')))).pop();
    await tester.pumpAndSettle();
    expect(createCalls, 0);
    expect(moves.writes, 0);
  });

  testWidgets('cancel Create & Move sheet writes no Program or Move',
      (tester) async {
    final programs = _Programs()..items = [source];
    final moves = _Move();
    var atomicCalls = 0;
    bool? needsRefresh;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: moves,
      programs: programs,
      canWrite: () => true,
      onResult: (value) => needsRefresh = value,
      createAndMove: ({
        required RoutineMoveTarget target,
        required ProgramId newProgramId,
        required String newProgramName,
        required String mutationId,
      }) async {
        atomicCalls++;
        return RoutineMoveResult.confirmed;
      },
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-move-new-program')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('routine-move-new-program')));
    await tester.pumpAndSettle();
    final editable = find.descendant(
      of: find.byKey(const ValueKey('program-name-field')),
      matching: find.byType(EditableText));
    await tester.enterText(editable, 'Evening Training');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TioButton, 'Save & Move'), findsOneWidget);
    Navigator.of(tester.element(find.byKey(
        const ValueKey('program-name-field')))).pop();
    await tester.pumpAndSettle();
    expect(needsRefresh, false);
    expect(atomicCalls, 0,
        reason: 'Sheet cancellation dispatches no atomic RPC');
    expect(programs.creates, 0,
        reason: 'Name-only editor must not persist a phantom Program');
    expect(moves.writes, 0);
    expect(programs.items, [source]);
    expect(find.text('Routine moved.'), findsNothing);
  });

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

  testWidgets('cancel before destination selection dispatches zero writes', (tester) async {
    final g = _Move();
    bool? result;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(), canWrite: () => true,
      onResult: (value) => result = value,
    );
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(find.text('Select Program'), findsOneWidget);
    Navigator.of(tester.element(find.byKey(
      ValueKey('routine-move-destinations-${routine.id.value}'),
    ))).pop();
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

  testWidgets('auth revocation before destination selection denies RPC',
      (tester) async {
    final g = _Move();
    var authorized = true;
    bool? result;
    await _pump(tester, flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(),
      canWrite: () => authorized, onResult: (v) => result = v);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(find.text('Select Program'), findsOneWidget);
    authorized = false;
    await tester.tap(find.byKey(
        ValueKey('routine-move-destination-${destination.id.value}')));
    await tester.pumpAndSettle();
    expect(result, false);
    expect(g.writes, 0);
  });

  testWidgets('destination removed before selection dispatches no RPC',
      (tester) async {
    final moves = _Move();
    final programs = _Programs();
    bool? result;
    await _pump(tester, flow: RoutineMoveFlow(newMutationId: () => token),
      move: moves, programs: programs, canWrite: () => true,
      onResult: (v) => result = v);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    expect(find.text('Select Program'), findsOneWidget);
    programs.items = [source];
    await tester.tap(find.byKey(
        ValueKey('routine-move-destination-${destination.id.value}')));
    await tester.pumpAndSettle();
    expect(programs.reads, 2,
        reason: 'Owner destinations must be re-read after destination selection');
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
    expect(result, true, reason: 'Refresh, not a success ACK');
    expect(g.writes, 1);
    expect(find.textContaining('unconfirmed'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-move-confirmed-feedback')),
        findsNothing);
  });

  testWidgets('UNKNOWN existing Move displays success only after exact receipt',
      (tester) async {
    final g = _VerifyingMove()
      ..onMove = () async {
        throw const RoutineMoveOutcomeUnknown(
          reason: RoutineMoveUncertainty.stillPresent);
      }
      ..onVerify = () async => RoutineMoveReadback(
        kind: RoutineMoveReadbackKind.confirmedLatestMutation,
        observedProgramId: destination.id, observedRevision: 5);
    bool? refresh;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(), canWrite: () => true,
      onResult: (value) => refresh = value);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    expect(refresh, true, reason: 'Readback success is still a refresh request');
    expect(g.writes, 1, reason: 'Never retry the original Move RPC');
    expect(g.verifications, 1);
    expect(find.byKey(const ValueKey('routine-move-confirmed-feedback')),
      findsOneWidget);
    expect(find.text('Move status is unconfirmed. Refresh Programs; do not retry.'),
      findsNothing);
  });

  for (final kind in [
    RoutineMoveReadbackKind.notConfirmed,
    RoutineMoveReadbackKind.superseded,
    RoutineMoveReadbackKind.absentOnRead,
    RoutineMoveReadbackKind.readUnavailable,
  ]) {
    testWidgets('UNKNOWN existing Move ${kind.name} cannot claim success',
        (tester) async {
      final g = _VerifyingMove()
        ..onMove = () async { throw const RoutineMoveOutcomeUnknown(); }
        ..onVerify = () async => RoutineMoveReadback(kind: kind);
      bool? refresh;
      await _pump(tester,
        flow: RoutineMoveFlow(newMutationId: () => token),
        move: g, programs: _Programs(), canWrite: () => true,
        onResult: (value) => refresh = value);
      await tester.tap(find.text('Open Move'));
      await tester.pumpAndSettle();
      await _choose(tester);
      expect(g.writes, 1);
      expect(g.verifications, 1);
      expect(refresh, true);
      expect(find.textContaining('unconfirmed'), findsOneWidget);
      expect(find.byKey(const ValueKey('routine-move-confirmed-feedback')),
        findsNothing);
    });
  }

  testWidgets('UNKNOWN verifier exception cannot replace uncertain outcome',
      (tester) async {
    final g = _VerifyingMove()
      ..onMove = () async { throw const RoutineMoveOutcomeUnknown(); }
      ..onVerify = () async => throw StateError('offline readback');
    bool? refresh;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(), canWrite: () => true,
      onResult: (value) => refresh = value);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    expect(refresh, true);
    expect(g.writes, 1);
    expect(g.verifications, 1);
    expect(find.textContaining('unconfirmed'), findsOneWidget);
    expect(find.textContaining('Try again later'), findsNothing);
  });

  testWidgets('UNKNOWN readback after auth revocation cannot show old success',
      (tester) async {
    final receipt = Completer<RoutineMoveReadback>();
    var allowed = true;
    bool? refresh;
    final g = _VerifyingMove()
      ..onMove = () async { throw const RoutineMoveOutcomeUnknown(); }
      ..onVerify = () => receipt.future;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(), canWrite: () => allowed,
      onResult: (value) => refresh = value);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    await tester.pump();
    await tester.pump();
    expect(g.verifications, 1);
    allowed = false;
    receipt.complete(const RoutineMoveReadback(
      kind: RoutineMoveReadbackKind.confirmedLatestMutation));
    await tester.pumpAndSettle();
    expect(g.writes, 1);
    expect(refresh, true);
    expect(find.text('Routine moved.'), findsNothing);
    expect(find.textContaining('unconfirmed'), findsNothing);
  });

  testWidgets('UNKNOWN atomic Create & Move uses same verifier once',
      (tester) async {
    var atomicWrites = 0;
    bool? refresh;
    final g = _VerifyingMove()
      ..onVerify = () async => const RoutineMoveReadback(
        kind: RoutineMoveReadbackKind.confirmedLatestMutation,
        observedRevision: 5);
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs()..items = [source],
      canWrite: () => true, onResult: (value) => refresh = value,
      createAndMove: ({
        required RoutineMoveTarget target,
        required ProgramId newProgramId,
        required String newProgramName,
        required String mutationId,
      }) async {
        atomicWrites++;
        throw const RoutineMoveOutcomeUnknown();
      });
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-move-new-program')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('program-create-submit')));
    await tester.pumpAndSettle();
    expect(refresh, true);
    expect(atomicWrites, 1);
    expect(g.writes, 0);
    expect(g.verifications, 1);
    expect(find.byKey(const ValueKey('routine-move-confirmed-feedback')),
      findsOneWidget);
  });

  testWidgets('atomic UNKNOWN without exact receipt never claims success',
      (tester) async {
    final programs = _Programs()..items = [source];
    final g = _VerifyingMove()
      ..onVerify = () async => const RoutineMoveReadback(
        kind: RoutineMoveReadbackKind.notConfirmed);
    var atomicWrites = 0;
    bool? refresh;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: programs,
      canWrite: () => true, onResult: (value) => refresh = value,
      createAndMove: ({
        required RoutineMoveTarget target,
        required ProgramId newProgramId,
        required String newProgramName,
        required String mutationId,
      }) async {
        atomicWrites++;
        expect(mutationId, token);
        throw const RoutineMoveOutcomeUnknown();
      });
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-move-new-program')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('program-create-submit')));
    await tester.pumpAndSettle();
    expect(refresh, true, reason: 'UNKNOWN requests an owner-guarded refresh');
    expect(atomicWrites, 1, reason: 'No atomic retry when receipt is missing');
    expect(g.writes, 0, reason: 'No standalone existing-Program Move');
    expect(g.verifications, 1);
    expect(programs.creates, 0, reason: 'No non-atomic Program INSERT');
    expect(find.textContaining('unconfirmed'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-move-confirmed-feedback')),
        findsNothing);
  });

  testWidgets('disposed Move screen suppresses delayed UNKNOWN receipt UI',
      (tester) async {
    final readback = Completer<RoutineMoveReadback>();
    final g = _VerifyingMove()
      ..onMove = () async { throw const RoutineMoveOutcomeUnknown(); }
      ..onVerify = () => readback.future;
    bool? refresh;
    final navigatorKey = GlobalKey<NavigatorState>();
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final flow = RoutineMoveFlow(newMutationId: () => token);
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Builder(builder: (context) => Center(
          child: TextButton(
            onPressed: () async {
              refresh = await flow.run(
                context: context,
                sourceProgram: source,
                routine: routine,
                programs: _Programs(),
                repository: g,
                canWrite: () => true,
              );
            },
            child: const Text('Open Move'),
          ),
        )),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    await tester.pump();
    await tester.pump();
    expect(g.writes, 1);
    expect(g.verifications, 1);
    final originalMessenger = messengerKey.currentState;
    expect(originalMessenger, isNotNull);
    // Dispose ONLY the origin route. A real app-level ScaffoldMessenger and
    // destination Scaffold must remain alive to expose a stale snackbar.
    unawaited(
      navigatorKey.currentState!.pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Destination screen')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Destination screen'), findsOneWidget);
    expect(messengerKey.currentState, same(originalMessenger));
    expect(find.byType(ScaffoldMessenger), findsOneWidget);

    readback.complete(const RoutineMoveReadback(
      kind: RoutineMoveReadbackKind.confirmedLatestMutation));
    await tester.pumpAndSettle();
    expect(refresh, true,
        reason: 'Disposal must not erase the attempt refresh signal');
    expect(g.writes, 1, reason: 'Readback never dispatches a second Move');
    expect(g.verifications, 1);
    expect(find.text('Routine moved.'), findsNothing);
    expect(find.textContaining('unconfirmed'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
    // A positive control verifies the destination route can still render
    // a root-messenger SnackBar; findsNothing above is not vacuous.
    messengerKey.currentState!.showSnackBar(
      const SnackBar(content: Text('Messenger is live')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Messenger is live'), findsOneWidget);
    messengerKey.currentState!.removeCurrentSnackBar();
    await tester.pumpAndSettle();
  });

  testWidgets('debug preview never invokes UNKNOWN verifier or writes',
      (tester) async {
    final g = _VerifyingMove()
      ..onVerify = () async => throw StateError('preview must never read back');
    bool? refresh;
    await _pump(tester,
      flow: RoutineMoveFlow(newMutationId: () => token),
      move: g, programs: _Programs(), canWrite: () => true,
      previewOnly: true, onResult: (value) => refresh = value);
    await tester.tap(find.text('Open Move'));
    await tester.pumpAndSettle();
    await _choose(tester);
    expect(refresh, false);
    expect(g.writes, 0);
    expect(g.verifications, 0);
    expect(find.byKey(const ValueKey('routine-move-preview-feedback')),
      findsOneWidget);
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
    expect(result, true);
    expect(g.writes, 1);
    expect(find.textContaining('changed'), findsOneWidget);
    expect(find.text('Routine moved.'), findsNothing);
  });

  testWidgets('simultaneous requests cannot reopen one Routine inspection',
      (tester) async {
    final inspect = Completer<RoutineMoveTarget?>();
    final g = _Move()..onInspect = () => inspect.future;
    final flow = RoutineMoveFlow();
    final programs = _Programs();
    await _pump(tester, flow: flow, move: g,
      programs: programs, canWrite: () => true, onResult: (_) {});
    await tester.tap(find.text('Open Move'));
    await tester.pump();
    // The first request has already opened a blocking modal. Invoke another
    // request directly, rather than tapping through that modal's barrier.
    final rejected = await flow.run(
      context: tester.element(find.text('Open Move')),
      sourceProgram: source,
      routine: routine,
      programs: programs,
      repository: g,
      canWrite: () => true,
    );
    expect(rejected, false);
    expect(g.reads, 1);
    inspect.complete(null);
    await tester.pumpAndSettle();
    expect(g.writes, 0);
  });
}
