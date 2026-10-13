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
  Future<void> Function(Routine)? onRoutinePressed,
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
        findsOneWidget);
  });

  testWidgets('Routine 3-dot opens only the real Edit metadata action',
      (tester) async {
    final repository = _MemoryRoutines([
      Routine(id: RoutineId(_routineId), programId: _program.id, name: 'Push'),
    ]);
    Routine? navigated;
    await _pump(
      tester,
      repository: repository,
      onRoutinePressed: (routine) async { navigated = routine; },
    );
    final options = find.byKey(const ValueKey('routine-menu-$_routineId'));
    final popup = find.byKey(const ValueKey('routine-popup-card-$_routineId'));
    expect(options, findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);

    await tester.tap(options);
    await tester.pumpAndSettle();

    expect(popup, findsOneWidget);
    expect(find.descendant(of: popup, matching: find.byType(TioCard)),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-edit-$_routineId')),
        findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Change Picture'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    // Tapping outside the anchored card dismisses it without changing Routine.
    await tester.tapAt(const Offset(16, 500));
    await tester.pumpAndSettle();
    expect(popup, findsNothing);
    expect(repository.rows.single.name, 'Push');

    await tester.tap(options);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-edit-$_routineId')));
    await tester.pumpAndSettle();

    expect(popup, findsNothing);
    expect(find.text('Edit Routine'), findsOneWidget);
    expect(navigated, isNull);
    expect(find.byKey(const ValueKey('routine-name-field')), findsOneWidget);
  });

  testWidgets('Routine popup stays anchored within narrow dark viewport',
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
    );
    final options = find.byKey(const ValueKey('routine-menu-$_routineId'));
    await tester.tap(options);
    await tester.pumpAndSettle();

    final popup = find.byKey(const ValueKey('routine-popup-card-$_routineId'));
    final anchorRect = tester.getRect(options);
    final popupRect = tester.getRect(popup);
    expect(popupRect.right, lessThanOrEqualTo(320));
    expect(popupRect.left, greaterThanOrEqualTo(0));
    expect(popupRect.top, greaterThanOrEqualTo(anchorRect.bottom));
    expect(tester.takeException(), isNull);
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
