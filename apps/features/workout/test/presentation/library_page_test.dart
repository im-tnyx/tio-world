import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

Future<void> _pump(
  WidgetTester tester, {
  Future<void> Function()? onProgramsManagePressed,
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
        programIdGenerator: programIdGenerator,
        onProgramsManagePressed: onProgramsManagePressed ?? () async {},
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

    final toggle = find.byKey(const ValueKey('program-expand-Strength'));
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

  testWidgets('Program rows stay display-only until W4 detail exists',
      (tester) async {
    await _pump(tester);

    final row = find.byKey(ValueKey('program-row-${_id(1).value}'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('missing durable Program repository fails closed inline',
      (tester) async {
    await _pump(tester, withProgramRepository: false);

    expect(find.byKey(const ValueKey('programs-unavailable')), findsOneWidget);
    expect(find.text('Programs are unavailable right now.'), findsOneWidget);
    final create = tester.widget<IconButton>(
      find.byKey(const ValueKey('library-programs-create')),
    );
    expect(create.onPressed, isNull);
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
  _FakeProgramRepository({List<Program>? programs})
      : programs = [...?programs];

  final List<Program> programs;
  final List<Program> created = [];

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
    throw UnimplementedError();
  }
}
