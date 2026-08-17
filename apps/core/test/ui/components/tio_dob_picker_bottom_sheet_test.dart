import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets(
      'TioDobPickerBottomSheet renders Day Month Year columns and returns picked date with TioButton',
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

    expect(find.text('Select Date of Birth'), findsOneWidget);
    expect(find.text('We use this data to help personalize Tio for you'),
        findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Year'), findsOneWidget);

    expect(find.text('5'), findsWidgets);
    expect(find.text('Jun'), findsWidgets);
    expect(find.text('1995'), findsWidgets);

    await tester.tap(find.byType(TioButton));
    await tester.pumpAndSettle();

    expect(pickedDate, DateTime(1995, 6, 5));
  });

  testWidgets('programmatic DOB sync does not re-enter onChanged',
      (tester) async {
    var changeCount = 0;

    Widget buildPicker(DateTime initialDate) {
      return MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: TioDobWheelPicker(
            initialDate: initialDate,
            endYear: 2014,
            onChanged: (_) => changeCount++,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildPicker(DateTime(1995, 6, 5)));
    await tester.pumpAndSettle();
    changeCount = 0;

    await tester.pumpWidget(buildPicker(DateTime(2000, 1, 1)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(changeCount, 0);
    expect(find.text('2000'), findsWidgets);
  });
}
