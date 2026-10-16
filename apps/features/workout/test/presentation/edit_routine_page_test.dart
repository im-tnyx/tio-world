import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_set_type_badge.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _p = '10000000-0000-4000-8000-000000000001';
const _other = '10000000-0000-4000-8000-000000000002';
const _r = '20000000-0000-4000-8000-000000000001';
const _entryId = '30000000-0000-4000-8000-000000000001';
const _setId = '40000000-0000-4000-8000-000000000001';
const _exerciseRef = 'ex_bench_press';
const _newCustomRef = '70000000-0000-4000-8000-000000000001';

Program get _program => Program(id: ProgramId(_p), name: 'Strength');
Routine get _routine =>
    Routine(id: RoutineId(_r), programId: ProgramId(_p), name: 'Push Day');

RoutineCompositionEntry _entry({
  double? kg = 12.54321,
  int reps = 8,
  int? repsMax,
  RoutineSetType setType = RoutineSetType.normal,
  int? rest = 60,
}) => RoutineCompositionEntry(
      id: _entryId,
      exercise: ExerciseRef.catalog(_exerciseRef),
      sets: [
        RoutineCompositionSet(
          id: _setId,
          prescription: SetPrescription(
            reps: reps,
            repsMax: repsMax,
            setType: setType,
            loadKg: kg,
            restSeconds: rest,
          ),
        ),
      ],
    );

RoutineCompositionSnapshot _snapshot({
  List<RoutineCompositionEntry>? entries,
  int revision = 4,
  String? mutation,
  String name = 'Push Day',
}) => RoutineCompositionSnapshot(
      routineId: RoutineId(_r),
      revision: revision,
      lastMutationId: mutation,
      name: name,
      entries: entries ?? [_entry()],
    );

class _Fixtures {
  _Fixtures({this.unit = WeightUnit.kg, this.routine, this.repositoryAvailable = true, this.canWrite})
      : compositions = _Compositions(_snapshot()),
        catalog = _Catalog(),
        users = _Users();

  final WeightUnit? unit;
  final Routine? routine;
  final bool repositoryAvailable;
  final bool Function()? canWrite;
  final _Compositions compositions;
  final _Catalog catalog;
  final _Users users;
  final _Routines routines = _Routines();
  bool? editorResult;
  int nextId = 0;

  String newId() {
    nextId++;
    return '90000000-0000-4000-8000-${nextId.toString().padLeft(12, '0')}';
  }

  Future<void> open(WidgetTester tester, {TioThemeMode mode = TioThemeMode.light}) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              editorResult = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditRoutinePage(
                    program: _program,
                    routine: routine ?? _routine,
                    routineRepository:
                        repositoryAvailable ? routines : null,
                    compositionRepository:
                        repositoryAvailable ? compositions : null,
                    catalogRepository: catalog,
                    userExerciseRepository: users,
                    canWrite: canWrite,
                    weightUnit: unit,
                    newUuid: newId,
                  ),
                ),
              );
            },
            child: const Text('Open editor'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }
}

Future<void> _fillNewSet(WidgetTester tester, {int reps = 8}) async {
  const id = '90000000-0000-4000-8000-000000000002';
  final field = find.byKey(const ValueKey('routine-set-reps-$id'));
  await tester.ensureVisible(field);
  await tester.enterText(field, '$reps');
  await tester.pump();
}

Future<void> _removeExerciseMenu(WidgetTester tester, String id) async {
  final menu = find.byKey(ValueKey('edit-routine-entry-options-$id'));
  await tester.ensureVisible(menu);
  await tester.tap(menu);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('routine-exercise-option-remove')),
      findsOneWidget);
  expect(find.text('Exercise Options'), findsOneWidget);
  expect(find.byType(PopupMenuButton<String>), findsNothing);
  await tester.tap(find.text('Remove Exercise'));
  await tester.pumpAndSettle();
}

const _thinPickerCardHeight = TioSize.dp38 +
    2 * TioSpacing.sm +
    2 * TioCardTokens.borderThin;

