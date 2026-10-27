import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _cycle = 'cycle-a';
final _source = ProgramId('22222222-2222-4222-8222-222222222222');
final _defaultProgram = ProgramId('00000000-0000-4000-8000-000000000000');
final _routineOne = RoutineId('44444444-4444-4444-8444-444444444444');
final _routineTwo = RoutineId('55555555-5555-4555-8555-555555555555');

Program _program({
  ProgramId? id,
  String name = 'Strength Block',
  bool isDefault = false,
}) =>
    Program(
      id: id ?? _source,
      name: name,
      isDefault: isDefault,
    );

RoutineMetadataRevision _snapshot(RoutineId id, {ProgramId? programId}) =>
    RoutineMetadataRevision(
      routine: Routine(
        id: id,
        programId: programId ?? _source,
        name: 'Routine ${id.value}',
      ),
      revision: 1,
      loginCycleId: _cycle,
    );

final class _FakePrograms implements ProgramRepository {
  _FakePrograms(this.items);
  final List<Program> items;
  int reads = 0;

  @override
  Future<List<Program>> list() async {
    reads++;
    return List.unmodifiable(items);
  }

  @override
  Future<void> create(Program program) async {}

  @override
  Future<void> rename({required ProgramId id, required String name}) async {}
}

final class _FakeRoutines implements RoutineVersionedRenameRepository {
  _FakeRoutines(this.snapshots);
  final List<RoutineMetadataRevision> snapshots;
  int reads = 0;

  @override
  String? get activeOwnerId => _owner;

  @override
  String? get activeLoginCycleId => _cycle;

  @override
  Future<List<RoutineMetadataRevision>> listVersioned(
    ProgramId programId,
  ) async {
    reads++;
    return List.unmodifiable(snapshots);
  }

  @override
  Future<int> renameVersioned(
    RoutineAggregateUpdate command, {
    required String expectedLoginCycleId,
  }) =>
      Future.error(UnsupportedError('not used'));
}

final class _FakeDeleteRepo implements ProgramDeleteRepository {
  _FakeDeleteRepo({
    required this.attemptGate,
    this.uncertainty,
    this.failure,
  });

  final ProgramDeleteAttemptGate attemptGate;
  final ProgramDeleteOutcomeUnknown? uncertainty;
  final ProgramDeleteException? failure;
  int writes = 0;

  @override
  Future<ProgramDeleteResult> delete({
    required ProgramDeleteTarget target,
    required String clientMutationId,
  }) async {
    if (!attemptGate.tryStart(
      owner: target.ownerId,
      sourceProgramId: target.sourceProgramId,
      target: target,
      mutationId: clientMutationId,
    )) {
      throw const ProgramDeleteException(ProgramDeleteFailureKind.inProgress);
    }
    writes++;
    try {
      if (uncertainty case final outcome?) {
        attemptGate.markUnknown(target.ownerId, target.sourceProgramId);
        throw outcome;
      }
      if (failure case final outcome?) {
        attemptGate.markDefiniteRejection(
          target.ownerId,
          target.sourceProgramId,
          target,
          clientMutationId,
        );
        throw outcome;
      }
      attemptGate.markCommitted(target.ownerId, target.sourceProgramId);
      return ProgramDeleteResult(
        deletedProgramId: target.sourceProgramId,
        destinationProgramId: _defaultProgram,
        movedRoutineCount: target.expectedRoutineIds.length,
      );
    } finally {
      attemptGate.finish(target.ownerId, target.sourceProgramId);
    }
  }
}

ProgramDeleteController _controller({
  required _FakePrograms programs,
  required _FakeRoutines routines,
  required _FakeDeleteRepo deleteRepository,
  required ProgramDeleteAttemptGate attemptGate,
}) {
  return ProgramDeleteController(
    programs: programs,
    routines: routines,
    deleteRepository: deleteRepository,
    attemptGate: attemptGate,
    pendingCreateGate: RoutinePendingCreateGate(),
    routineOperationGate: RoutineMoveDeleteAttemptGate(),
    refresh: (_) async {},
  );
}

