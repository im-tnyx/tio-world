import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _owner = '11111111-1111-4111-8111-111111111111';
const _routine = '22222222-2222-4222-8222-222222222222';
const _noteId = '33333333-3333-4333-8333-333333333333';
const _exercise = 'ex_barbell_bench_press';

RoutineNote _note({
  String id = _noteId,
  RoutineNoteScope? scope,
  String body = 'Keep shoulders down',
  int revision = 1,
}) {
  final date = DateTime.utc(2026, 11, 1);
  return RoutineNote(
    id: id,
    userId: _owner,
    scope: scope ?? RoutineNoteScope.exercise(ExerciseRef.catalog(_exercise)),
    body: body,
    createdAt: date,
    updatedAt: date,
    revision: revision,
  );
}

Future<void> _pump(
  WidgetTester tester,
  _FakeRoutineNotesRepository repository, {
  RoutineId? routineId,
  Widget restControl = const SizedBox(key: ValueKey('rest-control')),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ExerciseNotesInline(
            exerciseRef: ExerciseRef.catalog(_exercise),
            routineId: routineId,
            restControl: restControl,
            repository: repository,
            ownerId: _owner,
            isSessionCurrent: () => true,
            enabled: true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPreview(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: ExerciseNotesInline(
          exerciseRef: ExerciseRef.catalog(_exercise),
          routineId: null,
          restControl: const SizedBox(key: ValueKey('rest-control')),
          repository: null,
          ownerId: null,
          isSessionCurrent: null,
          enabled: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Note stays on the right of Rest in the action row',
      (tester) async {
    await _pump(
      tester,
      _FakeRoutineNotesRepository(),
      restControl: const SizedBox(
        key: ValueKey('rest-control'),
        width: 140,
        height: 31,
      ),
    );

    final rest = tester.getRect(find.byKey(const ValueKey('rest-control')));
    final note = tester.getRect(
      find.byKey(const ValueKey('exercise-note-action-$_exercise')),
    );
    expect(note.left, greaterThan(rest.right));
    expect(note.left - rest.right, closeTo(TioSpacing.sm, 0.01));
    expect(note.top, closeTo(rest.top, 0.01));
    expect(note.height, closeTo(rest.height, 0.01));
    expect(
      find.byKey(const ValueKey('exercise-note-input-$_exercise')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('exercise-notes-retry')), findsNothing);
  });

  testWidgets('Note focuses the inline input without opening a sheet',
      (tester) async {
    await _pump(tester, _FakeRoutineNotesRepository());

    await tester
        .tap(find.byKey(const ValueKey('exercise-note-action-$_exercise')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('exercise-note-input-$_exercise')),
      findsOneWidget,
    );
    final input = find.byKey(const ValueKey('exercise-note-input-$_exercise'));
    final inputWidget = tester.widget<TextField>(input);
    expect(inputWidget.decoration!.border, same(InputBorder.none));
    expect(inputWidget.decoration!.enabledBorder, same(InputBorder.none));
    expect(tester.getRect(input).height, lessThan(TioSize.dp52));
    expect(FocusManager.instance.primaryFocus, isNotNull);
    expect(
        find.byKey(const ValueKey('exercise-note-type-sheet')), findsNothing);
  });

  testWidgets('draft type sheet exposes Delete Note and clears the draft',
      (tester) async {
    await _pump(tester, _FakeRoutineNotesRepository());

    await tester.tap(
      find.byKey(const ValueKey('exercise-note-action-$_exercise')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('exercise-note-input-$_exercise')),
      'Temporary note',
    );
    await tester.tap(find.byKey(const ValueKey('exercise-note-draft-type')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('exercise-note-delete')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-note-delete')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('exercise-note-type-sheet')), findsNothing);
    expect(find.byKey(const ValueKey('exercise-note-input-$_exercise')),
        findsNothing);
  });

  testWidgets('debug preview shows a temporary field without note buttons',
      (tester) async {
    await _pumpPreview(tester);

    await tester.tap(
      find.byKey(const ValueKey('exercise-note-action-$_exercise')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('exercise-note-input-$_exercise')),
      'Preview note',
    );
    expect(find.text('Preview note'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-note-save')), findsNothing);
    expect(find.byKey(const ValueKey('exercise-note-cancel')), findsNothing);
  });

  testWidgets('draft survives rebuild without an inline save action',
      (tester) async {
    final repository = _FakeRoutineNotesRepository();
    await _pump(tester, repository);

    await tester
        .tap(find.byKey(const ValueKey('exercise-note-action-$_exercise')));
    await tester.pump();
    final input = find.byKey(const ValueKey('exercise-note-input-$_exercise'));
    await tester.enterText(input, '  Keep elbows tucked  ');
    await tester.pump();

    expect(tester.widget<TextField>(input).controller!.text,
        '  Keep elbows tucked  ');
    expect(find.byKey(const ValueKey('exercise-note-save')), findsNothing);
    expect(find.byKey(const ValueKey('exercise-note-cancel')), findsNothing);
    expect(repository.createCommand, isNull);
    expect(tester.widget<TextField>(input).controller!.text,
        '  Keep elbows tucked  ');
  });

  testWidgets('right swipe opens type sheet and offers Routine type in Edit',
      (tester) async {
    final repository = _FakeRoutineNotesRepository(notes: [_note()]);
    await _pump(tester, repository, routineId: RoutineId(_routine));

    final row = find.byKey(const ValueKey('exercise-note-swipe-$_noteId'));
    await tester.drag(row, const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('exercise-note-type-sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-note-type-routine')),
        findsOneWidget);
    final exerciseOption =
        find.byKey(const ValueKey('exercise-note-type-exercise'));
    final exerciseIcon = find.descendant(
      of: exerciseOption,
      matching: find.byIcon(Icons.push_pin_outlined),
    );
    final exerciseTitle = find.descendant(
      of: exerciseOption,
      matching: find.text('Pinned Exercise Note'),
    );
    expect(tester.getRect(exerciseIcon).top,
        closeTo(tester.getRect(exerciseTitle).top, 0.01));
    final exerciseSubtitle = find.descendant(
      of: exerciseOption,
      matching: find.text(
        'Appears every time you log this exercise. Hidden from workout posts.',
      ),
    );
    expect(tester.getRect(exerciseSubtitle).left,
        lessThan(tester.getRect(exerciseTitle).left));
  });

  testWidgets('type sheet exposes Delete Note before confirmation',
      (tester) async {
    final repository = _FakeRoutineNotesRepository(notes: [_note()]);
    await _pump(tester, repository, routineId: RoutineId(_routine));

    final row = find.byKey(const ValueKey('exercise-note-swipe-$_noteId'));
    await tester.drag(row, const Offset(220, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('exercise-note-delete')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-note-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Delete Exercise Note?'), findsOneWidget);
    expect(repository.deleteCommand, isNull);
  });

  testWidgets('left swipe reveals Delete and confirmation performs delete',
      (tester) async {
    final repository = _FakeRoutineNotesRepository(notes: [_note()]);
    await _pump(tester, repository);

    final row = find.byKey(const ValueKey('exercise-note-swipe-$_noteId'));
    await tester.drag(row, const Offset(-220, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Exercise Note?'), findsOneWidget);

    await tester.tap(find.text('Delete Note'));
    await tester.pumpAndSettle();
    expect(repository.deleteCommand?.id, _noteId);
    expect(find.text('Keep shoulders down'), findsNothing);
  });

  testWidgets('canceling Delete confirmation preserves the note',
      (tester) async {
    final repository = _FakeRoutineNotesRepository(notes: [_note()]);
    await _pump(tester, repository);

    final row = find.byKey(const ValueKey('exercise-note-swipe-$_noteId'));
    await tester.drag(row, const Offset(-220, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deleteCommand, isNull);
    expect(find.text('Keep shoulders down'), findsOneWidget);
  });
}

final class _FakeRoutineNotesRepository implements RoutineNotesRepository {
  _FakeRoutineNotesRepository({this.notes = const []});

  List<RoutineNote> notes;
  RoutineNoteCreate? createCommand;
  RoutineNoteDelete? deleteCommand;

  @override
  Future<List<RoutineNote>> read(RoutineNoteScope scope) async =>
      notes.where((note) => note.scope == scope).toList();

  @override
  Future<RoutineNote> create(RoutineNoteCreate command) async {
    createCommand = command;
    final saved = _note(
      id: command.id,
      scope: command.scope,
      body: command.body,
    );
    notes = [...notes, saved];
    return saved;
  }

  @override
  Future<RoutineNote> update(RoutineNoteUpdate command) async =>
      throw UnimplementedError();

  @override
  Future<RoutineNote> transfer(RoutineNoteTransfer command) async {
    final source = notes.singleWhere((note) => note.id == command.id);
    final transferred = _note(
      id: source.id,
      scope: command.destination,
      body: source.body,
      revision: source.revision + 1,
    );
    notes = [
      for (final note in notes)
        if (note.id != command.id) note,
      transferred,
    ];
    return transferred;
  }

  @override
  Future<void> delete(RoutineNoteDelete command) async {
    deleteCommand = command;
    notes = notes.where((note) => note.id != command.id).toList();
  }
}