void main() {
  testWidgets('Edit prefills Create-style Name field and saves one Name-only RPC',
      (tester) async {
    final fixture = _Fixtures();
    await fixture.open(tester);
    final name = find.byKey(const ValueKey('edit-routine-name'));
    expect(name, findsOneWidget);
    final field = tester.widget<TioInput>(name);
    expect(field.controller!.text, 'Push Day');
    expect(field.hint, 'Routine name');
    expect(find.text('Update'), findsOneWidget);
    await tester.enterText(name, 'Strength Push');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(fixture.editorResult, isTrue);
    expect(fixture.compositions.aggregateCalls, 1);
    expect(fixture.compositions.saveCount, 0);
    expect(fixture.compositions.lastAggregate!.name, 'Strength Push');
    expect(fixture.compositions.lastAggregate!.entries, isNull);
  });

  testWidgets('Edit Set Type sheet uses shared semantic badges and preserves actions',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: [
      _entry(setType: RoutineSetType.warmUp),
    ]);
    await f.open(tester, mode: TioThemeMode.dark);
    await tester.tap(find.byKey(const ValueKey('routine-set-type-$_setId')));
    await tester.pumpAndSettle();
    expect(find.text('Select Set Type'), findsOneWidget);
    for (final kind in RoutineSetType.values) {
      final option = find.byKey(ValueKey('edit-routine-type-${kind.wireValue}'));
      final finder = find.descendant(
        of: option, matching: find.byType(RoutineSetTypeBadge),
      );
      expect(finder, findsOneWidget);
      final badge = tester.widget<RoutineSetTypeBadge>(finder);
      expect(badge.setType, kind);
      expect(badge.useEditSetNumberColor, isTrue);
      final card = find.descendant(
        of: option,
        matching: find.byType(TioCard),
      );
      expect(card, findsOneWidget);
      expect(tester.widget<TioCard>(card).variant,
          TioCardVariant.outlined);
      expect(tester.widget<TioCard>(card).outlinedBorderWidth,
          TioCardTokens.borderThin);
      expect(tester.getSize(card).height, _thinPickerCardHeight);

      expect(badge.normalNumber, 1);
    }
    expect(find.descendant(
      of: find.byKey(const ValueKey('edit-routine-type-warm_up')),
      matching: find.byIcon(Icons.check),
    ), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-routine-set-details')), findsNothing);
    expect(find.text('Rest & set details'), findsNothing);
    final remove = find.byKey(const ValueKey('edit-routine-type-remove'));
    expect(remove, findsOneWidget);
    expect(find.descendant(
      of: remove, matching: find.byType(TioCard)), findsOneWidget);
    final trash = find.descendant(
      of: remove, matching: find.byIcon(Icons.delete_outline));
    expect(trash, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-routine-type-drop')));
    await tester.pumpAndSettle();
    expect(find.descendant(
      of: find.byKey(const ValueKey('routine-set-type-$_setId')),
      matching: find.text('D'),
    ), findsOneWidget);
    expect(f.compositions.saveCount, 0);
  });

  for (final mode in [TioThemeMode.dark, TioThemeMode.light]) {
    testWidgets('Edit Set/boxed number/Add Set rendered surfaces equal 38dp '
        'at 320dp in ${mode.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final f = _Fixtures();
      await f.open(tester, mode: mode);
      expect(find.byKey(const ValueKey('routine-composer-screen')),
          findsOneWidget);
      expect(find.text('Edit Routine'), findsOneWidget);
      final add = find.byKey(const ValueKey('edit-routine-add-set-$_entryId'));
      await tester.ensureVisible(add);
      final filled = find.descendant(of: add, matching: find.byType(FilledButton));
      final surface = find.descendant(
        of: filled, matching: find.byType(Material)).first;
      const expected = TioSize.dp38;
      expect(tester.getSize(surface).height, expected);
      expect(tester.getSize(find.byKey(
        const ValueKey('routine-set-type-box-$_setId'))).height, expected);
      expect(tester.getSize(find.byKey(
        const ValueKey('routine-set-weight-$_setId'))).height, expected);
      expect(tester.getSize(find.byKey(
        const ValueKey('routine-set-reps-$_setId'))).height, expected);
      expect(tester.getSize(add).height, greaterThanOrEqualTo(expected));
      expect(f.compositions.saveCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Exercise options dismiss without removing or saving',
      (tester) async {
    final f = _Fixtures();
    await f.open(tester);
    final menu = find.byKey(
      const ValueKey('edit-routine-entry-options-$_entryId'));
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-option-remove')),
        findsOneWidget);
    expect(find.text('Exercise Options'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-option-remove')),
        findsNothing);
    expect(find.byKey(const ValueKey('edit-routine-entry-$_entryId')),
        findsOneWidget);
    expect(f.compositions.saveCount, 0);
    await _removeExerciseMenu(tester, _entryId);
    expect(find.byKey(const ValueKey('edit-routine-entry-$_entryId')),
        findsNothing);
    expect(f.compositions.saveCount, 0);
  });

  testWidgets('Replace Exercise resets incompatible Set until explicit Update',
      (tester) async {
    final f = _Fixtures();
    await f.open(tester);
    final menu = find.byKey(const ValueKey(
        'edit-routine-entry-options-$_entryId'));
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-option-replace')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-exercise-option-remove')),
        findsOneWidget);
    await tester.tap(find.text('Replace Exercise'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercises-page')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-entry-$_entryId')),
        findsOneWidget);
    expect(f.compositions.saveCount, 0);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace Exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run on Treadmill'));
    await tester.pumpAndSettle();
    const newEntry = '90000000-0000-4000-8000-000000000001';
    const newSet = '90000000-0000-4000-8000-000000000002';
    expect(find.byKey(const ValueKey('edit-routine-entry-$_entryId')),
        findsNothing);
    expect(find.byKey(const ValueKey('edit-routine-entry-$newEntry')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-set-reps-$_setId')),
        findsNothing);
    expect(find.byKey(const ValueKey('routine-set-distance-$newSet')),
        findsOneWidget);
    expect(find.text('KM'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('KG'), findsNothing);
    expect(find.text('REPS'), findsNothing);
    expect(f.compositions.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    final saved = f.compositions.lastSave!.entries.single;
    expect(saved.id, newEntry);
    expect(saved.exercise, ExerciseRef.catalog('ex_run_on_treadmill'));
    expect(saved.sets.single.id, newSet);
    expect(saved.sets.single.prescription.reps, isNull);
    expect(saved.sets.single.prescription.loadKg, isNull);
    expect(saved.sets.single.prescription.distanceMeters, isNull);
    expect(f.editorResult, isTrue);
  });


  testWidgets('Edit batch Add queues two Exercises and saves once',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: const []);
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run on Treadmill'));
    await tester.pumpAndSettle();
    expect(find.text('Add 2 exercises'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(
        'edit-routine-entry-90000000-0000-4000-8000-000000000001')),
        findsOneWidget);
    expect(find.byKey(const ValueKey(
        'edit-routine-entry-90000000-0000-4000-8000-000000000003')),
        findsOneWidget);
    expect(f.compositions.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    expect(f.compositions.lastSave!.entries.map((e) => e.exercise).toList(), [
      ExerciseRef.catalog('ex_bench_press'),
      ExerciseRef.catalog('ex_run_on_treadmill'),
    ]);
  });

  testWidgets('legacy 9 Sets warn but allow Name-only without Set rewrite',
      (tester) async {
    final f = _Fixtures();
    final historical = RoutineCompositionEntry(
      id: _entryId,
      exercise: ExerciseRef.catalog(_exerciseRef),
      sets: [
        for (var index = 0; index < 9; index++)
          RoutineCompositionSet(
            id: '50000000-0000-4000-8000-${index.toString().padLeft(12, '0')}',
            prescription: SetPrescription(reps: 8),
          ),
      ],
    );
    f.compositions.snapshot = _snapshot(entries: [historical]);
    await f.open(tester);
    expect(find.byKey(const ValueKey('edit-routine-too-many-sets')),
        findsOneWidget);
    expect(find.textContaining('renaming alone is still available'),
        findsOneWidget);
    final update = find.byKey(const ValueKey('edit-routine-update'));
    expect(update, findsOneWidget);
    expect(tester.widget<TextButton>(update).onPressed, isNotNull);
    await tester.enterText(find.byKey(const ValueKey('edit-routine-name')),
        'Rename Historical');
    await tester.pumpAndSettle();
    await tester.tap(update);
    await tester.pumpAndSettle();
    expect(f.compositions.aggregateCalls, 1);
    expect(f.compositions.lastAggregate!.entries, isNull);
    expect(f.compositions.saveCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty Routine offers Add Exercise without a database write',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: const []);
    await f.open(tester);
    expect(find.byKey(const ValueKey('edit-routine-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercises-page')),
        findsOneWidget);
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-entry-90000000-0000-4000-8000-000000000001')),
        findsOneWidget);
    expect(f.compositions.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('edit-routine-cancel')));
    await tester.pumpAndSettle();
    expect(f.editorResult, isFalse);
    expect(f.compositions.saveCount, 0);
  });

  testWidgets('picker returns freshly created Custom even when editor source is stale',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: const []);
    await f.open(tester);
    expect(f.users.listCalls, 1);

    // A second device created this exercise after editor _source loaded.
    // The picker loads a new owner-scoped snapshot that includes it.
    f.users.rows = [
      Exercise(
        ref: UserCreatedExerciseRef(_newCustomRef),
        displayName: 'Fresh Custom Lift',
        status: ExerciseStatus.active,
      ),
    ];
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    expect(find.text('Fresh Custom Lift'), findsOneWidget);
    expect(f.users.listCalls, 2);
    await tester.tap(find.text('Fresh Custom Lift'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    await _fillNewSet(tester);

    expect(find.byKey(const ValueKey(
        'edit-routine-entry-90000000-0000-4000-8000-000000000001')),
        findsOneWidget);
    expect(find.text('Fresh Custom Lift'), findsOneWidget);
    expect(f.users.listCalls, 3); // Refresh editor source for safe Update.
    expect(f.compositions.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    expect(f.users.listCalls, 4); // Controller rechecks active owner refs.
    expect(f.compositions.lastSave!.entries.single.exercise,
        UserCreatedExerciseRef(_newCustomRef));
    expect(f.editorResult, isTrue);
    expect(f.users.writeCalls, 0);
  });

  testWidgets('archived Custom after selection cannot reach composition RPC',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: const []);
    f.users.rows = [
      Exercise(
        ref: UserCreatedExerciseRef(_newCustomRef),
        displayName: 'Remote Archive Candidate',
        status: ExerciseStatus.active,
      ),
    ];
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remote Archive Candidate'));
    await tester.pumpAndSettle();
    expect(find.text('Add 1 exercise'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    await _fillNewSet(tester);
    expect(f.compositions.saveCount, 0);

    // Another device archives the Exercise after picker selection.
    // The owner-inclusive preflight now sees its archived status, rather
    // than treating the exercise as missing. A newly added archived entry
    // is never an unchanged historical reference.
    f.users.rows = [
      Exercise(
        ref: UserCreatedExerciseRef(_newCustomRef),
        displayName: 'Remote Archive Candidate',
        status: ExerciseStatus.archived,
      ),
    ];
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(find.textContaining('archived Custom Exercise'), findsOneWidget);
    expect(f.compositions.saveCount, 0);
    expect(f.editorResult, isNull);

    // The archived entry can still be REMOVED, then Update is permitted.
    await _removeExerciseMenu(tester,
        '90000000-0000-4000-8000-000000000001');
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    // The only draft change was adding the Custom Exercise; removing it
    // restores the original empty composition. A confirmed no-op Update
    // returns to Detail without manufacturing a revision or RPC write.
    expect(f.compositions.saveCount, 0);
    expect(f.compositions.lastSave, isNull);
    expect(f.editorResult, isTrue);
  });

  testWidgets('Custom lookup failure before RPC is retryable, not unknown commit',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: const []);
    f.users.rows = [
      Exercise(
        ref: UserCreatedExerciseRef(_newCustomRef),
        displayName: 'My Custom Lift',
        status: ExerciseStatus.active,
      ),
    ];
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Custom Lift'));
    await tester.pumpAndSettle();
    expect(find.text('Add 1 exercise'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    await _fillNewSet(tester);

    f.users.listFailure = StateError('offline');
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not verify Custom Exercises'), findsOneWidget);
    expect(f.compositions.saveCount, 0);
    expect(find.byKey(const ValueKey('edit-routine-unknown')), findsNothing);

    f.users.listFailure = null;
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    expect(f.editorResult, isTrue);
  });


  testWidgets('Cancel remains available during an unresolved Custom preflight',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: const []);
    f.users.rows = [
      Exercise(
        ref: UserCreatedExerciseRef(_newCustomRef),
        displayName: 'My Custom Lift',
        status: ExerciseStatus.active,
      ),
    ];
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Custom Lift'));
    await tester.pumpAndSettle();
    expect(find.text('Add 1 exercise'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    await _fillNewSet(tester);

    f.users.listGate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pump();
    expect(find.byKey(const ValueKey('edit-routine-verifying')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-routine-cancel')));
    await tester.pumpAndSettle();
    expect(f.editorResult, isFalse);
    f.users.listGate!.complete();
    await tester.pump();
    expect(f.compositions.saveCount, 0);
  });

  testWidgets('changed live login capability blocks RPC after Custom preflight',
      (tester) async {
    var allowed = true;
    final f = _Fixtures(canWrite: () => allowed);
    f.compositions.snapshot = _snapshot(entries: const []);
    f.users.rows = [
      Exercise(
        ref: UserCreatedExerciseRef(_newCustomRef),
        displayName: 'My Custom Lift',
        status: ExerciseStatus.active,
      ),
    ];
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Custom Lift'));
    await tester.pumpAndSettle();
    expect(find.text('Add 1 exercise'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    await _fillNewSet(tester);

    f.users.listGate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pump();
    expect(find.byKey(const ValueKey('edit-routine-verifying')), findsOneWidget);
    allowed = false;
    f.users.listGate!.complete();
    await tester.pump();
    await tester.pump();
    expect(f.compositions.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('edit-routine-cancel')));
    await tester.pumpAndSettle();
    expect(f.editorResult, isFalse);
  });

  testWidgets('Custom preflight timeout returns to retry without RPC',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: const []);
    f.users.rows = [
      Exercise(
        ref: UserCreatedExerciseRef(_newCustomRef),
        displayName: 'My Custom Lift',
        status: ExerciseStatus.active,
      ),
    ];
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Custom Lift'));
    await tester.pumpAndSettle();
    expect(find.text('Add 1 exercise'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    await _fillNewSet(tester);

    f.users.listGate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pump();
    expect(find.byKey(const ValueKey('edit-routine-verifying')), findsOneWidget);
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.textContaining('Could not verify Custom Exercises'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-routine-update')), findsOneWidget);
    expect(f.compositions.saveCount, 0);
    f.users.listGate!.complete();
    await tester.pump();
  });

  testWidgets('Edit title long press and semantics reorder without writing',
      (tester) async {
    const secondId = '30000000-0000-4000-8000-000000000002';
    const secondSetId = '40000000-0000-4000-8000-000000000002';
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: [
      _entry(),
      RoutineCompositionEntry(
        id: secondId,
        exercise: ExerciseRef.catalog(_exerciseRef),
        sets: [
          RoutineCompositionSet(
            id: secondSetId,
            prescription: SetPrescription(reps: 8),
          ),
        ],
      ),
    ]);
    await f.open(tester);
    expect(find.byType(SliverReorderableList), findsOneWidget);
    final first = find.byKey(const ValueKey('edit-routine-entry-$_entryId'));
    final second = find.byKey(const ValueKey('edit-routine-entry-$secondId'));
    final drag = find.byKey(const ValueKey('edit-routine-drag-$_entryId'));
    final secondSemantics = find.byKey(
      const ValueKey('edit-routine-reorder-semantics-$secondId'),
    );
    final actions = tester.widget<Semantics>(secondSemantics)
        .properties.customSemanticsActions!;
    expect(actions.keys.map((action) => action.label),
        contains('Move exercise up'));

    await tester.ensureVisible(drag);
    final distance =
        tester.getTopLeft(second).dy - tester.getTopLeft(first).dy -
            TioSpacing.lg;
    expect(distance, greaterThan(0));
    final gesture = await tester.startGesture(tester.getCenter(drag));
    await tester.pump(const Duration(milliseconds: 700));
    for (var step = 0; step < 10; step++) {
      await gesture.moveBy(Offset(0, distance / 10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getTopLeft(first).dy,
        greaterThan(tester.getTopLeft(second).dy));

    final moveDown = tester.widget<Semantics>(secondSemantics)
        .properties.customSemanticsActions!.entries
        .singleWhere((entry) => entry.key.label == 'Move exercise down')
        .value;
    moveDown();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dy,
        lessThan(tester.getTopLeft(second).dy));
    expect(f.compositions.saveCount, 0);
  });

  testWidgets('Set Type picker omits advanced details; inline edits preserve rest',
      (tester) async {
    final f = _Fixtures();
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('routine-set-type-$_setId')));
    await tester.pumpAndSettle();
    expect(find.text('Select Set Type'), findsOneWidget);
    expect(find.text('Rest & set details'), findsNothing);
    expect(find.byKey(const ValueKey('edit-routine-set-details')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('edit-routine-type-warm_up')));
    await tester.pumpAndSettle();

    final reps = find.byKey(const ValueKey('routine-set-reps-$_setId'));
    final weight = find.byKey(const ValueKey('routine-set-weight-$_setId'));
    await tester.enterText(reps, '15');
    await tester.enterText(weight, '32.75');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();

    final saved = f.compositions.lastSave!.entries.single.sets.single;
    expect(saved.id, _setId);
    expect(saved.prescription.setType, RoutineSetType.warmUp);
    expect(saved.prescription.reps, 15);
    expect(saved.prescription.loadKg, 32.75);
    expect(saved.prescription.restSeconds, 60,
        reason: 'Removing the legacy Rest UI must never clear saved rest');
  });

  testWidgets('valid new Edit Set Reps remain visible after rejected Update',
      (tester) async {
    final f = _Fixtures();
    f.compositions.error = const RoutineCompositionException(
      RoutineCompositionFailureKind.invalidRequest,
    );
    await f.open(tester);
    final add = find.byKey(const ValueKey('edit-routine-add-set-$_entryId'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    const newSetId = '90000000-0000-4000-8000-000000000001';
    final reps = find.byKey(const ValueKey('routine-set-reps-$newSetId'));
    expect(reps, findsOneWidget);
    await tester.enterText(reps, '12');
    await tester.pump();
    expect(tester.widget<TioInput>(reps).controller!.text, '12');
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    expect(f.editorResult, isNull);
    expect(tester.widget<TioInput>(reps).controller!.text, '12',
      reason: 'Rejected RPC must not remount a typed Set as blank');
    final written = f.compositions.lastSave!.entries.single.sets.last;
    expect(written.id, newSetId);
    expect(written.prescription.reps, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Set Type and inline Reps survive rejected Update',
      (tester) async {
    final f = _Fixtures();
    f.compositions.error = const RoutineCompositionException(
      RoutineCompositionFailureKind.invalidRequest,
    );
    await f.open(tester);
    await tester.tap(find.byKey(const ValueKey('routine-set-type-$_setId')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-set-details')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('edit-routine-type-drop')));
    await tester.pumpAndSettle();

    final reps = find.byKey(const ValueKey('routine-set-reps-$_setId'));
    await tester.enterText(reps, '12');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();

    expect(f.compositions.saveCount, 1);
    expect(f.editorResult, isNull);
    expect(tester.widget<TioInput>(reps).controller!.text, '12');
    final pending = f.compositions.lastSave!.entries.single.sets.single;
    expect(pending.id, _setId);
    expect(pending.prescription.setType, RoutineSetType.drop);
    expect(pending.prescription.reps, 12);
    expect(pending.prescription.restSeconds, 60);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline Edit retains precise kg and Set UUID', (tester) async {
    final f = _Fixtures(unit: WeightUnit.lb);
    await f.open(tester);
    expect(find.text('PREVIOUS'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-set-reps-$_setId')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-set-weight-$_setId')),
        findsOneWidget);
    expect(find.byType(RoutineSetEditorSheet), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('routine-set-reps-$_setId')), '12');
    await tester.pump();
    expect(f.compositions.saveCount, 0);
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    final saved = f.compositions.lastSave!;
    expect(saved.expectedRevision, 4);
    expect(saved.entries.single.id, _entryId);
    expect(saved.entries.single.sets.single.id, _setId);
    expect(saved.entries.single.sets.single.prescription.reps, 12);
    expect(saved.entries.single.sets.single.prescription.loadKg, 12.54321);
    expect(f.editorResult, isTrue);
  });

  testWidgets('legacy treadmill prescriptions remain editable as KG/REPS',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: [
      RoutineCompositionEntry(
        id: _entryId,
        exercise: ExerciseRef.catalog('ex_run_on_treadmill'),
        sets: [
          RoutineCompositionSet(
            id: _setId,
            prescription: SetPrescription(reps: 8, loadKg: 12),
          ),
        ],
      ),
    ]);
    await f.open(tester);
    expect(find.text('KG'), findsOneWidget);
    expect(find.text('REPS'), findsOneWidget);
    expect(find.text('KM'), findsNothing);
    expect(find.text('TIME'), findsNothing);
    final reps = find.byKey(const ValueKey('routine-set-reps-$_setId'));
    final weight = find.byKey(const ValueKey('routine-set-weight-$_setId'));
    expect(tester.widget<TioInput>(reps).controller!.text, '8');
    expect(tester.widget<TioInput>(weight).controller!.text, '12');
    await tester.enterText(reps, '9');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    final saved = f.compositions.lastSave!.entries.single.sets.single;
    expect(saved.id, _setId);
    expect(saved.prescription.reps, 9);
    expect(saved.prescription.loadKg, 12);
    expect(saved.prescription.distanceMeters, isNull);
    expect(saved.prescription.durationSeconds, isNull);
  });

  testWidgets('inline range keeps Warm Up, UUID, kg and rest', (tester) async {
    final f = _Fixtures(unit: WeightUnit.lb);
    f.compositions.snapshot = _snapshot(entries: [
      _entry(kg: 12.54321, reps: 8, repsMax: 12,
          setType: RoutineSetType.warmUp, rest: 60),
    ]);
    await f.open(tester);
    final min = find.byKey(const ValueKey('routine-set-reps-$_setId'));
    final max = find.byKey(const ValueKey('routine-set-reps-max-$_setId'));
    expect(min, findsOneWidget);
    expect(max, findsOneWidget);
    await tester.enterText(max, '7');
    await tester.pump();
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('edit-routine-update'))), isNotNull);
    await tester.enterText(min, '9');
    await tester.enterText(max, '13');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    final row = f.compositions.lastSave!.entries.single.sets.single;
    expect(row.id, _setId);
    expect(row.prescription.setType, RoutineSetType.warmUp);
    expect(row.prescription.reps, 9);
    expect(row.prescription.repsMax, 13);
    expect(row.prescription.loadKg, 12.54321);
    expect(row.prescription.restSeconds, 60);
    expect(f.editorResult, isTrue);
  });

  testWidgets('clearing persisted Range bounds keeps Range until mode changes',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: [
      _entry(reps: 8, repsMax: 12, rest: 60),
    ]);
    await f.open(tester);
    final min = find.byKey(const ValueKey('routine-set-reps-$_setId'));
    final max = find.byKey(const ValueKey('routine-set-reps-max-$_setId'));
    expect(max, findsOneWidget);

    await tester.enterText(min, '');
    await tester.pump();
    await tester.enterText(max, '');
    await tester.pumpAndSettle();
    // Empty nullable targets are allowed, but the user's Range selection
    // stays visible; it must not silently collapse to fixed Reps.
    expect(min, findsOneWidget);
    expect(max, findsOneWidget);
    expect(tester.widget<TioInput>(min).controller!.text, isEmpty);
    expect(tester.widget<TioInput>(max).controller!.text, isEmpty);

    final update = find.byKey(const ValueKey('edit-routine-update'));
    expect(tester.widget<TextButton>(update).onPressed, isNotNull);
    await tester.tap(update);
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    final saved = f.compositions.lastSave!.entries.single.sets.single;
    expect(saved.prescription.reps, isNull);
    expect(saved.prescription.repsMax, isNull);
    expect(saved.prescription.restSeconds, 60);
    expect(saved.id, _setId);
  });

  testWidgets('clearing inline Range bounds retains nullable Set and rest',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: [
      _entry(reps: 8, repsMax: 12, rest: 60),
    ]);
    await f.open(tester);
    final min = find.byKey(const ValueKey('routine-set-reps-$_setId'));
    final max = find.byKey(const ValueKey('routine-set-reps-max-$_setId'));
    expect(min, findsOneWidget);
    expect(max, findsOneWidget);
    await tester.enterText(min, '');
    await tester.enterText(max, '');
    await tester.pump();
    expect(tester.widget<TioInput>(min).controller!.text, isEmpty);
    expect(tester.widget<TioInput>(max).controller!.text, isEmpty);
    expect(f.compositions.saveCount, 0);

    final update = find.byKey(const ValueKey('edit-routine-update'));
    expect(tester.widget<TextButton>(update).onPressed, isNotNull);
    await tester.tap(update);
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    final saved = f.compositions.lastSave!.entries.single.sets.single;
    expect(saved.id, _setId);
    expect(saved.prescription.reps, isNull);
    expect(saved.prescription.repsMax, isNull);
    expect(saved.prescription.restSeconds, 60);
  });

  testWidgets('loaded Rep Range plus blank Set blocks mixed Update until filled',
      (tester) async {
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: [
      _entry(reps: 8, repsMax: 12),
    ]);
    await f.open(tester);
    final addSet = find.byKey(
        const ValueKey('edit-routine-add-set-$_entryId'));
    await tester.ensureVisible(addSet);
    await tester.tap(addSet);
    await tester.pumpAndSettle();
    const newSet = '90000000-0000-4000-8000-000000000001';
    final min = find.byKey(const ValueKey('routine-set-reps-$newSet'));
    final max = find.byKey(const ValueKey('routine-set-reps-max-$newSet'));
    expect(min, findsOneWidget);
    expect(max, findsOneWidget);
    final update = find.byKey(const ValueKey('edit-routine-update'));
    expect(tester.widget<TextButton>(update).onPressed, isNull);
    expect(f.compositions.saveCount, 0);

    await tester.enterText(min, '10');
    await tester.pump();
    expect(tester.widget<TextButton>(update).onPressed, isNull);
    await tester.enterText(max, '15');
    await tester.pump();
    expect(tester.widget<TextButton>(update).onPressed, isNotNull);
    await tester.tap(update);
    await tester.pumpAndSettle();
    expect(f.compositions.saveCount, 1);
    final saved = f.compositions.lastSave!.entries.single.sets;
    expect(saved.length, 2);
    expect(saved.first.prescription.repsMax, 12);
    expect(saved.last.id, newSet);
    expect(saved.last.prescription.reps, 10);
    expect(saved.last.prescription.repsMax, 15);
  });

  testWidgets('inline Add Set blank permits Update; invalid typed Reps block',
      (tester) async {
    final f = _Fixtures();
    await f.open(tester);
    final addSet = find.byKey(const ValueKey('edit-routine-add-set-$_entryId'));
    await tester.ensureVisible(addSet);
    expect(tester.widget<TioButton>(addSet).variant,
        TioButtonVariant.supporting);
    final addSetHeight = tester.getSize(addSet).height;
    expect(addSetHeight, greaterThanOrEqualTo(TioButtonTokens.height));
    expect(addSetHeight, lessThanOrEqualTo(TioSize.dp52));
    expect(find.descendant(of: addSet, matching: find.byIcon(Icons.add)),
        findsOneWidget);
    await tester.tap(addSet);
    await tester.pumpAndSettle();
    expect(find.byType(RoutineSetEditorSheet), findsNothing);
    const newSet = '90000000-0000-4000-8000-000000000001';
    final reps = find.byKey(const ValueKey('routine-set-reps-$newSet'));
    expect(tester.widget<TioInput>(reps).controller!.text, isEmpty);
    final update = find.byKey(const ValueKey('edit-routine-update'));
    expect(tester.widget<TextButton>(update).onPressed, isNotNull);
    await tester.enterText(reps, '0');
    await tester.pump();
    expect(tester.widget<TextButton>(update).onPressed, isNull);
    expect(f.compositions.saveCount, 0);
    await tester.enterText(reps, '6');
    await tester.enterText(find.byKey(
      const ValueKey('routine-set-weight-$newSet')), '22.5');
    await tester.pump();
    expect(tester.widget<TextButton>(update).onPressed, isNotNull);
    await tester.tap(update);
    await tester.pumpAndSettle();
    final added = f.compositions.lastSave!.entries.single.sets.last;
    expect(added.prescription.reps, 6);
    expect(added.prescription.restSeconds, isNull);
    expect(added.prescription.loadKg, 22.5);
    expect(added.id, isNot(_setId));
  });

  testWidgets('320dp dark Edit table retains Previous and range inputs',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final f = _Fixtures();
    f.compositions.snapshot = _snapshot(entries: [
      _entry(reps: 8, repsMax: 12, setType: RoutineSetType.warmUp),
    ]);
    await f.open(tester, mode: TioThemeMode.dark);
    expect(find.text('PREVIOUS'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-set-reps-$_setId')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-set-reps-max-$_setId')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(f.compositions.saveCount, 0);
  });

  testWidgets('no repository and cross-Program fail closed', (tester) async {
    final missing = _Fixtures(repositoryAvailable: false);
    await missing.open(tester);
    expect(find.byKey(const ValueKey('edit-routine-unavailable')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-routine-update')), findsNothing);
    expect(missing.compositions.readCount, 0);

    // Dispose the first Navigator stack before creating a second fixture.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final cross = _Fixtures(
      routine: Routine(
        id: RoutineId(_r),
        programId: ProgramId(_other),
        name: 'Other',
      ),
    );
    await cross.open(tester);
    expect(find.byKey(const ValueKey('edit-routine-unavailable')),
        findsOneWidget);
    expect(cross.compositions.readCount, 0);
  });

  testWidgets('missing weight unit blocks form and write', (tester) async {
    final f = _Fixtures(unit: null);
    await f.open(tester);
    expect(find.byKey(const ValueKey('edit-routine-unavailable')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-routine-update')), findsNothing);
    expect(f.compositions.saveCount, 0);
  });

  testWidgets('revision conflict offers explicit Reload, no second save',
      (tester) async {
    final f = _Fixtures();
    f.compositions.error = const RoutineCompositionException(
      RoutineCompositionFailureKind.revisionConflict,
    );
    await f.open(tester);
    await _removeExerciseMenu(tester, _entryId);
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-conflict')), findsOneWidget);
    expect(f.compositions.saveCount, 1);
    expect(find.byKey(const ValueKey('edit-routine-reload')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-routine-reload')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-entry-$_entryId')),
        findsOneWidget);
    expect(f.compositions.saveCount, 1);
  });

  testWidgets('uncertain Update only confirms by matching mutation read',
      (tester) async {
    final f = _Fixtures();
    f.compositions.error = const RoutineCompositionSaveOutcomeUnknown();
    await f.open(tester);
    await _removeExerciseMenu(tester, _entryId);
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-unknown')), findsOneWidget);
    expect(f.compositions.saveCount, 1);
    await tester.tap(find.byKey(const ValueKey('edit-routine-verify')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-unknown')), findsOneWidget);
    expect(f.compositions.saveCount, 1);

    f.compositions.snapshot = _snapshot(
      entries: const [],
      revision: 5,
      mutation: f.compositions.lastSave!.mutationId,
    );
    await tester.tap(find.byKey(const ValueKey('edit-routine-verify')));
    await tester.pumpAndSettle();
    expect(f.editorResult, isTrue);
    expect(f.compositions.saveCount, 1);
  });

  testWidgets('large Routine is lazy, editor reaches first Set safely',
      (tester) async {
    final f = _Fixtures();
    final large = [
      for (var i = 1; i <= 1007; i++)
        RoutineCompositionSet(
          id: '40000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
          prescription: SetPrescription(reps: 8),
        ),
    ];
    f.compositions.snapshot = _snapshot(entries: [
      RoutineCompositionEntry(
        id: _entryId,
        exercise: ExerciseRef.catalog(_exerciseRef),
        sets: large,
      ),
    ]);
    await f.open(tester, mode: TioThemeMode.dark);
    expect(find.byKey(const ValueKey('edit-routine-set-list-$_entryId')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('edit-routine-set-40000000-0000-4000-8000-000000001007')),
        findsNothing);
    expect(tester.takeException(), isNull);
    expect(f.compositions.saveCount, 0);
  });
}

final class _Catalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([
    Exercise(
      ref: ExerciseRef.catalog(_exerciseRef),
      displayName: 'Bench Press',
      status: ExerciseStatus.active,
    ),
    Exercise(
      ref: ExerciseRef.catalog('ex_run_on_treadmill'),
      displayName: 'Run on Treadmill',
      status: ExerciseStatus.active,
      exerciseType: ExerciseType.distanceDuration,
    ),
  ]);
}

final class _Routines implements RoutineRepository {
  @override
  Future<List<Routine>> list(ProgramId id) async => [_routine];

  @override
  Future<void> create(Routine routine) async => throw UnimplementedError();

  @override
  Future<void> rename({required RoutineId id, required String name}) async =>
      throw UnimplementedError();
}

final class _Compositions implements RoutineCompositionRepository, RoutineAggregateUpdateRepository {
  _Compositions(this.snapshot);
  RoutineCompositionSnapshot? snapshot;
  int readCount = 0;
  int saveCount = 0;
  int aggregateCalls = 0;
  RoutineAggregateUpdate? lastAggregate;
  RoutineCompositionSave? lastSave;
  Object? error;
  Completer<void>? saveGate;

  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId id) async {
    readCount++;
    return snapshot;
  }

  @override
  Future<int> updateAggregate(RoutineAggregateUpdate command) async {
    aggregateCalls++;
    lastAggregate = command;
    if (saveGate != null) await saveGate!.future;
    if (error != null) throw error!;
    snapshot = _snapshot(
      entries: command.entries ?? snapshot!.entries,
      revision: command.expectedRevision + 1,
      mutation: command.mutationId,
      name: command.savedName,
    );
    return command.expectedRevision + 1;
  }

  @override
  Future<int> save(RoutineCompositionSave command) async {
    saveCount++;
    lastSave = command;
    if (saveGate != null) await saveGate!.future;
    if (error != null) throw error!;
    snapshot = _snapshot(
      entries: command.entries,
      revision: command.expectedRevision + 1,
      mutation: command.mutationId,
    );
    return command.expectedRevision + 1;
  }
}

final class _Users implements UserExerciseRepository {
  List<Exercise> rows = const [];
  int listCalls = 0;
  int writeCalls = 0;
  Object? listFailure;
  Completer<void>? listGate;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async {
    listCalls++;
    if (listGate != null) await listGate!.future;
    if (listFailure case final error?) throw error;
    return List.unmodifiable(rows.where(
      (item) => includeArchived || item.status == ExerciseStatus.active,
    ));
  }

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async {
    writeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> updateDefinition({
    required UserCreatedExerciseRef id,
    required UserExerciseDefinition definition,
  }) async {
    writeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async {
    writeCalls++;
    throw UnimplementedError();
  }

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {
    writeCalls++;
    throw UnimplementedError();
  }
}
