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
    expect(
      find.byKey(const ValueKey('measurement-units-preset-custom')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('measurement-units-weight-kg')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('measurement-units-preset-custom')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('measurement-units-save')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.weightUnit, WeightUnit.kg);
    expect(saved!.heightUnit, HeightUnit.ftIn);
    expect(saved!.distanceUnit, DistanceUnit.mi);
    expect(saved!.volumeUnit, VolumeUnit.flOz);
  });

  testWidgets('unit choices expose selected semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: MeasurementUnitsSettingsPage(
          initialPreferences: MeasurementUnitPreferences.metric,
          onSave: (_) async {},
        ),
      ),
    );

    int selectedSemanticsCount() => tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((widget) => widget.properties.selected == true)
        .length;

    expect(selectedSemanticsCount(), 5);

    await tester.tap(
      find.byKey(const ValueKey('measurement-units-preset-imperial')),
    );
    await tester.pump();

    expect(selectedSemanticsCount(), 5);
  });

  testWidgets('compact large-text layout remains overflow-safe', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: const TextScaler.linear(1.6),
            ),
            child: TioTheme(child: child ?? const SizedBox.shrink()),
          );
        },
        home: MeasurementUnitsSettingsPage(
          initialPreferences: const MeasurementUnitPreferences(
            weightUnit: WeightUnit.kg,
            heightUnit: HeightUnit.ftIn,
            distanceUnit: DistanceUnit.mi,
            volumeUnit: VolumeUnit.ml,
          ),
          onSave: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('measurement-units-preset-custom')),
      findsOneWidget,
    );
    expect(find.text('Liquid volume'), findsOneWidget);
    expect(find.text('miles'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
