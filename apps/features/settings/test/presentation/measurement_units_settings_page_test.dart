import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  testWidgets('hydrates persisted preferences and saves mixed changes',
      (tester) async {
    MeasurementUnitPreferences? saved;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: MeasurementUnitsSettingsPage(
          initialPreferences: MeasurementUnitPreferences.imperial,
          onSave: (preferences) async => saved = preferences,
        ),
      ),
    );

    expect(find.text('Measurement Units'), findsOneWidget);
    expect(
      tester.widget<TioButton>(
        find.byKey(const ValueKey('measurement-units-save')),
      ).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('measurement-units-weight-kg')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('measurement-units-save')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.weightUnit, WeightUnit.kg);
    expect(saved!.heightUnit, HeightUnit.ftIn);
    expect(saved!.distanceUnit, DistanceUnit.mi);
    expect(saved!.volumeUnit, VolumeUnit.flOz);
  });

  testWidgets('save failure stays retryable and exposes feedback',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: MeasurementUnitsSettingsPage(
          initialPreferences: MeasurementUnitPreferences.metric,
          onSave: (_) async => throw StateError('write failed'),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('measurement-units-preset-imperial')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('measurement-units-save')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('measurement-units-save-error')),
      findsOneWidget,
    );
    expect(find.text('Measurement Units'), findsOneWidget);
  });
}
