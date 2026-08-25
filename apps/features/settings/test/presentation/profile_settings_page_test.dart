import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  testWidgets('ProfileSettingsPage renders capsule fields without username and saves properly',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? savedName;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: ProfileSettingsPage(
          name: 'Santosh',
          gender: 'Male',
          dateOfBirth: DateTime(1995, 6, 5),
          heightCm: 175.0,
          currentWeightKg: 72.5,
          onSave: ({
            required name,
            required username,
            required gender,
            required dateOfBirth,
            required heightCm,
            required currentWeightKg,
          }) async {
            savedName = name;
          },
        ),
      ),
    );

    expect(find.text('Profile Settings'), findsOneWidget);
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('DATE OF BIRTH'), findsOneWidget);
    expect(find.text('BIOLOGICAL SEX'), findsOneWidget);
    expect(find.text('HEIGHT'), findsOneWidget);
    expect(find.text('CURRENT WEIGHT'), findsOneWidget);

    expect(find.text('6/5/1995'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);

    // Height unit switch
    expect(find.text('cm'), findsOneWidget);
    expect(find.text('ft'), findsOneWidget);

    // Weight unit switch
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('lbs'), findsOneWidget);

    // Switch height to cm
    await tester.tap(find.text('cm'));
    await tester.pumpAndSettle();
    expect(find.text('175 cm'), findsOneWidget);

    // Save changes
    await tester.tap(find.widgetWithText(FilledButton, 'Save Changes'));
    await tester.pumpAndSettle();

    expect(savedName, 'Santosh');
  });

  testWidgets('ProfileSettingsPage normalizes imperial height rollover',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: ProfileSettingsPage(
          name: 'Santosh',
          dateOfBirth: DateTime(1995, 6, 5),
          heightCm: 182.0,
          currentWeightKg: 72.5,
        ),
      ),
    );

    expect(find.text("6' 0\""), findsOneWidget);
    expect(find.text("5' 12\""), findsNothing);
  });
}
