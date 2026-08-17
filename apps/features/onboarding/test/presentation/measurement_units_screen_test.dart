import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/src/presentation/screens/profile/measurement_units_screen.dart';

void main() {
  testWidgets('preset and individual unit choices remain independently editable',
      (tester) async {
    var preferences = MeasurementUnitPreferences.metric;

    Widget build() => MaterialApp(
          builder: (context, child) =>
              TioTheme(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
            body: MeasurementUnitsScreen(
              preferences: preferences,
              onChanged: (next) => preferences = next,
            ),
          ),
        );

    await tester.pumpWidget(build());
    expect(find.text('Choose your units'), findsOneWidget);
    expect(preferences, MeasurementUnitPreferences.metric);

    await tester.tap(find.text('Imperial'));
    await tester.pumpWidget(build());
    expect(preferences, MeasurementUnitPreferences.imperial);

    await tester.tap(find.text('kg'));
    await tester.pumpWidget(build());
    expect(preferences.weightUnit, WeightUnit.kg);
    expect(preferences.heightUnit, HeightUnit.ftIn);
    expect(preferences.distanceUnit, DistanceUnit.mi);
    expect(preferences.volumeUnit, VolumeUnit.flOz);
    expect(preferences.isImperialPreset, isFalse);
  });
}
