import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('picker creates an identified Set; blank targets may Save',
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
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
    expect(find.byKey(const ValueKey('routine-composer-screen')),
        findsOneWidget);
    expect(find.text('Create Routine'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('create-routine-add-exercise')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercises-page')),
        findsOneWidget);
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(
        'create-routine-set-55555555-5555-4555-8555-555555555555')),
        findsOneWidget);
    expect(find.text('KG'), findsOneWidget);
    expect(find.text('REPS'), findsOneWidget);
    final reps = find.byKey(const ValueKey('routine-set-reps-55555555-5555-4555-8555-555555555555'));
    expect(tester.widget<TioInput>(reps).controller!.text, isEmpty);
    expect(tester.widget<TextButton>(
        find.byKey(const ValueKey('create-routine-save'))).onPressed,
        isNotNull);
    expect(create.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pump();
    expect(create.calls, 1);
    expect(create.command!.entries.single.sets.single.prescription.reps, isNull);
    expect(create.command!.entries.single.sets.single.prescription.loadKg,
        isNull);
  });


  testWidgets('batch Add two Exercises creates ordered blank Set 1 drafts',
      (tester) async {
    final create = _Create();
    final ids = [
      '44444444-4444-4444-8444-444444444444',
      '55555555-5555-4555-8555-555555555555',
      '66666666-6666-4666-8666-666666666666',
      '77777777-7777-4777-8777-777777777777',
      // Save also allocates a Routine UUID and mutation UUID after
      // the two Exercise/Set identity pairs have been created.
      '88888888-8888-4888-8888-888888888888',
      '99999999-9999-4999-8999-999999999999',
    ].iterator;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
        newUuid: () {
          if (!ids.moveNext()) throw StateError('Unexpected UUID');
          return ids.current;
        },
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercises-add-selected')), findsNothing);
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run on Treadmill'));
    await tester.pumpAndSettle();
    expect(find.text('Add 2 exercises'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(
        'create-routine-entry-44444444-4444-4444-8444-444444444444')),
        findsOneWidget);
    expect(find.byKey(const ValueKey(
        'create-routine-entry-66666666-6666-4666-8666-666666666666')),
        findsOneWidget);
    expect(create.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pumpAndSettle();
    expect(create.calls, 1);
    expect(create.command!.entries.map((e) => e.exercise).toList(), [
      ExerciseRef.catalog('ex_bench_press'),
      ExerciseRef.catalog('ex_run_on_treadmill'),
    ]);
    expect(create.command!.entries.every((e) =>
        e.sets.length == 1 &&
        e.sets.single.prescription.reps == null), isTrue);
  });

  testWidgets('Run on Treadmill uses full-width KM/TIME instead of KG/REPS',
      (tester) async {
    final ids = [
      '44444444-4444-4444-8444-444444444444',
      '55555555-5555-4555-8555-555555555555',
    ].iterator;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: _Create(),
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
        newUuid: () {
          if (!ids.moveNext()) throw StateError('Unexpected UUID');
          return ids.current;
        },
      ),
    ));
    await tester.tap(find.byKey(
      const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run on Treadmill'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    expect(find.text('KM'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('KG'), findsNothing);
    expect(find.text('REPS'), findsNothing);
    const id = '55555555-5555-4555-8555-555555555555';
    final km = find.byKey(const ValueKey('routine-set-distance-$id'));
    final time = find.byKey(const ValueKey('routine-set-duration-$id'));
    expect(km, findsOneWidget);
    expect(time, findsOneWidget);
    expect(find.byKey(const ValueKey('routine-set-weight-$id')), findsNothing);
    expect(find.byKey(const ValueKey('routine-set-reps-$id')), findsNothing);
    final addSet = find.byKey(const ValueKey(
      'create-routine-add-set-44444444-4444-4444-8444-444444444444'));
    expect(tester.getTopRight(time).dx,
        closeTo(tester.getTopRight(addSet).dx, 0.01));
    expect(tester.takeException(), isNull);
  });

  for (final mode in [TioThemeMode.dark, TioThemeMode.light]) {
    testWidgets('Create Set/boxed number/Add Set rendered surfaces equal 38dp '
        'at 320dp in ${mode.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      var index = 0;
      const entryId = '44444444-4444-4444-8444-444444444444';
      const setId = '55555555-5555-4555-8555-555555555555';
      final uuids = [entryId, setId].iterator;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
        home: CreateRoutinePage(
          program: Program(
            id: ProgramId('11111111-1111-4111-8111-111111111111'),
            name: 'Program 1',
          ),
          initialName: 'Routine 1',
          createRepository: _Create(),
          catalogRepository: _Catalog(),
          weightUnit: WeightUnit.kg,
          newUuid: () {
            index++;
            if (!uuids.moveNext()) throw StateError('Unexpected UUID #$index');
            return uuids.current;
          },
        ),
      ));
      await tester.tap(find.byKey(
        const ValueKey('create-routine-add-exercise')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
      await tester.pumpAndSettle();

      final add = find.byKey(const ValueKey('create-routine-add-set-$entryId'));
      await tester.ensureVisible(add);
      final filled = find.descendant(of: add, matching: find.byType(FilledButton));
      final surface = find.descendant(
        of: filled, matching: find.byType(Material)).first;
      const expected = TioSize.dp38;
      expect(tester.getSize(surface).height, expected);
      expect(tester.getSize(find.byKey(
        const ValueKey('routine-set-type-box-$setId'))).height, expected);
      expect(tester.getSize(find.byKey(
        const ValueKey('routine-set-weight-$setId'))).height, expected);
      final reps = find.byKey(const ValueKey('routine-set-reps-$setId'));
      expect(tester.getSize(reps).height, expected);
      // In the approved reference, KG/REPS occupies the same full-width
      // right edge as Add Set, with no invisible 48dp trailing gutter.
      final swipe = find.byKey(const ValueKey('routine-set-swipe-$setId'));
      expect(tester.getTopRight(reps).dx,
          closeTo(tester.getTopRight(swipe).dx, 0.01));
      expect(tester.getTopRight(reps).dx,
          closeTo(tester.getTopRight(surface).dx, 0.01));
      // The Material hit target may be taller, without changing visual size.
      expect(tester.getSize(add).height, greaterThanOrEqualTo(expected));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Add Set appends blank valid row; invalid typed Reps block Save',
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
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();

    final addSet = find.byKey(
      const ValueKey('create-routine-add-set-44444444-4444-4444-8444-444444444444'),
    );
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

    expect(find.byKey(const ValueKey('create-routine-set-$set1')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('create-routine-set-$set2')),
        findsOneWidget);
    expect(find.byType(RoutineSetEditorSheet), findsNothing);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
    expect(create.calls, 0);
    final firstReps = find.byKey(const ValueKey('routine-set-reps-$set1'));
    final secondReps = find.byKey(const ValueKey('routine-set-reps-$set2'));
    expect(tester.widget<TioInput>(firstReps).controller!.text, isEmpty);
    expect(tester.widget<TioInput>(secondReps).controller!.text, isEmpty);

    final reps = secondReps;
    await tester.ensureVisible(reps);
    await tester.enterText(reps, '');
    await tester.pump();
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save')),
    ).onPressed, isNotNull);
    await tester.enterText(reps, '0');
    await tester.pump();
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save')),
    ).onPressed, isNull);
    expect(create.calls, 0);

    await tester.enterText(reps, '12');
    await tester.pump();
    // Untouched Set 1 is a legitimate blank template target.
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save')),
    ).onPressed, isNotNull);
    await tester.enterText(firstReps, '8');
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
    expect(sets.first.prescription.reps, 8);
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
        config: const TioThemeConfig(mode: TioThemeMode.light),
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
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    // Only the surviving, explicitly-entered Set makes Save available.
    await tester.enterText(
      find.byKey(const ValueKey(
        'routine-set-reps-55555555-5555-4555-8555-555555555555',
      )),
      '8',
    );
    await tester.pump();
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
    expect(remove, findsNothing,
        reason: 'Delete must not paint at rest');
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
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
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
    expect(firstDelete, findsNothing);
    expect(secondDelete, findsNothing);

    await tester.ensureVisible(firstSwipe);
    await tester.drag(firstSwipe, const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<TextButton>(firstDelete).onPressed, isNotNull);
    expect(secondDelete, findsNothing);
    expect(find.byKey(const ValueKey('create-routine-set-$first')),
        findsOneWidget);

    await tester.drag(secondSwipe, const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(firstDelete, findsNothing);
    expect(tester.widget<TextButton>(secondDelete).onPressed, isNotNull);

    await tester.drag(secondSwipe, const Offset(140, 0));
    await tester.pumpAndSettle();
    expect(secondDelete, findsNothing);
    expect(find.byKey(const ValueKey('create-routine-set-$first')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('create-routine-set-$second')),
        findsOneWidget);
    expect(create.calls, 0);
    expect(find.byKey(const ValueKey('tio-editor-sheet')), findsNothing);
  });

  testWidgets('full swipe deletes selected Set without a Delete tap and haptics',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String? ?? '');
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

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
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('routine-set-reps-$first')), '8');
    await tester.pump();
    final addSet = find.byKey(const ValueKey(
      'create-routine-add-set-44444444-4444-4444-8444-444444444444',
    ));
    await tester.ensureVisible(addSet);
    await tester.tap(addSet);
    await tester.pumpAndSettle();

    final secondSwipe = find.byKey(const ValueKey('routine-set-swipe-$second'));
    await tester.ensureVisible(secondSwipe);
    await tester.drag(secondSwipe, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-set-$second')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-set-$first')),
        findsOneWidget);
    expect(haptics, contains('HapticFeedbackType.mediumImpact'));
    expect(create.calls, 0);
    expect(tester.widget<TextButton>(
        find.byKey(const ValueKey('create-routine-save'))).onPressed,
        isNotNull);
  });

  testWidgets('reversing a full-length drag before release never deletes Set',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments as String? ?? '');
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final create = _Create();
    var index = 0;
    const first = '55555555-5555-4555-8555-555555555555';
    final ids = [
      '44444444-4444-4444-8444-444444444444', first,
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();

    final swipe = find.byKey(const ValueKey('routine-set-swipe-$first'));
    await tester.ensureVisible(swipe);
    final gesture = await tester.startGesture(tester.getCenter(swipe));
    await gesture.moveBy(const Offset(-320, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(300, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-set-$first')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('create-routine-entry-44444444-4444-4444-8444-444444444444')),
        findsOneWidget);
    expect(haptics, isNot(contains('HapticFeedbackType.mediumImpact')));
    expect(create.calls, 0);
  });

  testWidgets('full swipe last Set removes Exercise and disables Create Save',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final create = _Create();
    var index = 0;
    const onlySet = '55555555-5555-4555-8555-555555555555';
    final ids = [
      '44444444-4444-4444-8444-444444444444',
      onlySet,
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    final swipe = find.byKey(const ValueKey('routine-set-swipe-$onlySet'));
    await tester.ensureVisible(swipe);
    await tester.drag(swipe, const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-set-$onlySet')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-entry-44444444-4444-4444-8444-444444444444')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-empty')),
        findsOneWidget);
    expect(tester.widget<TextButton>(
        find.byKey(const ValueKey('create-routine-save'))).onPressed,
        isNull);
    expect(create.calls, 0);
  });

  testWidgets('half swipe Delete on final Set also removes Exercise',
      (tester) async {
    final create = _Create();
    var index = 0;
    const setId = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
        newUuid: () => [
          '44444444-4444-4444-8444-444444444444', setId,
        ][index++],
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    final swipe = find.byKey(const ValueKey('routine-set-swipe-$setId'));
    final delete = find.byKey(const ValueKey('routine-set-remove-$setId'));
    await tester.ensureVisible(swipe);
    await tester.drag(swipe, const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-entry-44444444-4444-4444-8444-444444444444')),
        findsOneWidget);
    expect(tester.widget<TextButton>(delete).onPressed, isNotNull);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-entry-44444444-4444-4444-8444-444444444444')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-empty')), findsOneWidget);
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed, isNull);
    expect(create.calls, 0);
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
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    expect(find.text('LB'), findsOneWidget);
    final weight = find.byKey(const ValueKey('routine-set-weight-$set1'));
    await tester.ensureVisible(weight);
    await tester.enterText(weight, '44');
    await tester.enterText(
      find.byKey(const ValueKey('routine-set-reps-$set1')), '8');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pump();
    expect(create.calls, 1);
    expect(create.command!.entries.single.sets.single.prescription.loadKg,
        closeTo(UnitConverters.lbToKg(44), 0.000001));
  });

  testWidgets('Set badge sheet selects Warm Up and Reps header selects Range',
      (tester) async {
    final create = _Create();
    var index = 0;
    const id = '55555555-5555-4555-8555-555555555555';
    final uuids = [
      '44444444-4444-4444-8444-444444444444',
      id,
      '22222222-2222-4222-8222-222222222222',
      '33333333-3333-4333-8333-333333333333',
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
      const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();

    final type = find.byKey(const ValueKey('routine-set-type-$id'));
    await tester.tap(type);
    await tester.pumpAndSettle();
    expect(find.text('Select Set Type'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('routine-type-option-warm_up')));
    await tester.pumpAndSettle();
    expect(find.descendant(
      of: type, matching: find.text('W')), findsOneWidget);

    final header = find.byKey(const ValueKey(
      'create-routine-repetition-options-44444444-4444-4444-8444-444444444444',
    ));
    await tester.tap(header);
    await tester.pumpAndSettle();
    expect(find.text('Repetition Options'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('routine-repetition-range')));
    await tester.pumpAndSettle();
    final max = find.byKey(const ValueKey('routine-set-reps-max-$id'));
    expect(max, findsOneWidget);
    final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
    expect(tester.widget<TioInput>(reps).controller!.text, isEmpty);
    expect(tester.widget<TioInput>(max).controller!.text, isEmpty);
    await tester.enterText(max, '');
    await tester.pump();
    // An entirely blank template remains saveable; Range selection is
    // transient until both Min/Max are explicitly supplied.
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed, isNotNull);
    await tester.enterText(max, '12');
    await tester.pump();
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed,
      isNull);
    await tester.enterText(reps, '8');
    await tester.pump();
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed,
      isNotNull);
    expect(create.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pump();
    expect(create.calls, 1);
    final saved = create.command!.entries.single.sets.single;
    expect(saved.id, id);
    expect(saved.prescription.setType, RoutineSetType.warmUp);
    expect(saved.prescription.reps, 8);
    expect(saved.prescription.repsMax, 12);
  });

  testWidgets('compact Rep Range does not overflow at 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var nextId = 0;
    const setId = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: _Create(),
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
        newUuid: () => [
          '44444444-4444-4444-8444-444444444444', setId,
        ][nextId++],
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey(
      'create-routine-repetition-options-44444444-4444-4444-8444-444444444444',
    ));
    await tester.ensureVisible(header);
    await tester.tap(header);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-repetition-range')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-set-reps-max-$setId')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Set Type Remove Set uses last-Set-removes-Exercise contract',
      (tester) async {
    final create = _Create();
    var index = 0;
    const id = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
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
        newUuid: () => [
          '44444444-4444-4444-8444-444444444444', id,
        ][index++],
      ),
    ));
    await tester.tap(find.byKey(
      const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-set-type-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-type-remove-set')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-empty')),
        findsOneWidget);
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed, isNull);
    expect(create.calls, 0);
  });

  testWidgets('Exercise title long press reorders; menu replaces X and arrows',
      (tester) async {
    final create = _Create();
    var index = 0;
    const firstEntry = '44444444-4444-4444-8444-444444444444';
    const secondEntry = '77777777-7777-4777-8777-777777777777';
    const firstSet = '55555555-5555-4555-8555-555555555555';
    const secondSet = '88888888-8888-4888-8888-888888888888';
    final uuids = [firstEntry, firstSet, secondEntry, secondSet,
      '22222222-2222-4222-8222-222222222222',
      '33333333-3333-4333-8333-333333333333',
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(
        const ValueKey('create-routine-add-exercise')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
      await tester.pumpAndSettle();
    }
    expect(find.byType(SliverReorderableList), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
    expect(find.byKey(const ValueKey('create-routine-remove-$firstEntry')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-options-$firstEntry')),
        findsOneWidget);
    // Two identified Exercises and Sets are enough, without targets.
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed, isNotNull);

    final first = find.byKey(const ValueKey('create-routine-entry-$firstEntry'));
    final second = find.byKey(const ValueKey('create-routine-entry-$secondEntry'));
    final firstSemantics = find.byKey(
      const ValueKey('create-routine-reorder-semantics-$firstEntry'));
    final secondSemantics = find.byKey(
      const ValueKey('create-routine-reorder-semantics-$secondEntry'));
    final firstActions = tester.widget<Semantics>(firstSemantics)
        .properties.customSemanticsActions!;
    final secondActions = tester.widget<Semantics>(secondSemantics)
        .properties.customSemanticsActions!;
    expect(firstActions.keys.map((action) => action.label),
        contains('Move exercise down'));
    expect(firstActions.keys.map((action) => action.label),
        isNot(contains('Move exercise up')));
    expect(secondActions.keys.map((action) => action.label),
        contains('Move exercise up'));
    expect(secondActions.keys.map((action) => action.label),
        isNot(contains('Move exercise down')));
    final drag = find.byKey(const ValueKey('create-routine-drag-$firstEntry'));
    await tester.ensureVisible(drag);
    final rowDistance =
        tester.getTopLeft(second).dy - tester.getTopLeft(first).dy;
    final gesture = await tester.startGesture(tester.getCenter(drag));
    await tester.pump(const Duration(milliseconds: 700));
    // With SliverReorderableList, the drop gap is selected while the
    // dragged item's END remains inside the second item's lower half.
    // Overshooting the next row by 350px skips that window entirely.
    // Move across it in frames, like an actual finger drag.
    final distance = rowDistance - TioSpacing.lg;
    for (var step = 0; step < 10; step++) {
      await gesture.moveBy(Offset(0, distance / 10));
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dy,
        greaterThan(tester.getTopLeft(second).dy));

    // Screen-reader / keyboard action reorders without a pointer drag.
    final moveDown = tester.widget<Semantics>(secondSemantics)
        .properties.customSemanticsActions!.entries
        .singleWhere((entry) => entry.key.label == 'Move exercise down')
        .value;
    moveDown();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dy,
        lessThan(tester.getTopLeft(second).dy));
    expect(find.byKey(const ValueKey('routine-set-reps-$firstSet')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-set-reps-$secondSet')),
        findsOneWidget);
    // Reordering does not make an otherwise valid optional-target draft invalid.
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed, isNotNull);
    expect(create.calls, 0);

    await tester.ensureVisible(
      find.byKey(const ValueKey('create-routine-options-$firstEntry')));
    await tester.tap(find.byKey(
      const ValueKey('create-routine-options-$firstEntry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-option-remove')),
        findsOneWidget);
    expect(find.text('Exercise Options'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    // Outside tap dismisses without affecting the unsaved Routine draft.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-option-remove')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-entry-$firstEntry')),
        findsOneWidget);
    expect(create.calls, 0);

    await tester.tap(find.byKey(
      const ValueKey('create-routine-options-$firstEntry')));
    await tester.pumpAndSettle();
    expect(find.text('Remove Exercise'), findsOneWidget);
    await tester.tap(find.text('Remove Exercise'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-entry-$firstEntry')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-entry-$secondEntry')),
        findsOneWidget);
    expect(create.calls, 0);
  });

  testWidgets('Exercise overflow opens bottom sheet; dismissal does not remove',
      (tester) async {
    final create = _Create();
    var index = 0;
    const entryId = '44444444-4444-4444-8444-444444444444';
    const setId = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
        newUuid: () => [entryId, setId][index++],
      ),
    ));
    await tester.tap(find.byKey(
      const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    final menu = find.byKey(const ValueKey('create-routine-options-$entryId'));
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-options-sheet')),
        findsOneWidget);
    expect(find.text('Exercise Options'), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byKey(const ValueKey('create-routine-entry-$entryId')),
        findsOneWidget);
    expect(create.calls, 0);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-exercise-options-sheet')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-entry-$entryId')),
        findsOneWidget);
    expect(create.calls, 0);

    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
      const ValueKey('routine-exercise-option-remove')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-entry-$entryId')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-empty')),
        findsOneWidget);
    expect(create.calls, 0);
  });

  testWidgets(
      'unknown Create warns on Back/Cancel and never silently retries write',
      (tester) async {
    final create = _Create()..loseAcknowledgment = true;
    var exits = 0;
    var nextId = 0;
    final uuids = [
      '44444444-4444-4444-8444-444444444444',
      '55555555-5555-4555-8555-555555555555',
      '22222222-2222-4222-8222-222222222222',
      '33333333-3333-4333-8333-333333333333',
    ];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Builder(builder: (context) => Scaffold(
        body: TextButton(
          key: const ValueKey('launch-create'),
          onPressed: () => Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => CreateRoutinePage(
              program: Program(
                id: ProgramId('11111111-1111-4111-8111-111111111111'),
                name: 'Program 1',
              ),
              initialName: 'Routine 1',
              createRepository: create,
              catalogRepository: _Catalog(),
              weightUnit: WeightUnit.kg,
              newUuid: () => uuids[nextId++],
              onUnconfirmedExit: () => exits++,
            )),
          ),
          child: const Text('Open Create'),
        ),
      )),
    ));
    await tester.tap(find.byKey(const ValueKey('launch-create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
      const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pumpAndSettle();
    expect(create.calls, 1);
    final firstMutation = create.command!.mutationId;
    expect(find.textContaining('Could not confirm Create'), findsOneWidget);

    // The platform back gesture cannot silently discard the frozen attempt.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Routine save not confirmed'), findsOneWidget);
    expect(find.byType(CreateRoutinePage), findsOneWidget);
    expect(create.calls, 1);
    await tester.tap(find.text('Keep verifying'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateRoutinePage), findsOneWidget);

    // Cancel is also an explicit decision, never a silent discarded token.
    await tester.tap(find.byKey(const ValueKey('create-routine-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Routine save not confirmed'), findsOneWidget);
    expect(create.calls, 1);
    expect(create.command!.mutationId, firstMutation);
    await tester.tap(find.text('Exit to Program'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateRoutinePage), findsNothing);
    expect(exits, 1);
    expect(create.calls, 1);

    // Opening a fresh draft alone can never dispatch a second write.
    await tester.tap(find.byKey(const ValueKey('launch-create')));
    await tester.pumpAndSettle();
    expect(find.byType(CreateRoutinePage), findsOneWidget);
    expect(create.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Replace Exercise cancels safely, then resets targets for KM/TIME',
      (tester) async {
    final creates = _Create();
    const oldEntry = '44444444-4444-4444-8444-444444444444';
    const oldSet = '55555555-5555-4555-8555-555555555555';
    const newEntry = '66666666-6666-4666-8666-666666666666';
    const newSet = '77777777-7777-4777-8777-777777777777';
    final ids = [
      oldEntry, oldSet, newEntry, newSet,
      '22222222-2222-4222-8222-222222222222',
      '33333333-3333-4333-8333-333333333333',
    ].iterator;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: CreateRoutinePage(
        program: Program(
          id: ProgramId('11111111-1111-4111-8111-111111111111'),
          name: 'Program 1',
        ),
        initialName: 'Routine 1',
        createRepository: creates,
        catalogRepository: _Catalog(),
        weightUnit: WeightUnit.kg,
        newUuid: () {
          if (!ids.moveNext()) throw StateError('Unexpected UUID');
          return ids.current;
        },
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('routine-set-reps-$oldSet')), '12');
    await tester.pump();
    final menu = find.byKey(const ValueKey('create-routine-options-$oldEntry'));
    await tester.ensureVisible(menu);
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
    expect(find.byKey(const ValueKey('create-routine-entry-$oldEntry')),
        findsOneWidget);
    expect(tester.widget<TioInput>(
        find.byKey(const ValueKey('routine-set-reps-$oldSet')))
        .controller!.text, '12');
    expect(creates.calls, 0);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replace Exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run on Treadmill'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('create-routine-entry-$oldEntry')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-entry-$newEntry')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('create-routine-set-$oldSet')), findsNothing);
    expect(find.byKey(const ValueKey('create-routine-set-$newSet')), findsOneWidget);
    expect(find.text('KG'), findsNothing);
    expect(find.text('REPS'), findsNothing);
    expect(find.text('KM'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(tester.widget<TioInput>(
        find.byKey(const ValueKey('routine-set-distance-$newSet')))
        .controller!.text, isEmpty);
    expect(creates.calls, 0);
    await tester.tap(find.byKey(const ValueKey('create-routine-save')));
    await tester.pump();
    expect(creates.calls, 1);
    final saved = creates.command!.entries.single;
    expect(saved.id, newEntry);
    expect(saved.exercise, ExerciseRef.catalog('ex_run_on_treadmill'));
    expect(saved.sets.single.id, newSet);
    expect(saved.sets.single.prescription.reps, isNull);
    expect(saved.sets.single.prescription.loadKg, isNull);
    expect(saved.sets.single.prescription.distanceMeters, isNull);
  });

  testWidgets('Create reference empty state has disabled Save and Add exercise',
      (tester) async {
    final create = _Create();
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
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
        Exercise(
          ref: ExerciseRef.catalog('ex_run_on_treadmill'),
          displayName: 'Run on Treadmill',
          status: ExerciseStatus.active,
          exerciseType: ExerciseType.distanceDuration,
        ),
      ]);
}

class _Create implements RoutineCreateRepository {
  int calls = 0;
  RoutineCreateCommand? command;
  bool loseAcknowledgment = false;
  @override
  Future<int> create(RoutineCreateCommand value) async {
    calls++;
    command = value;
    if (loseAcknowledgment) throw StateError('response lost after commit');
    return 1;
  }
}
