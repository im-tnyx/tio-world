import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

Future<void> _pump(
  WidgetTester tester, {
  Future<void> Function()? onProgramsManagePressed,
  Future<void> Function(Program)? onProgramPressed,
  Future<void> Function(Program)? onAddRoutinePressed,
  Future<void> Function(Program, Routine)? onRoutinePressed,
  RoutineRepository? routineRepository,
  ProgramRepository? programRepository,
  ProgramIdGenerator? programIdGenerator,
  bool withProgramRepository = true,
  VoidCallback? onExercisesPressed,
  VoidCallback? onCreateExercisePressed,
  bool canCreateExercise = true,
  VoidCallback? onSearchPressed,
  TioThemeMode mode = TioThemeMode.light,
}) async {
  final resolvedProgramRepository = withProgramRepository
      ? programRepository ??
          _FakeProgramRepository(
            programs: [_program(1, 'Strength')],
          )
      : null;

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: LibraryPage(
        programRepository: resolvedProgramRepository,
        routineRepository: routineRepository,
        programIdGenerator: programIdGenerator,
        onProgramsManagePressed: onProgramsManagePressed ?? () async {},
        onProgramPressed: onProgramPressed,
        onAddRoutinePressed: onAddRoutinePressed,
        onRoutinePressed: onRoutinePressed,
        onExercisesPressed: onExercisesPressed ?? () {},
        onCreateExercisePressed: onCreateExercisePressed ?? () {},
        canCreateExercise: canCreateExercise,
        onSearchPressed: onSearchPressed ?? () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'shows Library chrome, full category strip and Programs directly by default',
      (tester) async {
    await _pump(tester);

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Library')),
      findsOneWidget,
    );
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byKey(const ValueKey('library-category-strip')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('library-category-clear')), findsNothing);

    expect(
      find.byKey(const ValueKey('library-programs-content')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-programs-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-programs-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-programs-create')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('programs-list')), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.byKey(const ValueKey('library-programs-entry')), findsNothing);
    expect(find.byType(ProgramsPage), findsNothing);

    expect(
      find.byKey(const ValueKey('library-exercises-content')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-custom-exercises-entry')),
      findsNothing,
    );
    expect(find.text('Your Plan'), findsNothing);
    expect(find.text('Routines'), findsNothing);
  });

  testWidgets('inline Program rows are plain and expose collapse state',
      (tester) async {
    await _pump(tester);

    final programs = find.byKey(const ValueKey('library-programs-content'));
    expect(
      find.descendant(of: programs, matching: find.byType(TioGroupCard)),
      findsNothing,
    );

    final row = find.byKey(ValueKey('program-row-${_id(1).value}'));
    final padding = tester.widget<Padding>(
      find.descendant(of: row, matching: find.byType(Padding)).first,
    );
    expect(
      padding.padding,
      const EdgeInsets.symmetric(vertical: TioSpacing.sm),
    );

    final toggle = find.byKey(ValueKey('program-expand-${_id(1).value}'));
    expect(toggle, findsOneWidget);
    expect(
      tester.widget<IconButton>(toggle).tooltip,
      'Collapse Strength',
    );

    await tester.tap(toggle);
    await tester.pump();

    expect(
      tester.widget<IconButton>(toggle).tooltip,
      'Expand Strength',
    );
  });

  testWidgets('Program name has a 48dp action target and the right identity',
      (tester) async {
    Program? selected;
    await _pump(tester, onProgramPressed: (program) async {
      selected = program;
    });

    final target = find.byKey(
      ValueKey('program-open-${_id(1).value}'),
    );
    expect(target, findsOneWidget);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(TioSize.dp48));
    await tester.tap(target);
    await tester.pump();
    expect(selected?.id, _id(1));

    // The existing separate collapse/expand control still owns its action.
    final toggle = find.byKey(ValueKey('program-expand-${_id(1).value}'));
    await tester.tap(toggle);
    await tester.pump();
    expect(
      tester.widget<IconButton>(toggle).tooltip,
      'Expand Strength',
    );
  });

  testWidgets('expanded Programs render only their persisted Routine children',
      (tester) async {
    final repository = _FakeRoutineRepository([
      _routine(1, 101, 'Push'),
      _routine(1, 102, 'Pull'),
      _routine(2, 201, 'Legs'),
    ]);
    await _pump(
      tester,
      programRepository: _FakeProgramRepository(
        programs: [_program(1, 'Strength'), _program(2, 'Cardio')],
      ),
      routineRepository: repository,
    );
    final one = find.byKey(ValueKey('library-routines-${_id(1).value}'));
    final two = find.byKey(ValueKey('library-routines-${_id(2).value}'));
    expect(one, findsOneWidget);
    expect(two, findsOneWidget);
    expect(find.descendant(of: one, matching: find.text('Push')), findsOneWidget);
    expect(find.descendant(of: one, matching: find.text('Pull')), findsOneWidget);
    expect(find.descendant(of: one, matching: find.text('Legs')), findsNothing);
    expect(find.descendant(of: two, matching: find.text('Legs')), findsOneWidget);
    expect(find.descendant(of: one, matching: find.byType(TioCard)),
        findsNWidgets(2));

    // No extra left inset for any persisted Program-owned Routine, including
    // both Programs, matching the Library's existing outer horizontal margin.
    final section = find.byKey(const ValueKey('library-programs-content'));
    final left = tester.getTopLeft(section).dx;
    final right = tester.getTopRight(section).dx;
    final firstCard = find.byKey(
        ValueKey('library-routine-${_id(1).value}-${_routine(1, 101, 'Push').id.value}'));
    final secondCard = find.byKey(
        ValueKey('library-routine-${_id(2).value}-${_routine(2, 201, 'Legs').id.value}'));
    for (final card in [firstCard, secondCard]) {
      expect(tester.getTopLeft(card).dx, closeTo(left, 0.1));
      expect(tester.getTopRight(card).dx, closeTo(right, 0.1));
    }
    for (final container in [one, two]) {
      expect(
        tester.widget<Padding>(container).padding,
        const EdgeInsets.only(bottom: TioSpacing.sm),
      );
    }
    expect(repository.queries, containsAll([_id(1), _id(2)]));

    await tester.tap(find.byKey(ValueKey('program-expand-${_id(1).value}')));
    await tester.pumpAndSettle();
    expect(one, findsNothing);
    expect(two, findsOneWidget);
    await tester.tap(find.byKey(ValueKey('program-expand-${_id(1).value}')));
    await tester.pumpAndSettle();
    expect(one, findsOneWidget);
    expect(find.descendant(of: one, matching: find.text('Push')), findsOneWidget);
  });

  testWidgets('expanded owner Routine invokes Detail navigation without Edit',
      (tester) async {
    final repository = _FakeRoutineRepository([_routine(1, 101, 'Push')]);
    Program? selectedProgram;
    Routine? selectedRoutine;
    await _pump(
      tester,
      routineRepository: repository,
      onRoutinePressed: (program, routine) async {
        selectedProgram = program;
        selectedRoutine = routine;
      },
    );
    final card = find.byKey(ValueKey(
        'library-routine-${_id(1).value}-${_routine(1, 101, 'Push').id.value}'));
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(selectedProgram?.id, _id(1));
    expect(selectedRoutine?.programId, _id(1));
    expect(selectedRoutine?.name, 'Push');
    expect(find.byKey(const ValueKey('routine-name-field')), findsNothing);
  });

  testWidgets('Program Detail return refreshes saved Library Routines',
      (tester) async {
    final repository = _FakeRoutineRepository([_routine(1, 101, 'Push')]);
    await _pump(
      tester,
      routineRepository: repository,
      onProgramPressed: (program) async {
        repository.rows.add(_routine(1, 102, 'New Routine'));
      },
    );
    expect(find.text('New Routine'), findsNothing);
    await tester.tap(find.byKey(ValueKey('program-open-${_id(1).value}')));
    await tester.pumpAndSettle();
    expect(find.text('New Routine'), findsOneWidget);
    expect(repository.queries.where((p) => p == _id(1)).length,
        greaterThanOrEqualTo(2));
  });

  testWidgets('empty Program Add Routine uses its identity and refreshes',
      (tester) async {
    final routines = _FakeRoutineRepository([]);
    ProgramId? target;
    await _pump(
      tester,
      routineRepository: routines,
      onAddRoutinePressed: (program) async {
        target = program.id;
        routines.rows.add(_routine(1, 103, 'New Routine'));
      },
    );

    final add = find.byKey(ValueKey('library-add-routine-${_id(1).value}'));
    expect(add, findsOneWidget);
    expect(find.text('No routines yet'), findsNothing);
    expect(
      find.descendant(of: add, matching: find.text('Add new routine')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: add, matching: find.byIcon(Icons.add_rounded)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: add, matching: find.byType(CustomPaint)),
      findsOneWidget,
    );
    // The dotted card and persisted Routine cards share Library margins.
    final programSection =
        find.byKey(const ValueKey('library-programs-content'));
    final routineContainer =
        find.byKey(ValueKey('library-routines-${_id(1).value}'));
    expect(tester.getTopLeft(add).dx,
        closeTo(tester.getTopLeft(programSection).dx, 0.1));
    expect(tester.getTopLeft(add).dx,
        closeTo(tester.getTopLeft(routineContainer).dx, 0.1));
    expect(tester.getTopRight(add).dx,
        closeTo(tester.getTopRight(routineContainer).dx, 0.1));
    expect(tester.getSize(add).height, lessThanOrEqualTo(TioSize.dp64));
    expect(tester.getSize(add).height, greaterThanOrEqualTo(TioSize.dp48));
    await tester.tap(add);
    await tester.pumpAndSettle();

    expect(target, _id(1));
    expect(find.text('New Routine'), findsOneWidget);
    expect(add, findsNothing, reason: 'Populated Program has no empty Add CTA');
    expect(routines.queries.where((id) => id == _id(1)).length,
        greaterThanOrEqualTo(2));
  });

  testWidgets('empty Add Routine is Program-scoped, hidden when unavailable',
      (tester) async {
    final routines = _FakeRoutineRepository([_routine(2, 201, 'Legs')]);
    await _pump(
      tester,
      programRepository: _FakeProgramRepository(
        programs: [_program(1, 'Strength'), _program(2, 'Cardio')],
      ),
      routineRepository: routines,
      onAddRoutinePressed: (program) async {},
    );
    expect(find.byKey(ValueKey('library-add-routine-${_id(1).value}')),
        findsOneWidget);
    expect(find.byKey(ValueKey('library-add-routine-${_id(2).value}')),
        findsNothing);
    expect(find.text('Legs'), findsOneWidget);

    await _pump(tester, routineRepository: routines);
    expect(find.byKey(ValueKey('library-add-routine-${_id(1).value}')),
        findsNothing);
    expect(find.text('No routines yet'), findsOneWidget);
  });

  testWidgets('dotted Add new routine keeps Core dark theme and remains tappable',
      (tester) async {
    ProgramId? target;
    await _pump(
      tester,
      mode: TioThemeMode.dark,
      routineRepository: _FakeRoutineRepository([]),
      onAddRoutinePressed: (program) async { target = program.id; },
    );
    final action =
        find.byKey(ValueKey('library-add-routine-${_id(1).value}'));
    expect(action, findsOneWidget);
    expect(
      find.descendant(of: action, matching: find.text('Add new routine')),
      findsOneWidget,
    );
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(target, _id(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Program bottom sheet Add Routine reuses selected Program',
      (tester) async {
    final routines = _FakeRoutineRepository([]);
    ProgramId? target;
    await _pump(
      tester,
      routineRepository: routines,
      onAddRoutinePressed: (program) async {
        target = program.id;
      },
    );
    await tester.tap(find.byKey(ValueKey('program-overflow-${_id(1).value}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('program-actions-sheet')), findsOneWidget);
    expect(find.text('Edit Program'), findsOneWidget);
    expect(find.text('Add New Routine'), findsOneWidget);
    expect(find.text('Delete Program'), findsNothing,
        reason: 'No Program Delete lifecycle or permission yet');
    await tester.tap(find.byKey(const ValueKey('program-action-add-routine')));
    await tester.pumpAndSettle();
    expect(target, _id(1));
    expect(find.byKey(const ValueKey('program-actions-sheet')), findsNothing);
  });

  testWidgets('Routine child load error retries without leaking another Program',
      (tester) async {
    final repository = _FakeRoutineRepository([_routine(2, 201, 'Foreign')])
      ..loadFailures = 1;
    await _pump(tester, routineRepository: repository);
    expect(find.text('Could not load routines.'), findsOneWidget);
    expect(find.text('Foreign'), findsNothing);
    await tester.tap(find.byKey(
        ValueKey('library-routines-retry-${_id(1).value}')));
    await tester.pumpAndSettle();
    expect(find.text('No routines yet'), findsOneWidget);

    repository.returnForeign = true;
    await tester.tap(find.byKey(ValueKey('program-expand-${_id(1).value}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('program-expand-${_id(1).value}')));
    await tester.pumpAndSettle();
    expect(find.text('Foreign'), findsNothing);
    expect(find.text('Could not load routines.'), findsOneWidget);
  });

  testWidgets('no Routine repository fails closed under expanded Program',
      (tester) async {
    await _pump(tester);
    expect(find.text('Push'), findsNothing);
    expect(find.byKey(const ValueKey('library-routines-unavailable')),
        findsOneWidget);
  });

  testWidgets('Programs header refreshes inline rows after management returns',
      (tester) async {
    final repository = _FakeProgramRepository(
      programs: [_program(1, 'Strength')],
    );
    var opened = 0;
    await _pump(
      tester,
      programRepository: repository,
      onProgramsManagePressed: () async {
        opened++;
        await repository.create(_program(2, 'Hypertrophy'));
      },
    );

    expect(find.text('Hypertrophy'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('library-programs-header')));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(find.text('Strength'), findsOneWidget);
    expect(find.text('Hypertrophy'), findsOneWidget);
  });

  testWidgets('folder-plus reuses generated-name Create Program flow',
      (tester) async {
    final repository = _FakeProgramRepository();
    await _pump(
      tester,
      programRepository: repository,
      programIdGenerator: _QueueProgramIdGenerator([_id(1)]),
    );

    expect(find.text('No programs yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-programs-create')));
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('program-name-field'));
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editable).controller.text, 'Program 1');

    await tester.enterText(editable, 'Library Strength');
    await tester.tap(find.byKey(const ValueKey('program-create-submit')));
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    expect(repository.created.single.name, 'Library Strength');
    expect(find.text('Library Strength'), findsOneWidget);
    expect(find.byType(ProgramsPage), findsNothing);
  });

  testWidgets('Program name stays non-navigable until W4 detail exists',
      (tester) async {
    await _pump(tester);

    final name = find.text('Strength');
    expect(name, findsOneWidget);
    expect(
      find.ancestor(of: name, matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('Program overflow opens bottom sheet and edits through rename',
      (tester) async {
    final repository = _FakeProgramRepository(
      programs: [_program(1, 'Strength')],
    );
    await _pump(tester, programRepository: repository);

    final overflow =
        find.byKey(ValueKey('program-overflow-${_id(1).value}'));
    expect(overflow, findsOneWidget);

    await tester.tap(overflow);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('program-actions-sheet')),
      findsOneWidget,
    );
    expect(find.text('Edit Program'), findsOneWidget);
    expect(find.text('Open / View Program'), findsNothing);
    expect(find.text('Add New Routine'), findsNothing);
    expect(find.text('Delete Program'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('program-action-edit')));
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('program-edit-name-field'));
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editable).controller.text, 'Strength');

    await tester.enterText(editable, 'Strength Plus');
    await tester.tap(find.byKey(const ValueKey('program-edit-submit')));
    await tester.pumpAndSettle();

    expect(repository.renamed, [(id: _id(1), name: 'Strength Plus')]);
    expect(find.text('Strength Plus'), findsOneWidget);
  });

  testWidgets('ambiguous Program rename reconciles durable state',
      (tester) async {
    final repository = _FakeProgramRepository(
      programs: [_program(1, 'Strength')],
      renameErrorAfterWrite: Exception('response lost'),
    );
    await _pump(tester, programRepository: repository);

    await tester.tap(
      find.byKey(ValueKey('program-overflow-${_id(1).value}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('program-action-edit')));
    await tester.pumpAndSettle();

    final editable = find.descendant(
      of: find.byKey(const ValueKey('program-edit-name-field')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(editable, 'Strength Plus');
    await tester.tap(find.byKey(const ValueKey('program-edit-submit')));
    await tester.pumpAndSettle();

    expect(repository.renamed, [(id: _id(1), name: 'Strength Plus')]);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(find.text('Strength Plus'), findsOneWidget);
  });

  testWidgets('Program actions sheet bounds long Program names',
      (tester) async {
    final longName = List.filled(40, 'VeryLongProgramName').join(' ');
    await _pump(
      tester,
      programRepository: _FakeProgramRepository(
        programs: [_program(1, longName)],
      ),
    );

    await tester.tap(
      find.byKey(ValueKey('program-overflow-${_id(1).value}')),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.byKey(const ValueKey('program-actions-title')),
    );
    expect(title.maxLines, 2);
    expect(title.overflow, TextOverflow.ellipsis);
    expect(find.text('Edit Program'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'missing durable Program repository fails closed but header still manages',
      (tester) async {
    var managed = 0;
    await _pump(
      tester,
      withProgramRepository: false,
      onProgramsManagePressed: () async => managed++,
    );

    expect(find.byKey(const ValueKey('programs-unavailable')), findsOneWidget);
    expect(find.text('Programs are unavailable right now.'), findsOneWidget);
    final create = tester.widget<IconButton>(
      find.byKey(const ValueKey('library-programs-create')),
    );
    expect(create.onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('library-programs-header')));
    await tester.pumpAndSettle();
    expect(managed, 1);
  });

  testWidgets('Exercises selection collapses pills and shows only two actions',
      (tester) async {
    await _pump(tester);

    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-category-clear')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-programs-content')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-exercises-content')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-create-exercise-entry')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('library-exercises-entry')), findsOneWidget);
    expect(find.byType(TioGroupCard), findsNothing);
    expect(
      find.byKey(const ValueKey('library-create-exercise-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-exercises-card')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('library-exercises-content')),
        matching: find.byType(TioCard),
      ),
      findsNWidgets(2),
    );
    expect(find.text('Favorite Exercises'), findsNothing);
    expect(find.text('Custom Exercises'), findsNothing);
    expect(find.byType(ExercisesPage), findsNothing);
  });

  testWidgets(
      'hides Create Exercise when durable user Exercise capability is absent',
      (tester) async {
    await _pump(tester, canCreateExercise: false);

    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('library-create-exercise-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-create-exercise-entry')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-exercises-card')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('library-exercises-content')),
        matching: find.byType(TioCard),
      ),
      findsOneWidget,
    );
    expect(find.byType(TioGroupCard), findsNothing);
  });

  testWidgets('clear restores full strip and inline Programs content',
      (tester) async {
    await _pump(tester);

    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('library-category-clear')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-category-clear')), findsNothing);
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-programs-section')),
      findsOneWidget,
    );
    expect(find.text('Strength'), findsOneWidget);
  });

  testWidgets('explicit Programs selection keeps inline Programs content',
      (tester) async {
    await _pump(tester);

    await tester.tap(
      find.byKey(const ValueKey('library-category-programs')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-category-clear')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-programs-section')),
      findsOneWidget,
    );
    expect(find.text('Strength'), findsOneWidget);
  });

  testWidgets('Exercises actions use separate create and browse handoffs',
      (tester) async {
    var created = 0;
    var browsed = 0;
    await _pump(
      tester,
      onCreateExercisePressed: () => created++,
      onExercisesPressed: () => browsed++,
    );

    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('library-create-exercise-card')),
    );
    await tester.pump();
    expect(created, 1);
    expect(browsed, 0);

    await tester.tap(find.byKey(const ValueKey('library-exercises-card')));
    await tester.pump();
    expect(created, 1);
    expect(browsed, 1);
  });

  testWidgets('the top-bar search icon keeps the existing Exercises search',
      (tester) async {
    var searched = 0;
    await _pump(tester, onSearchPressed: () => searched++);

    final search = find.byKey(const ValueKey('library-search'));
    final button = tester.widget<IconButton>(search);
    expect(button.tooltip, 'Search exercises');

    await tester.tap(search);
    await tester.pump();
    expect(searched, 1);
  });

  for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
    testWidgets('renders category UI on the ${mode.name} theme background',
        (tester) async {
      await _pump(tester, mode: mode);

      final context = tester.element(find.byType(LibraryPage));
      final scaffold = tester.widget<Scaffold>(
        find.byKey(const ValueKey('library-page')),
      );
      expect(scaffold.backgroundColor, context.tioColors.background);
      expect(tester.takeException(), isNull);
    });
  }
}

