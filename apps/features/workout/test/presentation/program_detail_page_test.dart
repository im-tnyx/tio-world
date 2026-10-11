import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _programId = '10000000-0000-4000-8000-000000000001';
const _routineId = '20000000-0000-4000-8000-000000000041';

Program get _program => Program(id: ProgramId(_programId), name: 'Strength');

Future<void> _pump(
  WidgetTester tester, {
  required RoutineRepository? repository,
  TioThemeMode mode = TioThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: ProgramDetailPage(
        program: _program,
        routineRepository: repository,
        newRoutineUuid: () => _routineId,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty Program shows real Routine creation, no builder action',
      (tester) async {
    final repository = _MemoryRoutines();
    await _pump(tester, repository: repository);

    expect(find.byKey(const ValueKey('program-detail-page')), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.byKey(const ValueKey('program-routines-empty')), findsOneWidget);
    expect(find.text('No routines yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('program-routines-empty-create')),
        findsOneWidget);
    expect(find.text('Add Exercises'), findsNothing);
    expect(find.text('Start Workout'), findsNothing);
  });

  testWidgets('create sheet has generated name, writes owning Program and closes',
      (tester) async {
    final repository = _MemoryRoutines();
    await _pump(tester, repository: repository);
    await tester.tap(
        find.byKey(const ValueKey('program-routines-empty-create')));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('routine-name-field'));
    final editable =
        find.descendant(of: field, matching: find.byType(EditableText));
    expect(tester.widget<EditableText>(editable).controller.text, 'Routine 1');

    await tester.enterText(editable, 'Upper Body');
    await tester.tap(find.byKey(const ValueKey('routine-name-submit')));
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    expect(repository.created.single.programId, _program.id);
    expect(repository.created.single.id, RoutineId(_routineId));
    expect(repository.created.single.name, 'Upper Body');
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(find.text('Upper Body'), findsOneWidget);
  });

  testWidgets('persisted Routine row opens only its real rename editor',
      (tester) async {
    final repository = _MemoryRoutines([
      Routine(id: RoutineId(_routineId), programId: _program.id, name: 'Push'),
    ]);
    await _pump(tester, repository: repository);
    await tester.tap(find.byKey(const ValueKey('program-routine-$_routineId')));
    await tester.pumpAndSettle();

    expect(find.text('Edit Routine'), findsOneWidget);
    final editable = find.descendant(
      of: find.byKey(const ValueKey('routine-name-field')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(editable, 'Push A');
    await tester.tap(find.byKey(const ValueKey('routine-name-submit')));
    await tester.pumpAndSettle();

    expect(repository.rows.single.name, 'Push A');
    expect(find.text('Push A'), findsOneWidget);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
  });

  testWidgets('create failure retains name and editor', (tester) async {
    final repository = _MemoryRoutines()..failCreate = true;
    await _pump(tester, repository: repository);
    await tester.tap(
        find.byKey(const ValueKey('program-routines-empty-create')));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('routine-name-field'));
    final editable =
        find.descendant(of: field, matching: find.byType(EditableText));
    await tester.enterText(editable, 'Day One');
    await tester.tap(find.byKey(const ValueKey('routine-name-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsOneWidget);
    expect(tester.widget<EditableText>(editable).controller.text, 'Day One');
    expect(find.text('Could not create routine. Please try again.'),
        findsOneWidget);
    expect(repository.rows, isEmpty);
  });

  testWidgets('load error exposes retry without inventing Routine data',
      (tester) async {
    final repository = _MemoryRoutines()..loadFailures = 1;
    await _pump(tester, repository: repository);

    expect(find.byKey(const ValueKey('program-routines-load-failed')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('program-routines-list')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('program-routines-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('program-routines-empty')),
        findsOneWidget);
  });

  testWidgets('missing durable repository fails closed', (tester) async {
    await _pump(tester, repository: null);
    expect(find.byKey(const ValueKey('program-routines-unavailable')),
        findsOneWidget);
    final create = tester.widget<IconButton>(
        find.byKey(const ValueKey('program-detail-add-routine')));
    expect(create.onPressed, isNull);
    expect(find.byKey(const ValueKey('routine-name-submit')), findsNothing);
  });

  testWidgets('dark theme retains readable Program and Routine headers',
      (tester) async {
    await _pump(tester, repository: _MemoryRoutines(), mode: TioThemeMode.dark);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Routines'), findsOneWidget);
  });
}

final class _MemoryRoutines implements RoutineRepository {
  _MemoryRoutines([List<Routine> initial = const []]) : rows = [...initial];

  final List<Routine> rows;
  final List<Routine> created = [];
  bool failCreate = false;
  int loadFailures = 0;

  @override
  Future<List<Routine>> list(ProgramId programId) async {
    if (loadFailures > 0) {
      loadFailures--;
      throw Exception('disconnected');
    }
    return List.unmodifiable(
        rows.where((routine) => routine.programId == programId));
  }

  @override
  Future<void> create(Routine routine) async {
    if (failCreate) throw Exception('disconnected');
    created.add(routine);
    rows.add(routine);
  }

  @override
  Future<void> rename({required RoutineId id, required String name}) async {
    final i = rows.indexWhere((routine) => routine.id == id);
    if (i == -1) throw StateError('Missing Routine');
    rows[i] = Routine(id: id, programId: rows[i].programId, name: name);
  }
}