void main() {
  group('programDeleteExplanation', () {
    test('formats explanation based on routine count', () {
      expect(
        programDeleteExplanation(
            programName: 'Hypertrophy', routineCount: null),
        'Delete "Hypertrophy"? Any saved Routines will be moved to My Program. '
        'This cannot be undone.',
      );
      expect(
        programDeleteExplanation(programName: 'Hypertrophy', routineCount: 0),
        'Delete "Hypertrophy"? This Program has no saved Routines. '
        'This cannot be undone.',
      );
      expect(
        programDeleteExplanation(programName: 'Hypertrophy', routineCount: 1),
        'Delete "Hypertrophy"? Its 1 saved Routine will be moved to My Program. '
        'This cannot be undone.',
      );
      expect(
        programDeleteExplanation(programName: 'Hypertrophy', routineCount: 3),
        'Delete "Hypertrophy"? All 3 saved Routines will be moved to My Program. '
        'This cannot be undone.',
      );
    });
  });

  group('showProgramDeleteDialog', () {
    testWidgets('renders centered dialog with compact width and actions', (
      tester,
    ) async {
      bool? confirmed;
      await tester.pumpWidget(MaterialApp(
        home: TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    confirmed = await showProgramDeleteDialog(
                      context: context,
                      programId: _source,
                      programName: 'Cardio Blast',
                      routineCount: 2,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Program?'), findsOneWidget);
      expect(
        find.text(
          'Delete "Cardio Blast"? All 2 saved Routines will be moved to My Program. '
          'This cannot be undone.',
        ),
        findsOneWidget,
      );

      final dialog =
          find.byKey(ValueKey('confirm-delete-program-${_source.value}'));
      expect(dialog, findsOneWidget);

      final card = find.descendant(of: dialog, matching: find.byType(TioCard));
      expect(card, findsOneWidget);
      expect(tester.getSize(card).width, lessThanOrEqualTo(TioSize.dp320));

      final cardCenter = tester.getCenter(card);
      final logicalScreen =
          tester.view.physicalSize / tester.view.devicePixelRatio;
      expect((cardCenter.dx - logicalScreen.width / 2).abs(), lessThan(1));
      expect((cardCenter.dy - logicalScreen.height / 2).abs(), lessThan(1));

      // Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);
    });

    testWidgets('delete button returns true', (tester) async {
      bool? confirmed;
      await tester.pumpWidget(MaterialApp(
        home: TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    confirmed = await showProgramDeleteDialog(
                      context: context,
                      programId: _source,
                      programName: 'Cardio Blast',
                      routineCount: 0,
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Delete "Cardio Blast"? This Program has no saved Routines. '
          'This cannot be undone.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });
  });

  group('ProgramDeleteFlow', () {
    Future<void> pumpFlow(
      WidgetTester tester, {
      required Program program,
      required ProgramDeleteController controller,
      required ProgramDeleteFlow flow,
      required void Function(bool) onResult,
      bool Function()? canWrite,
      Widget Function(BuildContext, Widget)? confirmationGuard,
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    final result = await flow.run(
                      context: context,
                      program: program,
                      controller: controller,
                      canWrite: canWrite ?? () => true,
                      confirmationGuard: confirmationGuard,
                    );
                    onResult(result);
                  },
                  child: const Text('Trigger Delete'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('default Program cannot be deleted and shows feedback', (
      tester,
    ) async {
      final defaultProg = _program(id: _defaultProgram, isDefault: true);
      final gate = ProgramDeleteAttemptGate();
      final programs = _FakePrograms([defaultProg]);
      final routines = _FakeRoutines([]);
      final deleteRepo = _FakeDeleteRepo(attemptGate: gate);
      final controller = _controller(
        programs: programs,
        routines: routines,
        deleteRepository: deleteRepo,
        attemptGate: gate,
      );
      addTearDown(controller.dispose);

      bool? result;
      final flow = ProgramDeleteFlow();
      await pumpFlow(
        tester,
        program: defaultProg,
        controller: controller,
        flow: flow,
        onResult: (r) => result = r,
      );

      await tester.tap(find.text('Trigger Delete'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(Dialog), findsNothing);
      expect(
          find.text('The default Program cannot be deleted.'), findsOneWidget);
      expect(programs.reads, 0);
      expect(deleteRepo.writes, 0);
    });

    testWidgets('cancel after preparation dismisses dialog and never deletes', (
      tester,
    ) async {
      final prog = _program();
      final gate = ProgramDeleteAttemptGate();
      final programs = _FakePrograms([prog]);
      final routines = _FakeRoutines([
        _snapshot(_routineOne),
        _snapshot(_routineTwo),
      ]);
      final deleteRepo = _FakeDeleteRepo(attemptGate: gate);
      final controller = _controller(
        programs: programs,
        routines: routines,
        deleteRepository: deleteRepo,
        attemptGate: gate,
      );
      addTearDown(controller.dispose);

      bool? result;
      final flow = ProgramDeleteFlow();
      await pumpFlow(
        tester,
        program: prog,
        controller: controller,
        flow: flow,
        onResult: (r) => result = r,
      );

      await tester.tap(find.text('Trigger Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(
        find.text(
          'Delete "Strength Block"? All 2 saved Routines will be moved to My Program. '
          'This cannot be undone.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(Dialog), findsNothing);
      expect(deleteRepo.writes, 0);
    });

    testWidgets('confirm deletes and shows confirmed floating SnackBar', (
      tester,
    ) async {
      final prog = _program();
      final gate = ProgramDeleteAttemptGate();
      final programs = _FakePrograms([prog]);
      final routines = _FakeRoutines([_snapshot(_routineOne)]);
      final deleteRepo = _FakeDeleteRepo(attemptGate: gate);
      final controller = _controller(
        programs: programs,
        routines: routines,
        deleteRepository: deleteRepo,
        attemptGate: gate,
      );
      addTearDown(controller.dispose);

      bool? result;
      final flow = ProgramDeleteFlow(
        newMutationId: () => '11111111-2222-4333-8444-555555555555',
      );
      await pumpFlow(
        tester,
        program: prog,
        controller: controller,
        flow: flow,
        onResult: (r) => result = r,
      );

      await tester.tap(find.text('Trigger Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Delete "Strength Block"? Its 1 saved Routine will be moved to My Program. '
          'This cannot be undone.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(deleteRepo.writes, 1);
      expect(find.text('Program deleted.'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(
        find.byKey(const ValueKey('program-delete-confirmed-feedback')),
      );
      expect(snackBar.duration, const Duration(seconds: 5));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.shape, isA<StadiumBorder>());
      expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);
    });

    testWidgets('unknown outcome asks for refresh without false success', (
      tester,
    ) async {
      final prog = _program();
      final gate = ProgramDeleteAttemptGate();
      final programs = _FakePrograms([prog]);
      final routines = _FakeRoutines([]);
      final deleteRepo = _FakeDeleteRepo(
        attemptGate: gate,
        uncertainty: const ProgramDeleteOutcomeUnknown(
          reason: ProgramDeleteUncertainty.unconfirmed,
        ),
      );
      final controller = _controller(
        programs: programs,
        routines: routines,
        deleteRepository: deleteRepo,
        attemptGate: gate,
      );
      addTearDown(controller.dispose);

      bool? result;
      final flow = ProgramDeleteFlow();
      await pumpFlow(
        tester,
        program: prog,
        controller: controller,
        flow: flow,
        onResult: (r) => result = r,
      );

      await tester.tap(find.text('Trigger Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(deleteRepo.writes, 1);
      expect(
        find.text(
          'Delete status is unconfirmed. Checking your Programs; do not retry.',
        ),
        findsOneWidget,
      );
      expect(find.text('Program deleted.'), findsNothing);
    });

    testWidgets('rejection shows appropriate error feedback', (tester) async {
      final prog = _program();
      final gate = ProgramDeleteAttemptGate();
      final programs = _FakePrograms([prog]);
      final routines = _FakeRoutines([]);
      final deleteRepo = _FakeDeleteRepo(
        attemptGate: gate,
        failure: const ProgramDeleteException(
          ProgramDeleteFailureKind.staleMembership,
        ),
      );
      final controller = _controller(
        programs: programs,
        routines: routines,
        deleteRepository: deleteRepo,
        attemptGate: gate,
      );
      addTearDown(controller.dispose);

      bool? result;
      final flow = ProgramDeleteFlow();
      await pumpFlow(
        tester,
        program: prog,
        controller: controller,
        flow: flow,
        onResult: (r) => result = r,
      );

      await tester.tap(find.text('Trigger Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue); // attempted write occurred
      expect(deleteRepo.writes, 1);
      expect(
        find.text(
            'This Program changed. Refresh the list before trying again.'),
        findsOneWidget,
      );
      expect(find.text('Program deleted.'), findsNothing);
    });

    testWidgets('cannot run when canWrite is false', (tester) async {
      final prog = _program();
      final gate = ProgramDeleteAttemptGate();
      final programs = _FakePrograms([prog]);
      final routines = _FakeRoutines([]);
      final deleteRepo = _FakeDeleteRepo(attemptGate: gate);
      final controller = _controller(
        programs: programs,
        routines: routines,
        deleteRepository: deleteRepo,
        attemptGate: gate,
      );
      addTearDown(controller.dispose);

      bool? result;
      final flow = ProgramDeleteFlow();
      await pumpFlow(
        tester,
        program: prog,
        controller: controller,
        flow: flow,
        canWrite: () => false,
        onResult: (r) => result = r,
      );

      await tester.tap(find.text('Trigger Delete'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(Dialog), findsNothing);
      expect(programs.reads, 0);
      expect(deleteRepo.writes, 0);
    });

    testWidgets('concurrent run calls cannot open second inspection', (
      tester,
    ) async {
      final prog = _program();
      final gate = ProgramDeleteAttemptGate();
      final programs = _FakePrograms([prog]);
      final routines = _FakeRoutines([]);
      final deleteRepo = _FakeDeleteRepo(attemptGate: gate);
      final controller = _controller(
        programs: programs,
        routines: routines,
        deleteRepository: deleteRepo,
        attemptGate: gate,
      );
      addTearDown(controller.dispose);

      final flow = ProgramDeleteFlow();
      await pumpFlow(
        tester,
        program: prog,
        controller: controller,
        flow: flow,
        onResult: (_) {},
      );

      await tester.tap(find.text('Trigger Delete'));
      await tester.pump();
      await tester.tap(find.text('Trigger Delete'), warnIfMissed: false);
      await tester.pump();

      expect(programs.reads, 1);
      expect(deleteRepo.writes, 0);
    });
  });
}
