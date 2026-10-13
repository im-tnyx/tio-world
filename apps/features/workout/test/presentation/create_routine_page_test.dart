import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('picker adds Set 1 and enables a single atomic Save',
      (tester) async {
    final create = _Create();
    var index = 0;
    final uuids = [
      '44444444-4444-4444-8444-444444444444',
      '55555555-5555-4555-8555-555555555555',
      '22222222-2222-4222-8222-222222222222',
      '33333333-3333-4333-8333-333333333333',
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: create,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
        newUuid: () => uuids[index++],
      ),
    ));
    await tester.tap(
      find.byKey(const ValueKey('create-routine-add-exercise')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-picker-page')),
        findsOneWidget);
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(
        'create-routine-set-55555555-5555-4555-8555-555555555555')),
        findsOneWidget);
    expect(find.text('KG'), findsOneWidget);
    expect(find.text('REPS'), findsOneWidget);
    expect(tester.widget<TextButton>(
        find.byKey(const ValueKey('create-routine-save'))).onPressed,
        isNotNull);
    expect(create.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pump();
    expect(create.calls, 1);
    expect(create.command!.entries.single.sets.single.prescription.reps, 1);
    expect(create.command!.entries.single.sets.single.prescription.loadKg,
        isNull);
  });

  testWidgets('Add Set appends inline row immediately; invalid Reps block Save',
      (tester) async {
    final create = _Create();
    var index = 0;
    const set1 = '55555555-5555-4555-8555-555555555555';
    const set2 = '66666666-6666-4666-8666-666666666666';
    final uuids = [
      '44444444-4444-4444-8444-444444444444',
      set1,
      set2,
      '22222222-2222-4222-8222-222222222222',
      '33333333-3333-4333-8333-333333333333',
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: create,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
        newUuid: () => uuids[index++],
      ),
    ));
    await tester.tap(find.byKey(
      const ValueKey('create-routine-add-exercise'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    final addSet = find.byKey(
      const ValueKey('create-routine-add-set-44444444-4444-4444-8444-444444444444'),
    );
    await tester.ensureVisible(addSet);
    await tester.tap(addSet);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('create-routine-set-$set1')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('create-routine-set-$set2')),
        findsOneWidget);
    expect(find.byType(RoutineSetEditorSheet), findsNothing);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(create.calls, 0);

    final reps = find.byKey(const ValueKey('routine-set-reps-$set2'));
    await tester.ensureVisible(reps);
    await tester.enterText(reps, '');
    await tester.pump();
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save')),
    ).onPressed, isNull);
    expect(create.calls, 0);

    await tester.enterText(reps, '12');
    await tester.pump();
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save')),
    ).onPressed, isNotNull);

    final weight = find.byKey(const ValueKey('routine-set-weight-$set2'));
    await tester.enterText(weight, '25.5');
    await tester.pump();
    expect(create.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pump();
    expect(create.calls, 1);
    final sets = create.command!.entries.single.sets;
    expect(sets, hasLength(2));
    expect(sets.first.id, set1);
    expect(sets.first.prescription.reps, 1);
    expect(sets.last.id, set2);
    expect(sets.last.prescription.reps, 12);
    expect(sets.last.prescription.loadKg, 25.5);
  });

  testWidgets('Removing invalid inline Set restores Save without stale values',
      (tester) async {
    final create = _Create();
    var index = 0;
    const set2 = '66666666-6666-4666-8666-666666666666';
    final uuids = [
      '44444444-4444-4444-8444-444444444444',
      '55555555-5555-4555-8555-555555555555',
      set2,
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: create,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
        newUuid: () => uuids[index++],
      ),
    ));
    await tester.tap(find.byKey(
      const ValueKey('create-routine-add-exercise'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    final addSet = find.byKey(const ValueKey(
      'create-routine-add-set-44444444-4444-4444-8444-444444444444',
    ));
    await tester.ensureVisible(addSet);
    await tester.tap(addSet);
    await tester.pumpAndSettle();
    final reps = find.byKey(const ValueKey('routine-set-reps-$set2'));
    await tester.ensureVisible(reps);
    await tester.enterText(reps, '0');
    await tester.pump();
    final save = find.byKey(const ValueKey('create-routine-save'));
    expect(tester.widget<TextButton>(save).onPressed, isNull);
    final swipe = find.byKey(const ValueKey('routine-set-swipe-$set2'));
    final remove = find.byKey(const ValueKey('routine-set-remove-$set2'));
    expect(tester.widget<TextButton>(remove).onPressed, isNull);
    await tester.ensureVisible(swipe);
    await tester.drag(swipe, const Offset(-140, 0));
    await tester.pumpAndSettle();
    // Revealing does not delete an invalid draft Set by itself.
    expect(find.byKey(const ValueKey('create-routine-set-$set2')),
        findsOneWidget);
    expect(tester.widget<TextButton>(remove).onPressed, isNotNull);
    expect(create.calls, 0);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-set-$set2')),
        findsNothing);
    expect(tester.widget<TextButton>(save).onPressed, isNotNull);
    expect(create.calls, 0);
  });

  testWidgets('Only one Set reveals Delete; reverse swipe closes without write',
      (tester) async {
    final create = _Create();
    var index = 0;
    const first = '55555555-5555-4555-8555-555555555555';
    const second = '66666666-6666-4666-8666-666666666666';
    final ids = [
      '44444444-4444-4444-8444-444444444444',
      first, second,
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: create,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
        newUuid: () => ids[index++],
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    final addSet = find.byKey(const ValueKey(
      'create-routine-add-set-44444444-4444-4444-8444-444444444444',
    ));
    await tester.ensureVisible(addSet);
    await tester.tap(addSet);
    await tester.pumpAndSettle();

    final firstSwipe = find.byKey(const ValueKey('routine-set-swipe-$first'));
    final secondSwipe = find.byKey(const ValueKey('routine-set-swipe-$second'));
    final firstDelete = find.byKey(const ValueKey('routine-set-remove-$first'));
    final secondDelete = find.byKey(const ValueKey('routine-set-remove-$second'));
    expect(tester.widget<TextButton>(firstDelete).onPressed, isNull);
    expect(tester.widget<TextButton>(secondDelete).onPressed, isNull);

    await tester.ensureVisible(firstSwipe);
    await tester.drag(firstSwipe, const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(firstDelete).onPressed, isNotNull);
    expect(tester.widget<TextButton>(secondDelete).onPressed, isNull);
    expect(find.byKey(const ValueKey('create-routine-set-$first')),
        findsOneWidget);

    await tester.drag(secondSwipe, const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(firstDelete).onPressed, isNull);
    expect(tester.widget<TextButton>(secondDelete).onPressed, isNotNull);

    await tester.drag(secondSwipe, const Offset(140, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(secondDelete).onPressed, isNull);
    expect(find.byKey(const ValueKey('create-routine-set-$first')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('create-routine-set-$second')),
        findsOneWidget);
    expect(create.calls, 0);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
  });

  testWidgets('lb inline Weight converts once to canonical kg on Save',
      (tester) async {
    final create = _Create();
    var index = 0;
    const set1 = '55555555-5555-4555-8555-555555555555';
    final uuids = [
      '44444444-4444-4444-8444-444444444444',
      set1,
      '22222222-2222-4222-8222-222222222222',
      '33333333-3333-4333-8333-333333333333',
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: create,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.lb,
        newUuid: () => uuids[index++],
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    expect(find.text('LB'), findsOneWidget);
    final weight = find.byKey(const ValueKey('routine-set-weight-$set1'));
    await tester.ensureVisible(weight);
    await tester.enterText(weight, '44');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pump();
    expect(create.calls, 1);
    expect(create.command!.entries.single.sets.single.prescription.loadKg,
        closeTo(UnitConverters.lbToKg(44), 0.000001));
  });

  testWidgets('Create reference empty state has disabled Save and Add exercise',
      (tester) async {
    final create = _Create();
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: create,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
      ),
    ));
    expect(find.text('Create Routine'), findsOneWidget);
    final name = find.descendant(
      of: find.byKey(const ValueKey('create-routine-name')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(name).controller.text, 'Routine 1');
    expect(find.textContaining('Get started by adding'), findsOneWidget);
    expect(find.byKey(const ValueKey('create-routine-add-exercise')),
        findsOneWidget);
    final save = tester.widget<TextButton>(
        find.byKey(const ValueKey('create-routine-save')));
    expect(save.onPressed, isNull);
    expect(create.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-cancel')));
    await tester.pumpAndSettle();
    expect(create.calls, 0);
  });
}

class _Catalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([
        Exercise(
          ref: ExerciseRef.catalog('ex_bench_press'),
          displayName: 'Bench Press',
          status: ExerciseStatus.active,
        ),
      ]);
}

class _Create implements RoutineCreateRepository {
  int calls = 0;
  RoutineCreateCommand? command;
  @override
  Future<int> create(RoutineCreateCommand value) async {
    calls++;
    command = value;
    return 1;
  }
}
