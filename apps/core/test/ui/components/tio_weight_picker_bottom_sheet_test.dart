import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('TioWeightPickerBottomSheet renders kg mode and returns weight',
      (tester) async {
    double? pickedKg;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                pickedKg = await showTioWeightPickerBottomSheet(
                  context: context,
                  initialWeightKg: 70.0,
                  unit: 'kg',
                );
              },
              child: const Text('Open Weight Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Weight Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Weight'), findsOneWidget);
    expect(
      find.text(
        'Weight is important for calculating BMI, estimating calorie needs, and personalizing your fitness plan.',
      ),
      findsOneWidget,
    );
    expect(find.text('kg'), findsOneWidget);

    // Tap Save button
    await tester.tap(find.byType(TioButton));
    await tester.pumpAndSettle();

    expect(pickedKg, 70.0);
  });

  testWidgets('lbs mode converts through the canonical core converter',
      (tester) async {
    double? pickedKg;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                pickedKg = await showTioWeightPickerBottomSheet(
                  context: context,
                  initialWeightKg: 81.6466266,
                  unit: 'lbs',
                );
              },
              child: const Text('Open Imperial Weight Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Imperial Weight Picker'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '180.0');
    expect(find.text('lbs'), findsOneWidget);

    await tester.tap(find.byType(TioButton));
    await tester.pumpAndSettle();

    expect(pickedKg, closeTo(81.6466266, 0.0001));
  });
}
