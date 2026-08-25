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

  testWidgets('ft mode normalizes rollover boundary instead of showing 12 inches',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showTioHeightPickerBottomSheet(
                  context: context,
                  initialHeightCm: 182.0,
                  unit: 'ft',
                );
              },
              child: const Text('Open Rollover Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Rollover Picker'));
    await tester.pumpAndSettle();

    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields, hasLength(2));
    expect(fields[0].controller?.text, '6');
    expect(fields[1].controller?.text, '0');
  });

  testWidgets('ft mode rejects 12-inch component and retains canonical value',
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
                  unit: 'ft',
                );
              },
              child: const Text('Open Invalid Inches Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Invalid Inches Picker'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '5');
    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.tap(find.byType(TioButton));
    await tester.pumpAndSettle();

    expect(pickedCm, 170.0);
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
