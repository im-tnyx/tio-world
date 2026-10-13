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
    expect(validity.last, isFalse);
    expect(values, isEmpty);
    await tester.enterText(reps, '10');
    await tester.pump();
    expect(validity.last, isTrue);
    expect(values.last.reps, 10);
    expect(values.last.loadKg, 12.54321);
    expect(values.last.restSeconds, 60);
  });
}
