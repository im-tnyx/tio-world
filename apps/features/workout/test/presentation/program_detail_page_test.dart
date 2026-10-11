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
  Program? selectedProgram,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: ProgramDetailPage(
        program: selectedProgram ?? _program,
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
    expect(find.text('No routines yet. Use + above to add one.'), findsOneWidget);
    expect(find.byKey(const ValueKey('program-routines-empty-create')),
        findsNothing);
    final add = find.byKey(const ValueKey('program-detail-add-routine'));
    expect(find.descendant(of: find.byType(TioAppBar), matching: add),
        findsOneWidget);
    expect(find.text('Add Exercises'), findsNothing);
    expect(find.text('Start Workout'), findsNothing);
  });

  testWidgets('create sheet has generated name, writes owning Program and closes',
      (tester) async {
    final repository = _MemoryRoutines();
    await _pump(tester, repository: repository);
    await tester.tap(
        find.byKey(const ValueKey('program-detail-add-routine')));
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

  testWidgets('create action tracks empty and restored Routine name',
      (tester) async {
    await _pump(tester, repository: _MemoryRoutines());
    await tester.tap(
      find.byKey(const ValueKey('program-detail-add-routine')),
    );
    await tester.pumpAndSettle();

    final field = find.descendant(
      of: find.byKey(const ValueKey('routine-name-field')),
      matching: find.byType(EditableText),
    );
    final button = find.byKey(const ValueKey('routine-name-submit'));

    expect(tester.widget<TioButton>(button).onPressed, isNotNull);
    await tester.enterText(field, '');
    await tester.pump();
    expect(tester.widget<TioButton>(button).onPressed, isNull);
    await tester.enterText(field, 'Upper');
    await tester.pump();
    expect(tester.widget<TioButton>(button).onPressed, isNotNull);
  });

  testWidgets('two saved Routines use separate cards and one top-bar add',
      (tester) async {
    final repository = _MemoryRoutines([
      Routine(id: RoutineId(_routineId), programId: _program.id, name: 'Push'),
      Routine(
        id: RoutineId('20000000-0000-4000-8000-000000000042'),
        programId: _program.id,
        name: 'Pull',
      ),
    ]);
    await _pump(tester, repository: repository);

    final list = find.byKey(const ValueKey('program-routines-list'));
    expect(find.descendant(of: list, matching: find.byType(TioCard)),
        findsNWidgets(2));
    expect(find.descendant(of: list, matching: find.byType(TioGroupCard)),
        findsNothing);
    expect(find.text('Routines'), findsNothing);
    final add = find.byKey(const ValueKey('program-detail-add-routine'));
    expect(add, findsOneWidget);
    expect(find.descendant(of: find.byType(TioAppBar), matching: add),
        findsOneWidget);
    expect(find.byKey(const ValueKey('program-routines-empty-create')),
        findsNothing);
    expect(find.text('Push'), findsOneWidget);
    expect(find.text('Pull'), findsOneWidget);
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
        find.byKey(const ValueKey('program-detail-add-routine')));
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

  testWidgets('long title stays single-line in compact large-text layout',
      (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final name = List.filled(18, 'Long Program').join(' ');
    final program = Program(id: _program.id, name: name);

    await _pump(
      tester,
      repository: _MemoryRoutines(),
      selectedProgram: program,
      textScale: 2,
    );
    final title = find.descendant(
      of: find.byType(TioAppBar),
      matching: find.text(name),
    );
    expect(title, findsOneWidget);
    expect(tester.widget<Text>(title).maxLines, 1);
    expect(tester.widget<Text>(title).overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme retains readable Program and Routine headers',
      (tester) async {
    await _pump(tester, repository: _MemoryRoutines(), mode: TioThemeMode.dark);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Routines'), findsNothing);
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
