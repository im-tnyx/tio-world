import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
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
