import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_feature_workout/src/presentation/library/routines/routine_set_input_limits.dart';
import 'package:tio_shared/shared.dart';

TextEditingValue _value(String text) => TextEditingValue(text: text);

void main() {
  test('Rest input accepts signed-int32 maximum, never exceeds it', () {
    final formatter = RoutineSetInputLimits.int32;
    expect(formatter.formatEditUpdate(_value('8'), _value('2147483647')).text,
        '2147483647');
    expect(formatter.formatEditUpdate(
      _value('2147483647'), _value('2147483648')).text, '2147483647');
    expect(formatter.formatEditUpdate(
      _value('8'), _value('99999999999')).text, '8');
    expect(formatter.formatEditUpdate(
      _value('8'), _value('')).text, '');
    expect(formatter.formatEditUpdate(
      _value('8'), _value('0')).text, '0');
    expect(formatter.formatEditUpdate(
      _value('8'), _value('-1')).text, '8');
    expect(formatter.formatEditUpdate(
      _value('8'), _value('123.4')).text, '8');
    expect(formatter.formatEditUpdate(
      _value('8'), _value('0000000000')).text, '0000000000');
  });

  test('Reps and range targets cap at three whole digits', () {
    final formatter = RoutineSetInputLimits.reps;
    expect(RoutineSetInputLimits.maxRepsDigits, 3);
    expect(RoutineSetInputLimits.maxReps, 999);
    expect(formatter.formatEditUpdate(_value(''), _value('999')).text, '999');
    expect(formatter.formatEditUpdate(_value('8'), _value('1000')).text, '8');
    expect(formatter.formatEditUpdate(_value('8'), _value('9999')).text, '8');
    expect(formatter.formatEditUpdate(_value('999'), _value('')).text, '');
    expect(formatter.formatEditUpdate(_value('8'), _value('0')).text, '0');
    expect(formatter.formatEditUpdate(_value('8'), _value('000')).text, '000');
    expect(formatter.formatEditUpdate(_value('8'), _value('-2')).text, '8');
    expect(formatter.formatEditUpdate(_value('8'), _value('12.0')).text, '8');
  });

  test('KG/LB field allows six whole and three fractional digits only', () {
    final formatter = RoutineSetInputLimits.weight;
    expect(formatter.formatEditUpdate(_value(''), _value('123456.789')).text,
        '123456.789');
    expect(formatter.formatEditUpdate(
      _value('12.543'), _value('12.5432')).text, '12.543');
    expect(formatter.formatEditUpdate(
      _value('12.543'), _value('1234567.5')).text, '12.543');
    expect(formatter.formatEditUpdate(
      _value('12'), _value('12.3.4')).text, '12');
    expect(formatter.formatEditUpdate(
      _value('12'), _value('-3')).text, '12');
    expect(formatter.formatEditUpdate(
      _value('12'), _value('')).text, '');
    expect(formatter.formatEditUpdate(
      _value(''), _value('.')).text, '.');
    expect(formatter.formatEditUpdate(
      _value(''), _value('0.5')).text, '0.5');
  });

  testWidgets('blank Routine Set Reps, typed limits and draft validity',
      (tester) async {
    const id = '55555555-5555-4555-8555-555555555555';
    final values = <SetPrescription>[];
    final validity = <bool>[];
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.dark),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: RoutineSetInputRow(
        set: RoutineCompositionSet(
          id: id, prescription: SetPrescription(reps: 1)),
        index: 0,
        normalNumber: 1,
        onTypePressed: () {},
        unit: WeightUnit.kg,
        enabled: true,
        startWithBlankReps: true,
        isOpen: false,
        onOpenChanged: (_) {},
        onChanged: values.add,
        onValidityChanged: validity.add,
        onRemove: () {},
      )),
    ));
    final reps = find.byKey(const ValueKey('routine-set-reps-$id'));
    final weight = find.byKey(const ValueKey('routine-set-weight-$id'));
    TextField input(Finder field) =>
        tester.widget<TextField>(find.descendant(
          of: field, matching: find.byType(TextField)));

    expect(input(reps).controller!.text, isEmpty);
    await tester.enterText(reps, '99999999999');
    await tester.pump();
    expect(input(reps).controller!.text, isEmpty);
    expect(values, isEmpty);

    await tester.enterText(reps, '999');
    await tester.pump();
    expect(input(reps).controller!.text, '999');
    await tester.enterText(reps, '1000');
    await tester.pump();
    expect(input(reps).controller!.text, '999');
    await tester.enterText(reps, '8');
    await tester.pump();
    expect(input(reps).controller!.text, '8');
    expect(validity.last, isTrue);
    expect(values.last.reps, 8);

    await tester.enterText(weight, '12.5432');
    await tester.pump();
    expect(input(weight).controller!.text, isEmpty);
    await tester.enterText(weight, '12.543');
    await tester.pump();
    expect(input(weight).controller!.text, '12.543');
    expect(values.last.loadKg, 12.543);
    expect(values.last.reps, 8);
    expect(tester.takeException(), isNull);
  });
}
