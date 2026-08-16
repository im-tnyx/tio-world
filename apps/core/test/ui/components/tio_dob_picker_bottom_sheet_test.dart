import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('TioDobPickerBottomSheet renders Day Month Year columns and returns picked date with TioButton',
      (tester) async {
    DateTime? pickedDate;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                pickedDate = await showTioDobPickerBottomSheet(
                  context: context,
                  initialDate: DateTime(1995, 6, 5),
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Check title, subtitle, and column headers
    expect(find.text('Select Date of Birth'), findsOneWidget);
    expect(find.text('We use this data to help personalize Tio for you'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);

    // Check initial values visible
    expect(find.text('5'), findsWidgets);
    expect(find.text('Jun'), findsWidgets);
    expect(find.text('1995'), findsWidgets);

    // Tap Save TioButton
    await tester.tap(find.byType(TioButton));
    await tester.pumpAndSettle();

    expect(pickedDate, DateTime(1995, 6, 5));
  });
}
