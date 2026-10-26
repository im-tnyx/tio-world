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