ProgramId _id(int value) => ProgramId(
      '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}',
    );

Program _program(int value, String name) => Program(id: _id(value), name: name);

final class _QueueProgramIdGenerator implements ProgramIdGenerator {
  _QueueProgramIdGenerator(this.ids);

  final List<ProgramId> ids;
  var index = 0;

  @override
  ProgramId generate(Iterable<ProgramId> existingIds) => ids[index++];
}

final class _FakeProgramRepository implements ProgramRepository {
  _FakeProgramRepository({
    List<Program>? programs,
    this.renameErrorAfterWrite,
  }) : programs = [...?programs];

  final List<Program> programs;
  final List<Program> created = [];
  final List<({ProgramId id, String name})> renamed = [];
  final Object? renameErrorAfterWrite;

  @override
  Future<List<Program>> list() async => List.unmodifiable(programs);

  @override
  Future<void> create(Program program) async {
    created.add(program);
    programs.add(program);
  }

  @override
  Future<void> rename({
    required ProgramId id,
    required String name,
  }) async {
    renamed.add((id: id, name: name));
    final index = programs.indexWhere((program) => program.id == id);
    if (index == -1) throw StateError('Program not found.');
    programs[index] = Program(id: id, name: name);
    final errorAfterWrite = renameErrorAfterWrite;
    if (errorAfterWrite != null) throw errorAfterWrite;
  }
}

Routine _routine(int program, int number, String name) => Routine(
      id: RoutineId(
        '20000000-0000-4000-8000-${number.toString().padLeft(12, '0')}',
      ),
      programId: _id(program),
      name: name,
    );

final class _FakeRoutineRepository implements RoutineRepository {
  _FakeRoutineRepository(this.rows);

  final List<Routine> rows;
  final List<ProgramId> queries = [];
  int loadFailures = 0;
  bool returnForeign = false;

  @override
  Future<List<Routine>> list(ProgramId programId) async {
    queries.add(programId);
    if (loadFailures > 0) {
      loadFailures--;
      throw StateError('temporary failure');
    }
    return List.unmodifiable(
      returnForeign ? rows : rows.where((r) => r.programId == programId),
    );
  }

  @override
  Future<void> create(Routine routine) => throw UnimplementedError();

  @override
  Future<void> rename({required RoutineId id, required String name}) =>
      throw UnimplementedError();
}
