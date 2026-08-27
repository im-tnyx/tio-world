import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/src/presentation/screens/profile/measurement_units_screen.dart';

void main() {
  testWidgets('preset and individual unit choices derive Custom reversibly',
      (tester) async {
    var preferences = UnitPreferences.metric;

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

    void expectPresetCentered() {
      final presetCenter = tester
          .getCenter(
            find.byKey(
              const ValueKey('measurement-units-preset-segmented-control'),
            ),
          )
          .dx;
      final screenCenter = tester.getCenter(find.byType(Scaffold)).dx;
      expect(presetCenter, closeTo(screenCenter, 0.5));
    }

    await tester.pumpWidget(build());
    expect(find.text('Choose your units'), findsOneWidget);
    expect(preferences, UnitPreferences.metric);
    expect(
      find.byKey(const ValueKey('measurement-units-preset-custom')),
      findsNothing,
    );
    expectPresetCentered();

    await tester.tap(
      find.byKey(const ValueKey('measurement-units-preset-imperial')),
    );
    await tester.pumpWidget(build());
    expect(preferences, UnitPreferences.imperial);
    expect(
      find.byKey(const ValueKey('measurement-units-preset-custom')),
      findsNothing,
    );
    expectPresetCentered();

    await tester.tap(find.byKey(const ValueKey('measurement-units-weight-kg')));
    await tester.pumpWidget(build());
    expect(preferences.weightUnit, WeightUnit.kg);
    expect(preferences.heightUnit, HeightUnit.ftIn);
    expect(preferences.distanceUnit, DistanceUnit.mi);
    expect(preferences.volumeUnit, VolumeUnit.flOz);
    expect(preferences.isImperialPreset, isFalse);
    expect(preferences.isMetricPreset, isFalse);
    expect(
      find.byKey(const ValueKey('measurement-units-preset-custom')),
      findsOneWidget,
    );
    expectPresetCentered();

    await tester.tap(find.byKey(const ValueKey('measurement-units-weight-lb')));
    await tester.pumpWidget(build());
    expect(preferences, UnitPreferences.imperial);
    expect(
      find.byKey(const ValueKey('measurement-units-preset-custom')),
      findsNothing,
    );
    expectPresetCentered();

    await tester.tap(
      find.byKey(const ValueKey('measurement-units-preset-metric')),
    );
    await tester.pumpWidget(build());
    await tester.tap(
      find.byKey(const ValueKey('measurement-units-height-ft-in')),
    );
    await tester.pumpWidget(build());
    expect(
      find.byKey(const ValueKey('measurement-units-preset-custom')),
      findsOneWidget,
    );
    expectPresetCentered();

    await tester.tap(find.byKey(const ValueKey('measurement-units-height-cm')));
    await tester.pumpWidget(build());
    expect(preferences, UnitPreferences.metric);
    expect(
      find.byKey(const ValueKey('measurement-units-preset-custom')),
      findsNothing,
    );
    expectPresetCentered();
  });
}
