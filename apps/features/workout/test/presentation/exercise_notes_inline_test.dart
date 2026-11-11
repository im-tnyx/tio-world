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
  bool isWorkoutLog = false,
  Widget restControl = const SizedBox(key: ValueKey('rest-control')),
  List<ExerciseNoteDraftSnapshot> initialDrafts = const [],
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
            isWorkoutLog: isWorkoutLog,
            restControl: restControl,
            repository: repository,
            ownerId: _owner,
            isSessionCurrent: () => true,
            enabled: true,
            initialDrafts: initialDrafts,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPreview(WidgetTester tester,
    {bool isWorkoutLog = false}) async {
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
          isWorkoutLog: isWorkoutLog,
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
  testWidgets('Workout Log defaults to Workout Note and shows three types',
      (tester) async {
    await _pumpPreview(tester, isWorkoutLog: true);
    await tester
        .tap(find.byKey(const ValueKey('exercise-note-action-$_exercise')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('exercise-note-type-sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-note-type-workout')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-note-type-routine')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-note-type-exercise')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercise-note-type-workout')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('exercise-note-input-$_exercise')))
            .decoration!
            .hintText,
        'Add a workout note');
    await tester.tap(find.byKey(const ValueKey('exercise-note-draft-type')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-note-type-exercise')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Icon>(
                find.byKey(const ValueKey('exercise-note-draft-type-icon')))
            .icon,
        Icons.push_pin_outlined);
  });

  testWidgets('Routine draft defaults to Routine Note and hides Workout Note',
      (tester) async {
    await _pump(tester, _FakeRoutineNotesRepository());
    await tester
        .tap(find.byKey(const ValueKey('exercise-note-action-$_exercise')));
    await tester.pump();
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('exercise-note-input-$_exercise')))
            .decoration!
            .hintText,
        'Add a note pinned to the routine');
    await tester.tap(find.byKey(const ValueKey('exercise-note-draft-type')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('exercise-note-type-workout')), findsNothing);
    expect(find.byKey(const ValueKey('exercise-note-type-routine')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-note-type-exercise')),
        findsOneWidget);
  });

  testWidgets('Note stays on the right of Rest in the action row',
      (tester) async {
    await _pump(
      tester,
      _FakeRoutineNotesRepository(),
      restControl: const Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        child: SizedBox(
          key: ValueKey('rest-control'),
          width: 140,
          height: 31,
        ),
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

  testWidgets('Note remains adjacent to Rest in a compact action row',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(
      tester,
      _FakeRoutineNotesRepository(),
      restControl: const Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        child: SizedBox(
          key: ValueKey('rest-control'),
          width: 140,
          height: 31,
        ),
      ),
    );

    final rest = tester.getRect(find.byKey(const ValueKey('rest-control')));
    final note = tester.getRect(
      find.byKey(const ValueKey('exercise-note-action-$_exercise')),
    );
    expect(note.left - rest.right, closeTo(TioSpacing.sm, 0.01));
    expect(note.right, lessThanOrEqualTo(320));
  });

  testWidgets('Note reveals the inline input without opening the keyboard',
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
    expect(inputWidget.focusNode!.hasFocus, isFalse);
    expect(
        find.byKey(const ValueKey('exercise-note-type-sheet')), findsNothing);

    await tester.tap(input);
    await tester.pump();
    expect(inputWidget.focusNode!.hasFocus, isTrue);

    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(inputWidget.focusNode!.hasFocus, isFalse);
  });

  testWidgets('draft icon follows the selected note type', (tester) async {
    await _pump(tester, _FakeRoutineNotesRepository(),
        routineId: RoutineId(_routine));

    await tester.tap(
      find.byKey(const ValueKey('exercise-note-action-$_exercise')),
    );
    await tester.pump();
    final icon = find.byKey(
      const ValueKey('exercise-note-draft-type-icon'),
    );
    expect(tester.widget<Icon>(icon).icon, Icons.assignment_outlined);

    await tester.tap(find.byKey(const ValueKey('exercise-note-draft-type')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('exercise-note-type-exercise')),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Icon>(icon).icon, Icons.push_pin_outlined);
  });

  testWidgets('tapping Note adds another inline draft field', (tester) async {
    await _pump(tester, _FakeRoutineNotesRepository());

    final noteAction =
        find.byKey(const ValueKey('exercise-note-action-$_exercise'));
    await tester.tap(noteAction);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('exercise-note-input-$_exercise')),
      'First note',
    );

    await tester.tap(noteAction);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('exercise-note-input-$_exercise')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('exercise-note-input-$_exercise-1')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('exercise-note-input-$_exercise')),
          )
          .controller!
          .text,
      'First note',
    );
  });

  testWidgets('text selection does not trigger Note swipe actions',
      (tester) async {
    await _pump(tester, _FakeRoutineNotesRepository());

    await tester.tap(
      find.byKey(const ValueKey('exercise-note-action-$_exercise')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('exercise-note-input-$_exercise')),
      'Select this text',
    );
    await tester.pump();

    final input = find.byKey(const ValueKey('exercise-note-input-$_exercise'));
    final gesture = await tester.startGesture(tester.getRect(input).center);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(120, 0));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('exercise-note-type-sheet')), findsNothing);
    expect(find.byKey(const ValueKey('exercise-note-delete-action')),
        findsNothing);
    expect(
      tester.widget<TextField>(input).controller!.text,
      'Select this text',
    );
  });

  testWidgets(
      'left swipe on a draft reveals Delete and removes it after confirmation',
      (tester) async {
    await _pump(tester, _FakeRoutineNotesRepository());

    await tester.tap(
      find.byKey(const ValueKey('exercise-note-action-$_exercise')),
    );
    await tester.pump();

    final draftRow = find.byKey(const ValueKey('exercise-note-draft-swipe-0'));
    await tester.drag(draftRow, const Offset(-220, 0));
    await tester.pump();

    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('exercise-note-delete-action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete Note?'), findsOneWidget);
    await tester.tap(find.text('Delete Note').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('exercise-note-input-$_exercise')),
      findsNothing,
    );
  });

  testWidgets('swiping an open draft back closes the Delete action',
      (tester) async {
    await _pump(tester, _FakeRoutineNotesRepository());

    await tester.tap(
      find.byKey(const ValueKey('exercise-note-action-$_exercise')),
    );
    await tester.pump();

    final draftRow = find.byKey(const ValueKey('exercise-note-draft-swipe-0'));
    await tester.drag(draftRow, const Offset(-220, 0));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('exercise-note-delete-action')),
      findsOneWidget,
    );

    await tester.drag(draftRow, const Offset(220, 0));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('exercise-note-delete-action')),
      findsNothing,
    );
  });

  testWidgets('inline drafts stop at four active note slots', (tester) async {
    await _pump(tester, _FakeRoutineNotesRepository());

    final noteAction =
        find.byKey(const ValueKey('exercise-note-action-$_exercise'));
    for (var index = 0; index < 5; index++) {
      await tester.tap(noteAction);
      await tester.pump();
    }

    expect(find.byType(TextField), findsNWidgets(4));
    expect(
      find.byKey(const ValueKey('exercise-note-input-$_exercise-4')),
      findsNothing,
    );
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

  testWidgets('captured drafts restore after the exercise card remounts',
      (tester) async {
    await _pump(
      tester,
      _FakeRoutineNotesRepository(),
      initialDrafts: [
        ExerciseNoteDraftSnapshot(
          draftId: 'entry-1:0',
          exerciseRef: ExerciseRef.catalog(_exercise),
          type: RoutineNoteType.pinnedExercise,
          body: 'Restore this draft',
        ),
      ],
    );

    final input = find.byKey(const ValueKey('exercise-note-input-$_exercise'));
    expect(input, findsOneWidget);
    expect(
        tester.widget<TextField>(input).controller!.text, 'Restore this draft');
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

  testWidgets('Routine-scoped Notes stay inside the inline Exercise surface',
      (tester) async {
    final routineNote = _note(
      id: '44444444-4444-4444-8444-444444444444',
      scope: RoutineNoteScope.routine(RoutineId(_routine)),
      body: 'Routine-wide cue',
    );
    await _pump(
      tester,
      _FakeRoutineNotesRepository(notes: [routineNote]),
      routineId: RoutineId(_routine),
    );

    expect(find.text('Routine-wide cue'), findsOneWidget);
    expect(find.text('Routine Notes'), findsNothing);
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

    await tester.tap(
      find.byKey(const ValueKey('exercise-note-delete-action')),
    );
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
    await tester.tap(
      find.byKey(const ValueKey('exercise-note-delete-action')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deleteCommand, isNull);
    expect(find.text('Keep shoulders down'), findsOneWidget);
  });

  testWidgets('duplicate ExerciseRef cards share persisted Notes state',
      (tester) async {
    final repository = _FakeRoutineNotesRepository(notes: [_note()]);
    final registry = RoutineNotesControllerRegistry();
    addTearDown(registry.dispose);
    final exerciseRef = ExerciseRef.catalog(_exercise);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                ExerciseNotesInline(
                  key: const ValueKey('duplicate-note-card-1'),
                  exerciseRef: exerciseRef,
                  routineId: null,
                  restControl: const SizedBox(),
                  repository: repository,
                  ownerId: _owner,
                  isSessionCurrent: () => true,
                  enabled: true,
                  controllerRegistry: registry,
                ),
                ExerciseNotesInline(
                  key: const ValueKey('duplicate-note-card-2'),
                  exerciseRef: exerciseRef,
                  routineId: null,
                  restControl: const SizedBox(),
                  repository: repository,
                  ownerId: _owner,
                  isSessionCurrent: () => true,
                  enabled: true,
                  controllerRegistry: registry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keep shoulders down'), findsNWidgets(2));
    await tester.drag(
      find.byKey(const ValueKey('exercise-note-swipe-$_noteId')).first,
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('exercise-note-delete-action')).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Note'));
    await tester.pumpAndSettle();

    expect(repository.deleteCommand?.id, _noteId);
    expect(find.text('Keep shoulders down'), findsNothing);
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
  Future<RoutineNoteMutationReceipt> reconcile(String mutationId) async =>
      RoutineNoteMutationReceipt(
        mutationId: mutationId,
        status: RoutineNoteMutationReceiptStatus.pending,
      );

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
