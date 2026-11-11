import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('initial lb drums show 154.3 lb for 70 canonical kg',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: TioWeightWheel(
            valueKg: 70,
            unit: WeightUnit.lb,
            showUnitSwitcher: false,
            minKg: 30,
            maxKg: 200,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final drums = find.byType(ListWheelScrollView);
    expect(drums, findsNWidgets(2));
    final whole = tester.widget<ListWheelScrollView>(drums.at(0)).controller!
        as FixedExtentScrollController;
    final decimal = tester.widget<ListWheelScrollView>(drums.at(1)).controller!
        as FixedExtentScrollController;
    expect(whole.selectedItem, 154 - 66); // minLbs is round(30 * 2.20462)
    expect(decimal.selectedItem, 3);
    expect(find.text('154'), findsOneWidget);
  });

  testWidgets('external kg to lb unit switch remaps mounted drum indices',
      (tester) async {
    WeightUnit unit = WeightUnit.kg;
    late StateSetter change;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return TioWeightWheel(
                valueKg: 70,
                unit: unit,
                showUnitSwitcher: false,
                onChanged: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    var drums = find.byType(ListWheelScrollView);
    expect(
      (tester.widget<ListWheelScrollView>(drums.at(0)).controller!
          as FixedExtentScrollController).selectedItem,
      40, // 70 kg - 30 kg minimum
    );
    change(() => unit = WeightUnit.lb);
    await tester.pumpAndSettle();
    drums = find.byType(ListWheelScrollView);
    expect(
      (tester.widget<ListWheelScrollView>(drums.at(0)).controller!
          as FixedExtentScrollController).selectedItem,
      154 - 66,
    );
    expect(
      (tester.widget<ListWheelScrollView>(drums.at(1)).controller!
          as FixedExtentScrollController).selectedItem,
      3,
    );
  });

  testWidgets('lb controlled echo preserves the selected 117.0 drums',
      (tester) async {
    double canonicalKg = 70;
    late StateSetter setParentState;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setParentState = setState;
              return TioWeightWheel(
                valueKg: canonicalKg,
                unit: WeightUnit.lb,
                showUnitSwitcher: false,
                onChanged: (kg) => setState(() => canonicalKg = kg),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final drums = find.byType(ListWheelScrollView);
    final whole = tester.widget<ListWheelScrollView>(drums.at(0)).controller!
        as FixedExtentScrollController;
    final decimal = tester.widget<ListWheelScrollView>(drums.at(1)).controller!
        as FixedExtentScrollController;

    // Simulate the user's whole/decimal choices; each detent notifies its
    // controlled parent, which echoes the exact canonical kg back.
    whole.jumpToItem(117 - 66);
    await tester.pumpAndSettle();
    decimal.jumpToItem(0);
    await tester.pumpAndSettle();

    expect(canonicalKg, closeTo(117 / 2.20462, 0.0000001));
    expect(whole.selectedItem, 117 - 66);
    expect(decimal.selectedItem, 0);
    expect(find.text('117'), findsOneWidget);

    // An actual external value update must still reposition both drums,
    // using rounded tenths even across lb/kg floating-point conversion.
    setParentState(() => canonicalKg = 154.3 / 2.20462);
    await tester.pumpAndSettle();
    expect(whole.selectedItem, 154 - 66);
    expect(decimal.selectedItem, 3);
  });

  testWidgets('switching 154.3 lb to kg carries to visible 70.0',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: TioWeightWheel(
            valueKg: 154.3 / 2.20462,
            unit: WeightUnit.lb,
            showUnitSwitcher: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final drums = find.byType(ListWheelScrollView);
    expect(drums, findsNWidgets(3));
    final whole = tester.widget<ListWheelScrollView>(drums.at(0)).controller!
        as FixedExtentScrollController;
    final decimal = tester.widget<ListWheelScrollView>(drums.at(1)).controller!
        as FixedExtentScrollController;
    final unit = tester.widget<ListWheelScrollView>(drums.at(2)).controller!
        as FixedExtentScrollController;
    expect(whole.selectedItem, 154 - 66);
    expect(decimal.selectedItem, 3);
    unit.jumpToItem(0);
    await tester.pumpAndSettle();
    expect(whole.selectedItem, 70 - 30);
    expect(decimal.selectedItem, 0);
    expect(find.text('70'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('external canonical kg sync carries rounded decimal overflow',
      (tester) async {
    var kg = 69.5;
    late StateSetter change;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: StatefulBuilder(
        builder: (context, setState) {
          change = setState;
          return TioWeightWheel(
            valueKg: kg,
            unit: WeightUnit.kg,
            showUnitSwitcher: false,
            onChanged: (_) {},
          );
        },
      )),
    ));
    await tester.pumpAndSettle();
    final drums = find.byType(ListWheelScrollView);
    final whole = tester.widget<ListWheelScrollView>(drums.at(0)).controller!
        as FixedExtentScrollController;
    final decimal = tester.widget<ListWheelScrollView>(drums.at(1)).controller!
        as FixedExtentScrollController;
    change(() => kg = 154.3 / 2.20462);
    await tester.pumpAndSettle();
    expect(whole.selectedItem, 70 - 30);
    expect(decimal.selectedItem, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('light theme selection pill uses a contrasting surface role',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: TioWeightWheel(
            valueKg: 70,
            unit: WeightUnit.kg,
            minKg: 30,
            maxKg: 200,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final pill = tester.widget<Container>(
      find.byKey(const ValueKey('tio-weight-wheel-selection-pill')),
    );
    final decoration = pill.decoration! as BoxDecoration;

    expect(
      decoration.color,
      TioColors.light.surfaceVariant.withAlpha(
        TioWheelPickerTokens.selectionSurfaceAlpha,
      ),
    );
    expect(TioColors.light.surface, TioColors.light.surfaceRaised);
    expect(
        TioColors.light.surfaceVariant, isNot(TioColors.light.surfaceRaised));
  });
}
