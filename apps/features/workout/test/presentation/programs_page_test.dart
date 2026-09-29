import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

Future<void> _pump(
  WidgetTester tester, {
  required ProgramRepository? repository,
  ProgramIdGenerator? idGenerator,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: ProgramsPage(
        repository: repository,
        idGenerator: idGenerator,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty state and both create affordances', (tester) async {
    final repository = _FakeProgramRepository();
    await _pump(
      tester,
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(1)]),
    );

    expect(find.text('No programs yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('programs-create-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('programs-empty-create')), findsOneWidget);
  });

  testWidgets('create sheet starts generated and persists edited name',
      (tester) async {
    final repository = _FakeProgramRepository();
    await _pump(
      tester,
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(1)]),
    );

    await tester.tap(find.byKey(const ValueKey('programs-create-action')));
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('program-name-field'));
    var editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editable).controller.text, 'Program 1');

    await tester.enterText(editable, 'Strength');
    await tester.tap(find.byKey(const ValueKey('program-create-submit')));
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    expect(repository.created.single.name, 'Strength');
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(find.text('Strength'), findsOneWidget);
  });

  testWidgets('create failure keeps sheet and typed name visible',
      (tester) async {
    final repository = _FakeProgramRepository(
      createError: Exception('write failed'),
    );
    await _pump(
      tester,
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(1)]),
    );

    await tester.tap(find.byKey(const ValueKey('programs-empty-create')));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('program-name-field'));
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    await tester.enterText(editable, 'Strength');

    await tester.tap(find.byKey(const ValueKey('program-create-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsOneWidget);
    expect(
      find.text('Could not create program. Please try again.'),
      findsOneWidget,
    );
    expect(tester.widget<EditableText>(editable).controller.text, 'Strength');
    expect(repository.created, isEmpty);
  });

  testWidgets('load failure retries into the empty state', (tester) async {
    final repository = _FakeProgramRepository(loadFailuresRemaining: 1);
    await _pump(
      tester,
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(1)]),
    );

    expect(find.byKey(const ValueKey('programs-load-failure')), findsOneWidget);
    expect(
      find.text('Could not load programs. Please try again.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('programs-retry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('programs-empty')), findsOneWidget);
  });

  testWidgets('persisted Program rows are display-only', (tester) async {
    final repository = _FakeProgramRepository(
      programs: [_program(1, 'Strength')],
    );
    await _pump(
      tester,
      repository: repository,
      idGenerator: _QueueProgramIdGenerator([_id(2)]),
    );

    final row = find.byKey(ValueKey('program-row-${_id(1).value}'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(
      find.descendant(of: row, matching: find.text('Strength')),
      findsOneWidget,
    );
  });

  testWidgets('missing durable repository fails closed', (tester) async {
    await _pump(tester, repository: null);

    expect(find.byKey(const ValueKey('programs-unavailable')), findsOneWidget);
    expect(find.text('Programs are unavailable right now.'), findsOneWidget);
    final create = tester.widget<IconButton>(
      find.byKey(const ValueKey('programs-create-action')),
    );
    expect(create.onPressed, isNull);
  });
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
    this.loadFailuresRemaining = 0,
    this.createError,
  }) : programs = [...?programs];

  final List<Program> programs;
  final List<Program> created = [];
  int loadFailuresRemaining;
  Object? createError;

  @override
  Future<List<Program>> list() async {
    if (loadFailuresRemaining > 0) {
      loadFailuresRemaining--;
      throw Exception('load failed');
    }
    return List.unmodifiable(programs);
  }

  @override
  Future<void> create(Program program) async {
    final error = createError;
    if (error != null) throw error;
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
