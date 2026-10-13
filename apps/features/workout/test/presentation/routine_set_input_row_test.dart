import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('inline row preserves kg when lb display is unchanged', (tester) async {
    final values = <SetPrescription>[];
    final validity = <bool>[];
    const id = '55555555-5555-4555-8555-555555555555';
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: TioThemeMode.dark),
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
    expect(validity.last, isFalse);
    expect(values, isEmpty);
    await tester.enterText(reps, '10');
    await tester.pump();
    expect(validity.last, isTrue);
    expect(values.last.reps, 10);
    expect(values.last.loadKg, 12.54321);
    expect(values.last.restSeconds, 60);
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
      final field = tester.widget<TextFormField>(find.descendant(
        of: input,
        matching: find.byType(TextFormField),
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
    final field = tester.widget<TextFormField>(find.descendant(
      of: reps,
      matching: find.byType(TextFormField),
    ));
    expect(field.decoration!.enabledBorder, isA<OutlineInputBorder>());
    expect(tester.takeException(), isNull);
  });
}
