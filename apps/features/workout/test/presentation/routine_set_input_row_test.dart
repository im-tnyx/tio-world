import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  for (final mode in [TioThemeMode.dark, TioThemeMode.light]) {
    testWidgets('Set 1 and 2 have visible filled rounded boxes in '
        '${mode.name}', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      const ids = [
        '55555555-5555-4555-8555-555555555555',
        '66666666-6666-4666-8666-666666666666',
      ];
      final palette =
          mode == TioThemeMode.dark ? TioColors.oled : TioColors.light;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => TioTheme(
          config: TioThemeConfig(mode: mode),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Column(children: [
            for (var index = 0; index < ids.length; index++)
              RoutineSetInputRow(
                set: RoutineCompositionSet(
                  id: ids[index],
                  prescription: SetPrescription(reps: 8),
                ),
                index: index,
                normalNumber: index + 1,
                onTypePressed: () {},
                unit: WeightUnit.kg,
                enabled: true,
                isOpen: false,
                onOpenChanged: (_) {},
                onChanged: (_) {},
                onValidityChanged: (_) {},
                onRemove: () {},
              ),
          ]),
        ),
      ));
      for (var index = 0; index < ids.length; index++) {
        final box = find.byKey(ValueKey('routine-set-type-box-${ids[index]}'));
        expect(box, findsOneWidget);
        final decoration = tester.widget<Container>(box).decoration!
            as BoxDecoration;
        expect(decoration.color, palette.surfaceVariant);
        expect(decoration.color, isNot(palette.background));
        expect(decoration.borderRadius,
            BorderRadius.circular(TioRadius.md));
        expect(tester.getSize(box).width, TioSize.dp44);
        expect(tester.getSize(box).height,
            greaterThanOrEqualTo(TioSize.dp44));
        expect(find.text('${index + 1}'), findsOneWidget);
        expect(find.byKey(ValueKey('routine-set-type-${ids[index]}')),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('inline row preserves kg when lb display is unchanged', (tester) async {
    final values = <SetPrescription>[];
    final validity = <bool>[];
    const id = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: RoutineSetInputRow(
        set: RoutineCompositionSet(id: id,
          prescription: SetPrescription(reps: 8, loadKg: 12.54321, restSeconds: 60)),
        index: 0,
        normalNumber: 1,
        onTypePressed: () {},
        unit: WeightUnit.lb,
        enabled: true,
        isOpen: false,
        onOpenChanged: (_) {},
        onChanged: values.add,
        onValidityChanged: validity.add,
        onRemove: () {},
      )),
    ));
    final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
    await tester.enterText(reps, '');
    await tester.pump();
    // Empty targets are a valid nullable Routine prescription.
    expect(validity, isEmpty);
    expect(values.single.reps, isNull);
    await tester.enterText(reps, '10');
    await tester.pump();
    expect(validity, isEmpty);
    expect(values.last.reps, 10);
    expect(values.last.loadKg, 12.54321);
    expect(values.last.restSeconds, 60);
  });

  testWidgets('unspecified Range shows Min/Max without fabricating Reps',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final edits = <SetPrescription>[];
    final valid = <bool>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: RoutineSetInputRow(
        set: RoutineCompositionSet(
          id: id, prescription: SetPrescription()),
        index: 0,
        normalNumber: 1,
        onTypePressed: () {},
        unit: WeightUnit.kg,
        enabled: true,
        showRangeDraft: true,
        isOpen: false,
        onOpenChanged: (_) {},
        onChanged: edits.add,
        onValidityChanged: valid.add,
        onRemove: () {},
      )),
    ));
    final min = find.byKey(const ValueKey('routine-set-reps-$id'));
    final max = find.byKey(const ValueKey('routine-set-reps-max-$id'));
    expect(min, findsOneWidget);
    expect(max, findsOneWidget);
    expect(tester.widget<TioInput>(min).controller!.text, isEmpty);
    expect(tester.widget<TioInput>(max).controller!.text, isEmpty);
    expect(edits, isEmpty);
    expect(valid, isEmpty);
    await tester.enterText(max, '12');
    await tester.pump();
    expect(valid.last, isFalse);
    expect(edits, isEmpty);
    await tester.enterText(min, '8');
    await tester.pump();
    expect(valid.last, isTrue);
    expect(edits.single.reps, 8);
    expect(edits.single.repsMax, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Edit range shows distinct outlined Min/Max and Previous at 320dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const id = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: RoutineSetInputRow(
          set: RoutineCompositionSet(
            id: id,
            prescription: SetPrescription(
              reps: 8,
              repsMax: 12,
              loadKg: 20,
            ),
          ),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          enabled: true,
          showPrevious: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (_) {},
          onValidityChanged: (_) {},
          onRemove: () {},
        ),
      ),
    ));
    for (final suffix in ['weight', 'reps', 'reps-max']) {
      final input = find.byKey(ValueKey('routine-set-$suffix-$id'));
      expect(input, findsOneWidget);
      final field = tester.widget<TextField>(find.descendant(
        of: input,
        matching: find.byType(TextField),
      ));
      expect(tester.widget<TioInput>(input).variant,
          TioInputVariant.boxedNumber);
      expect(field.decoration!.enabledBorder, isA<OutlineInputBorder>());
      expect(field.decoration!.focusedBorder, isA<OutlineInputBorder>());
      expect(field.decoration!.hintText, '–');
      expect(field.textAlign, TextAlign.center);
      expect(tester.getSize(input).height, greaterThanOrEqualTo(44));
    }
    expect(find.byKey(const ValueKey('routine-set-range-separator-$id')),
        findsOneWidget);
    expect(find.text('to'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('External Set edit refreshes inline values without overwriting weight',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final current = ValueNotifier<SetPrescription>(
      SetPrescription(reps: 8, loadKg: 12.5, restSeconds: 60),
    );
    addTearDown(current.dispose);
    final emitted = <SetPrescription>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: ValueListenableBuilder<SetPrescription>(
        valueListenable: current,
        builder: (_, prescription, __) => RoutineSetInputRow(
          set: RoutineCompositionSet(id: id, prescription: prescription),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          enabled: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (next) {
            emitted.add(next);
            current.value = next;
          },
          onValidityChanged: (_) {},
          onRemove: () {},
        ),
      )),
    ));
    current.value = SetPrescription(reps: 14, loadKg: 32.75, restSeconds: 45);
    await tester.pump();
    await tester.pump();
    final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
    final weight = find.byKey(const ValueKey('routine-set-weight-$id'));
    expect(tester.widget<TioInput>(reps).controller!.text, '14');
    expect(tester.widget<TioInput>(weight).controller!.text, '32.75');
    expect(emitted, isEmpty);
    await tester.enterText(reps, '15');
    await tester.pump();
    expect(emitted.last.reps, 15);
    expect(emitted.last.loadKg, 32.75);
    expect(emitted.last.restSeconds, 45);
  });

  testWidgets('Switching typed fixed Reps to range requires explicit Max',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final current = ValueNotifier<SetPrescription>(
      SetPrescription(reps: 8),
    );
    addTearDown(current.dispose);
    final validity = <bool>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: ValueListenableBuilder<SetPrescription>(
        valueListenable: current,
        builder: (_, prescription, __) => RoutineSetInputRow(
          set: RoutineCompositionSet(id: id, prescription: prescription),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          enabled: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (next) => current.value = next,
          onValidityChanged: validity.add,
          onRemove: () {},
        ),
      )),
    ));

    // The domain model uses a provisional Max to represent range mode,
    // but no user has typed that Max in this row.
    current.value = SetPrescription(reps: 8, repsMax: 8);
    await tester.pump();
    await tester.pump();
    final max = find.byKey(const ValueKey('routine-set-reps-max-$id'));
    expect(tester.widget<TioInput>(max).controller!.text, isEmpty);
    expect(validity.last, isFalse);

    await tester.enterText(max, '12');
    await tester.pump();
    expect(validity.last, isTrue);
    expect(current.value.reps, 8);
    expect(current.value.repsMax, 12);
  });

  testWidgets('Treadmill uses optional KM/TIME with canonical meters and seconds',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final current = ValueNotifier<SetPrescription>(SetPrescription());
    addTearDown(current.dispose);
    final validity = <bool>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: ValueListenableBuilder<SetPrescription>(
        valueListenable: current,
        builder: (_, value, __) => RoutineSetInputRow(
          set: RoutineCompositionSet(id: id, prescription: value),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          exerciseType: ExerciseType.distanceDuration,
          enabled: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (value) => current.value = value,
          onValidityChanged: validity.add,
          onRemove: () {},
        ),
      )),
    ));
    expect(find.byKey(const ValueKey('routine-set-weight-$id')), findsNothing);
    expect(find.byKey(const ValueKey('routine-set-reps-$id')), findsNothing);
    final km = find.byKey(const ValueKey('routine-set-distance-$id'));
    final time = find.byKey(const ValueKey('routine-set-duration-$id'));
    expect(tester.widget<TioInput>(km).controller!.text, isEmpty);
    expect(tester.widget<TioInput>(time).controller!.text, isEmpty);
    await tester.enterText(km, '2.5');
    await tester.pump();
    expect(current.value.distanceMeters, 2500.0);
    expect(current.value.durationSeconds, isNull);
    expect(current.value.reps, isNull);
    await tester.enterText(time, '15:05');
    await tester.pump();
    expect(current.value.durationSeconds, 905);
    await tester.enterText(time, '15:');
    await tester.pump();
    expect(validity.last, isFalse);
    expect(current.value.durationSeconds, 905);
    await tester.enterText(time, '');
    await tester.pump();
    expect(validity.last, isTrue);
    expect(current.value.durationSeconds, isNull);
    expect(current.value.distanceMeters, 2500.0);
  });

  testWidgets('TIME-only Set hides KG/REPS/KM and preserves optional duration',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final current = ValueNotifier<SetPrescription>(SetPrescription());
    addTearDown(current.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: ValueListenableBuilder<SetPrescription>(
        valueListenable: current,
        builder: (_, value, __) => RoutineSetInputRow(
          set: RoutineCompositionSet(id: id, prescription: value),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          exerciseType: ExerciseType.duration,
          enabled: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (value) => current.value = value,
          onValidityChanged: (_) {},
          onRemove: () {},
        ),
      )),
    ));
    for (final hidden in ['weight', 'reps', 'distance']) {
      expect(find.byKey(ValueKey('routine-set-$hidden-$id')), findsNothing);
    }
    final time = find.byKey(const ValueKey('routine-set-duration-$id'));
    expect(time, findsOneWidget);
    await tester.enterText(time, '1:30');
    await tester.pump();
    expect(current.value.durationSeconds, 90);
    expect(current.value.reps, isNull);
    expect(current.value.loadKg, isNull);
    expect(current.value.distanceMeters, isNull);
  });

  testWidgets('Create fixed Set has outlined blank Reps without fabricated Max',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const id = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: RoutineSetInputRow(
          set: RoutineCompositionSet(
            id: id,
            prescription: SetPrescription(reps: 1),
          ),
          index: 0,
          normalNumber: 1,
          onTypePressed: () {},
          unit: WeightUnit.kg,
          enabled: true,
          startWithBlankReps: true,
          isOpen: false,
          onOpenChanged: (_) {},
          onChanged: (_) {},
          onValidityChanged: (_) {},
          onRemove: () {},
        ),
      ),
    ));
    final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
    final cell = tester.widget<TioInput>(reps);
    expect(cell.controller!.text, isEmpty);
    expect(cell.textAlign, TextAlign.center);
    expect(cell.variant, TioInputVariant.boxedNumber);
    expect(find.byKey(const ValueKey('routine-set-reps-max-$id')),
        findsNothing);
    expect(find.byKey(const ValueKey('routine-set-range-separator-$id')),
        findsNothing);
    final field = tester.widget<TextField>(find.descendant(
      of: reps,
      matching: find.byType(TextField),
    ));
    expect(field.decoration!.enabledBorder, isA<OutlineInputBorder>());
    expect(tester.takeException(), isNull);
  });
}
