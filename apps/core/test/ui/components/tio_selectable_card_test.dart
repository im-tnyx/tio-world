import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

/// Pumps a [TioSelectableCard] inside the real theme.
///
/// Light/dark is selected through [TioThemeConfig.mode], because that is what
/// `TioTheme` actually reads. An outer `ThemeData(brightness:)` would leave
/// every case resolving `TioColors.light`, and a test comparing a render
/// against the colors that same render produced would still pass with dark
/// resolution completely broken.
Future<TioColors> _pump(
  WidgetTester tester, {
  required bool selected,
  // The widget requires a callback; cases that do not care about the tap
  // still have to hand it one.
  VoidCallback? onTap,
  bool enabled = true,
  String? semanticLabel,
  TioThemeMode mode = TioThemeMode.light,
  bool reducedMotion = false,
}) async {
  late TioColors colors;

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode, reducedMotion: reducedMotion),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            colors = context.tioColors;
            return TioSelectableCard(
              selected: selected,
              onTap: onTap ?? () {},
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

AnimatedContainer _animatedContainer(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(TioSelectableCard),
        matching: find.byType(AnimatedContainer),
      ),
    );

BoxDecoration _decoration(WidgetTester tester) =>
    _animatedContainer(tester).decoration! as BoxDecoration;

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
      expect(
        _animatedContainer(tester).padding,
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
    testWidgets('light and dark resolve their own TioColors', (tester) async {
      final light = await _pump(tester, selected: true);
      final lightFill = _surface(tester).color;

      final dark = await _pump(tester, selected: true, mode: TioThemeMode.dark);
      final darkFill = _surface(tester).color;

      // Compared against the canonical schemes, not against whatever the same
      // render happened to produce, so a broken dark resolution cannot pass.
      expect(light.primary, TioColors.light.primary);
      expect(dark.primary, TioColors.dark.primary);
      expect(light.surface, TioColors.light.surface);
      expect(dark.surface, TioColors.dark.surface);

      expect(
        lightFill,
        TioColors.light.primary.withValues(
          alpha: TioCardTokens.selectedContainerAlpha,
        ),
      );
      expect(
        darkFill,
        TioColors.dark.primary.withValues(
          alpha: TioCardTokens.selectedContainerAlpha,
        ),
      );
    });

    testWidgets('the unselected fill differs between light and dark',
        (tester) async {
      await _pump(tester, selected: false);
      final lightFill = _surface(tester).color;

      await _pump(tester, selected: false, mode: TioThemeMode.dark);
      final darkFill = _surface(tester).color;

      expect(lightFill, TioColors.light.surface);
      expect(darkFill, TioColors.dark.surface);
      expect(
        lightFill,
        isNot(darkFill),
        reason: 'A harness that never really switched theme would report the '
            'same surface twice.',
      );
    });
  });

  group('motion', () {
    testWidgets('fill and border share the resolved duration', (tester) async {
      await _pump(tester, selected: true);

      final motion = tester.element(find.byType(TioSelectableCard)).tioMotion;
      expect(_surface(tester).animationDuration, motion.fast);
      expect(_animatedContainer(tester).duration, motion.fast);
    });

    testWidgets('reduced motion zeroes both the fill and the border',
        (tester) async {
      await _pump(tester, selected: true, reducedMotion: true);

      // The fill lives on Material and the border on AnimatedContainer. Left
      // at Flutter's default the Material would keep cross-fading here.
      expect(_surface(tester).animationDuration, Duration.zero);
      expect(_animatedContainer(tester).duration, Duration.zero);
    });
  });
}
