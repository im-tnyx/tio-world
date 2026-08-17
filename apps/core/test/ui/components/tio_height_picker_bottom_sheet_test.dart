import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('TioHeightPickerBottomSheet renders ft mode and returns converted cm',
      (tester) async {
    double? pickedCm;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                pickedCm = await showTioHeightPickerBottomSheet(
                  context: context,
                  initialHeightCm: 165.1,
                  unit: 'ft',
                );
              },
              child: const Text('Open Height Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Height Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Height'), findsOneWidget);
    expect(
      find.text(
        'Height is important for calculating BMI, estimating calorie needs, and personalizing your fitness plan.',
      ),
      findsOneWidget,
    );
    expect(find.text('ft'), findsOneWidget);
    expect(find.text('in'), findsOneWidget);

    // Tap Save button
    await tester.tap(find.byType(TioButton));
    await tester.pumpAndSettle();

    expect(pickedCm, isNotNull);
  });

  testWidgets('TioHeightPickerBottomSheet renders cm mode with single capsule',
      (tester) async {
    double? pickedCm;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                pickedCm = await showTioHeightPickerBottomSheet(
                  context: context,
                  initialHeightCm: 170.0,
                  unit: 'cm',
                );
              },
              child: const Text('Open Height Picker CM'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Height Picker CM'));
    await tester.pumpAndSettle();

    expect(find.text('Height'), findsOneWidget);
    expect(find.text('cm'), findsOneWidget);

    // Tap Save button
    await tester.tap(find.byType(TioButton));
    await tester.pumpAndSettle();

    expect(pickedCm, 170.0);
  });
}
