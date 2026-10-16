import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_metadata_card.dart';
import 'package:tio_shared/shared.dart';

const _programId = '10000000-0000-4000-8000-000000000001';
const _routineId = '20000000-0000-4000-8000-000000000041';

Program get _program => Program(id: ProgramId(_programId), name: 'Strength');

Future<void> _pump(
  WidgetTester tester, {
  required RoutineRepository? repository,
  TioThemeMode mode = TioThemeMode.light,
  Program? selectedProgram,
  Future<void> Function(Routine)? onRoutinePressed,
  Future<bool> Function(Routine)? onEditRoutine,
  Future<bool> Function(String suggestedName)? onCreateRoutine,
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
        onRoutinePressed: onRoutinePressed,
        onEditRoutine: onEditRoutine,
        onCreateRoutine: onCreateRoutine,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('atomic Create callback bypasses legacy name-only INSERT',
      (tester) async {
    final repository = _MemoryRoutines();
    String? suggested;
    await _pump(
      tester,
      repository: repository,
      onCreateRoutine: (name) async {
        suggested = name;
        return false;
      },
    );
    await tester.tap(
      find.byKey(const ValueKey('program-detail-add-routine')),
    );
    await tester.pumpAndSettle();
    expect(suggested, 'Routine 1');
    expect(repository.created, isEmpty);
    expect(find.byKey(const ValueKey('routine-name-field')), findsNothing);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
  });

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

  testWidgets('atomic Create callback uses suggested name and refreshes Program',
      (tester) async {
    final repository = _MemoryRoutines();
    String? received;
    await _pump(
      tester,
      repository: repository,
      onCreateRoutine: (name) async {
        received = name;
        repository.rows.add(Routine(
          id: RoutineId(_routineId),
          programId: _program.id,
          name: name,
        ));
        return true;
      },
    );
    await tester.tap(find.byKey(const ValueKey('program-detail-add-routine')));
    await tester.pumpAndSettle();
    expect(received, 'Routine 1');
    expect(repository.created, isEmpty);
    expect(repository.rows.single.programId, _program.id);
    expect(find.text('Routine 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-name-field')), findsNothing);
  });

  testWidgets('no atomic Create capability disables legacy name-only action',
      (tester) async {
    await _pump(tester, repository: _MemoryRoutines());
    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('program-detail-add-routine')),
    );
    expect(button.onPressed, isNull);
    expect(find.byKey(const ValueKey('routine-name-field')), findsNothing);
    expect(find.byKey(const ValueKey('routine-name-submit')), findsNothing);
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

  testWidgets('Routine card selects its identity, not Rename sheet',
      (tester) async {
    final repository = _MemoryRoutines([
      Routine(id: RoutineId(_routineId), programId: _program.id, name: 'Push'),
    ]);
    Routine? selected;
    await _pump(
      tester,
      repository: repository,
      onRoutinePressed: (routine) async { selected = routine; },
    );
    await tester.tap(find.byKey(const ValueKey('program-routine-$_routineId')));
    await tester.pumpAndSettle();

    expect(selected?.id, RoutineId(_routineId));
    expect(selected?.programId, _program.id);
    expect(find.text('Edit Routine'), findsNothing);
    expect(find.byKey(const ValueKey('routine-name-field')), findsNothing);
    expect(repository.rows.single.name, 'Push');
    expect(find.byKey(const ValueKey('routine-menu-$_routineId')),
        findsNothing, reason: 'No Edit capability means no inert 3-dot action');
  });

  testWidgets('Routine 3-dot opens Core bottom sheet and launches full Edit',
      (tester) async {
    final repository = _MemoryRoutines([
      Routine(id: RoutineId(_routineId), programId: _program.id, name: 'Push'),
    ]);
    Routine? navigated;
    Routine? edited;
    await _pump(
      tester,
      repository: repository,
      onRoutinePressed: (routine) async { navigated = routine; },
      onEditRoutine: (routine) async { edited = routine; return true; },
    );
    final options = find.byKey(const ValueKey('routine-menu-$_routineId'));
    final sheet = find.byKey(const ValueKey('routine-actions-sheet-$_routineId'));
    expect(options, findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);

    await tester.tap(options);
    await tester.pumpAndSettle();

    expect(sheet, findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.byType(TioCard)),
        findsOneWidget);
    expect(
      tester.widget<TioCard>(find.descendant(
        of: sheet,
        matching: find.byType(TioCard),
      )).variant,
      TioCardVariant.outlined,
    );
    expect(find.byKey(const ValueKey('routine-edit-$_routineId')),
        findsOneWidget);
    // Move and Delete must never appear without real owner-safe capabilities.
    expect(find.byKey(const ValueKey('routine-move-$_routineId')), findsNothing);
    expect(find.byKey(const ValueKey('routine-delete-$_routineId')), findsNothing);
    expect(find.text('Change Picture'), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    // Tapping the modal barrier dismisses without changing this Routine.
    await tester.tapAt(const Offset(16, 50));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(repository.rows.single.name, 'Push');
    expect(edited, isNull);

    await tester.tap(options);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-edit-$_routineId')));
    await tester.pumpAndSettle();

    expect(sheet, findsNothing);
    expect(navigated, isNull);
    expect(edited?.id.value, _routineId);
    expect(find.byKey(const ValueKey('routine-name-field')), findsNothing);
  });

  testWidgets('Routine bottom sheet fits narrow dark viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemoryRoutines([
      Routine(id: RoutineId(_routineId), programId: _program.id, name: 'Push'),
    ]);
    await _pump(
      tester,
      repository: repository,
      mode: TioThemeMode.dark,
      onEditRoutine: (_) async => false,
    );
    await tester.tap(find.byKey(const ValueKey('routine-menu-$_routineId')));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const ValueKey('routine-actions-sheet-$_routineId'));
    final rect = tester.getRect(sheet);
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(640));
    expect(find.text('Edit Routine'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Routine sheet dispatches only supplied Move/Delete actions',
      (tester) async {
    var editCalls = 0;
    var moveCalls = 0;
    var deleteCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: RoutineMetadataCard(
            routine: Routine(
              id: RoutineId(_routineId),
              programId: _program.id,
              name: 'Push',
            ),
            onEdit: () => editCalls++,
            onMove: () => moveCalls++,
            onDelete: () => deleteCalls++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final options = find.byKey(const ValueKey('routine-menu-$_routineId'));

    await tester.tap(options);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-edit-$_routineId')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-move-$_routineId')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-delete-$_routineId')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('routine-move-$_routineId')));
    await tester.pumpAndSettle();
    expect(moveCalls, 1);
    expect(editCalls, 0);
    expect(deleteCalls, 0);

    await tester.tap(options);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-delete-$_routineId')));
    await tester.pumpAndSettle();
    expect(deleteCalls, 1);
    expect(editCalls, 0);
    expect(moveCalls, 1);

    await tester.tap(options);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-edit-$_routineId')));
    await tester.pumpAndSettle();
    expect(editCalls, 1);
    expect(moveCalls, 1);
    expect(deleteCalls, 1);
  });

  testWidgets('Routine action sheet revokes stale Edit callback after rebuild',
      (tester) async {
    final actionVersion = ValueNotifier<int>(0);
    addTearDown(actionVersion.dispose);
    var oldCalls = 0;
    var newCalls = 0;
    final routine = Routine(
      id: RoutineId(_routineId),
      programId: _program.id,
      name: 'Push',
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: actionVersion,
            builder: (context, version, _) => RoutineMetadataCard(
              routine: routine,
              onEdit: version == 1
                  ? null
                  : version == 0
                      ? () => oldCalls++
                      : () => newCalls++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('routine-menu-$_routineId'));
    final action = find.byKey(const ValueKey('routine-edit-$_routineId'));

    // The old modal is still open, but the parent revoked the action.
    await tester.tap(button);
    await tester.pumpAndSettle();
    actionVersion.value = 1;
    await tester.pump();
    expect(action, findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(oldCalls, 0);
    expect(newCalls, 0);
    expect(button, findsNothing);

    // Parent now supplies a different current capability while modal is open.
    actionVersion.value = 0;
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    actionVersion.value = 2;
    await tester.pump();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(oldCalls, 0);
    expect(newCalls, 1);
  });

  testWidgets('Routine overflow has one accessible tap action and label',
      (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await _pump(
      tester,
      repository: _MemoryRoutines([
        Routine(id: RoutineId(_routineId), programId: _program.id, name: 'Push'),
      ]),
      onEditRoutine: (_) async => false,
    );
    final overflow = find.byKey(const ValueKey('routine-menu-$_routineId'));
    expect(overflow, findsOneWidget);
    final overflowSemantics = tester.getSemantics(overflow);
    expect(overflowSemantics.label, contains('Routine options'));
    expect(overflowSemantics.hasAction(SemanticsAction.tap), isTrue);
    await tester.tap(overflow);
    await tester.pumpAndSettle();
    final edit = find.byKey(const ValueKey('routine-edit-$_routineId'));
    expect(edit, findsOneWidget);
    final editSemantics = tester.getSemantics(edit);
    expect(editSemantics.label, contains('Edit Routine'));
    expect(editSemantics.hasAction(SemanticsAction.tap), isTrue);
    expect(find.byKey(const ValueKey('routine-actions-sheet-$_routineId')),
        findsOneWidget);
  });

  testWidgets('failed atomic Create retains empty Program without legacy write',
      (tester) async {
    final repository = _MemoryRoutines();
    await _pump(
      tester,
      repository: repository,
      onCreateRoutine: (name) async => false,
    );
    await tester.tap(find.byKey(const ValueKey('program-detail-add-routine')));
    await tester.pumpAndSettle();
    expect(repository.created, isEmpty);
    expect(repository.rows, isEmpty);
    expect(find.byKey(const ValueKey('program-routines-empty')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-name-submit')), findsNothing);
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
