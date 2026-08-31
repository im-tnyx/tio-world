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
          body: TioDobWheelPicker(
            initialDate: DateTime(1995, 6, 15),
            endYear: 2010,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final pill = tester.widget<Container>(
      find.byKey(const ValueKey('tio-dob-wheel-selection-pill')),
    );
    final decoration = pill.decoration! as BoxDecoration;

    expect(
      decoration.color,
      TioColors.light.surfaceVariant.withAlpha(
        TioWheelPickerTokens.selectionSurfaceAlpha,
      ),
    );

    // The defect this pins: in light theme these two roles are the same
    // colour, so painting the pill from `surface` over a `surfaceRaised`
    // sheet rendered it white-on-white.
    expect(TioColors.light.surface, TioColors.light.surfaceRaised);
    expect(
        TioColors.light.surfaceVariant, isNot(TioColors.light.surfaceRaised));
  });

  test('the pill role stays distinct from the host role in every theme', () {
    // Light was the only variant where the bug was visible, but the fix has to
    // hold everywhere — dark and OLED must not regress into the same trap.
    for (final (name, colors) in <(String, TioColors)>[
      ('light', TioColors.light),
      ('dark', TioColors.dark),
      ('oled', TioColors.oled),
    ]) {
      expect(
        colors.surfaceVariant,
        isNot(colors.surfaceRaised),
        reason: '$name: pill would be invisible on the host surface',
      );
    }
  });
}
