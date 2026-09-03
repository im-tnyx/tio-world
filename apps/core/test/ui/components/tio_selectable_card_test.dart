import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

/// Pumps a [TioSelectableCard] inside the real theme.
///
/// The colors this component resolves are runtime theme values, so the cases
/// below compare against `context.tioColors` read from the same tree rather
/// than against a hard-coded palette constant — that is the difference between
/// asserting the contract and re-typing the implementation.
Future<TioColors> _pump(
  WidgetTester tester, {
  required bool selected,
  VoidCallback? onTap,
  bool enabled = true,
  String? semanticLabel,
  Brightness brightness = Brightness.light,
}) async {
  late TioColors colors;

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            colors = context.tioColors;
            return TioSelectableCard(
              selected: selected,
              onTap: onTap,
              enabled: enabled,
              semanticLabel: semanticLabel,
              child: const Text('Option content'),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return colors;
}

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(TioSelectableCard),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

Material _surface(WidgetTester tester) => tester.widget<Material>(
      find.descendant(
        of: find.byType(TioSelectableCard),
        matching: find.byType(Material),
      ),
    );

void main() {
  group('unselected appearance', () {
    testWidgets('uses the canonical unselected border and outline',
        (tester) async {
      final colors = await _pump(tester, selected: false);
      final border = _decoration(tester).border! as Border;

      expect(border.top.width, TioCardTokens.unselectedBorderWidth);
      expect(
        border.top.color,
        colors.outlineStrong.withValues(
          alpha: TioCardTokens.unselectedOutlineAlpha,
        ),
        reason: 'The unselected outline is the value that drifted four ways '
            'across production surfaces.',
      );
    });

    testWidgets('unselected outline resolves to the canonical 40%',
        (tester) async {
      await _pump(tester, selected: false);
      final border = _decoration(tester).border! as Border;

      // Pinned as a number as well as a token: the whole point of the audit
      // was that alpha35 (13.7%) and alpha40 (15.7%) stood in for this.
      expect(TioCardTokens.unselectedOutlineAlpha, 0.40);
      expect(border.top.color.a, closeTo(0.40, 0.001));
    });

    testWidgets('fills with the plain surface, not a tint', (tester) async {
      final colors = await _pump(tester, selected: false);

      expect(_surface(tester).color, colors.surface);
    });
  });

  group('selected appearance', () {
    testWidgets('fills with the primary tint at the canonical alpha',
        (tester) async {
      final colors = await _pump(tester, selected: true);

      expect(
        _surface(tester).color,
        colors.primary.withValues(
          alpha: TioCardTokens.selectedContainerAlpha,
        ),
      );
    });

    testWidgets('uses the canonical selected border', (tester) async {
      final colors = await _pump(tester, selected: true);
      final border = _decoration(tester).border! as Border;

      expect(border.top.width, TioCardTokens.selectedBorderWidth);
      expect(border.top.color, colors.primary);
    });
  });

  group('geometry', () {
    testWidgets('radius and padding come from the card tokens', (tester) async {
      await _pump(tester, selected: false);

      expect(
        _decoration(tester).borderRadius,
        BorderRadius.circular(TioCardTokens.radius),
      );
      final container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(TioSelectableCard),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(
        container.padding,
        const EdgeInsets.all(TioCardTokens.padding),
      );
    });
  });

  group('interaction', () {
    testWidgets('tapping an enabled card fires the callback', (tester) async {
      var taps = 0;
      await _pump(tester, selected: false, onTap: () => taps++);

      await tester.tap(find.byType(TioSelectableCard));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('a disabled card does not fire and dims', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        selected: false,
        enabled: false,
        onTap: () => taps++,
      );

      await tester.tap(find.byType(TioSelectableCard), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(taps, 0);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(TioSelectableCard),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        TioOpacity.opacity64,
      );
    });

    testWidgets('a null callback leaves the card inert', (tester) async {
      await _pump(tester, selected: false);

      await tester.tap(find.byType(TioSelectableCard), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('semantics', () {
    testWidgets('exposes exactly one selected button node', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        selected: true,
        onTap: () {},
        semanticLabel: 'Primary option',
      );

      // One node, not two: the ink well is excluded so an option is never
      // announced twice.
      expect(
        find.bySemanticsLabel('Primary option'),
        findsOneWidget,
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Primary option')),
        isSemantics(
          label: 'Primary option',
          isButton: true,
          isSelected: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('an unselected card reports not selected', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        selected: false,
        onTap: () {},
        semanticLabel: 'Secondary option',
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Secondary option')),
        isSemantics(isSelected: false, isButton: true),
      );

      handle.dispose();
    });

    testWidgets('a disabled card reports disabled and offers no tap',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        selected: false,
        enabled: false,
        onTap: () {},
        semanticLabel: 'Locked option',
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Locked option')),
        isSemantics(
          isEnabled: false,
          hasEnabledState: true,
          hasTapAction: false,
        ),
      );

      handle.dispose();
    });

    testWidgets('omitting the label leaves the content to describe itself',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, selected: false, onTap: () {});

      expect(find.bySemanticsLabel('Option content'), findsOneWidget);

      handle.dispose();
    });
  });

  group('theme behavior', () {
    testWidgets('resolves runtime colors per brightness', (tester) async {
      final light = await _pump(tester, selected: true);
      final lightFill = _surface(tester).color;

      final dark = await _pump(
        tester,
        selected: true,
        brightness: Brightness.dark,
      );
      final darkFill = _surface(tester).color;

      expect(
        lightFill,
        light.primary.withValues(alpha: TioCardTokens.selectedContainerAlpha),
      );
      expect(
        darkFill,
        dark.primary.withValues(alpha: TioCardTokens.selectedContainerAlpha),
      );
    });
  });
}
