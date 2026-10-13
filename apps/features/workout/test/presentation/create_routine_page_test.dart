import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('picker adds empty Reps and Save requires user entry',
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
    final reps = find.byKey(const ValueKey('routine-set-reps-55555555-5555-4555-8555-555555555555'));
    expect(tester.widget<TioInput>(reps).controller!.text, isEmpty);
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
    expect(create.command!.entries.single.sets.single.prescription.reps, 8);
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
    ).onPressed, isNull);
    expect(create.calls, 0);

    await tester.enterText(reps, '12');
    await tester.pump();
    // Untouched Set 1 still blocks Save even after Set 2 becomes valid.
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save')),
    ).onPressed, isNull);
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
        newUuid: () => [
          '44444444-4444-4444-8444-444444444444', setId,
        ][index++],
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('create-routine-add-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench Press'));
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
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed, isNull);
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
    }
    expect(find.byType(SliverReorderableList), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
    expect(find.byKey(const ValueKey('create-routine-remove-$firstEntry')),
        findsNothing);
    expect(find.byKey(const ValueKey('create-routine-options-$firstEntry')),
        findsOneWidget);
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed, isNull);

    final first = find.byKey(const ValueKey('create-routine-entry-$firstEntry'));
    final second = find.byKey(const ValueKey('create-routine-entry-$secondEntry'));
    final drag = find.byKey(const ValueKey('create-routine-drag-$firstEntry'));
    await tester.ensureVisible(drag);
    final gesture = await tester.startGesture(tester.getCenter(drag));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveBy(const Offset(0, 350));
    await tester.pump(const Duration(milliseconds: 250));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(first).dy,
        greaterThan(tester.getTopLeft(second).dy));
    expect(find.byKey(const ValueKey('routine-set-reps-$firstSet')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('routine-set-reps-$secondSet')),
        findsOneWidget);
    expect(tester.widget<TextButton>(
      find.byKey(const ValueKey('create-routine-save'))).onPressed, isNull);
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
