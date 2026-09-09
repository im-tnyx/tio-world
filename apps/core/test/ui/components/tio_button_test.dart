import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

/// Pumps a button inside the real theme.
///
/// Light/dark/OLED is selected through [TioThemeConfig.mode], because that is
/// what `TioTheme` actually reads. An outer `ThemeData(brightness:)` would
/// leave every case resolving `TioColors.light`, so a test comparing a render
/// against the colors that same render produced would still pass with dark
/// resolution completely broken.
Future<TioColors> _pump(
  WidgetTester tester,
  Widget button, {
  TioThemeMode mode = TioThemeMode.light,
  bool reducedMotion = false,
  // A live CircularProgressIndicator never settles, so the loading case
  // advances a fixed frame instead of waiting for quiescence.
  bool settle = true,
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
            return button;
          },
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }

  return colors;
}

OutlinedButton _outlined(WidgetTester tester) => tester.widget<OutlinedButton>(
      find.descendant(
        of: find.byType(TioButton),
        matching: find.byType(OutlinedButton),
      ),
    );

/// Resolves the button's effective style the way Flutter does: the widget's
/// own style wins per-property, and the theme fills in everything it leaves
/// null. Reading only the widget style would hide whether governed geometry
/// still reaches the destructive variant.
ButtonStyle _effectiveStyle(WidgetTester tester) {
  final button = _outlined(tester);
  final context = tester.element(find.byType(OutlinedButton));
  // Precedence must match ButtonStyleButton.build: widget wins, then theme,
  // then framework defaults. `merge` fills this style's nulls from the other,
  // so the widget style has to be the receiver.
  return (button.style ?? const ButtonStyle())
      .merge(button.themeStyleOf(context))
      .merge(button.defaultStyleOf(context));
}

Color? _foreground(WidgetTester tester, Set<WidgetState> states) =>
    _effectiveStyle(tester).foregroundColor?.resolve(states);

BorderSide? _side(WidgetTester tester, Set<WidgetState> states) =>
    _effectiveStyle(tester).side?.resolve(states);

void main() {
  group('destructive variant', () {
    testWidgets('renders one button node carrying the label', (tester) async {
      await _pump(
        tester,
        TioButton.destructive(label: 'Remove', onPressed: () {}),
      );

      expect(find.text('Remove'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(TioButton)),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          label: 'Remove',
        ),
      );
    });

    testWidgets('uses the danger role for foreground and outline',
        (tester) async {
      final colors = await _pump(
        tester,
        TioButton.destructive(label: 'Remove', onPressed: () {}),
      );

      expect(_foreground(tester, const {}), colors.danger);
      expect(_side(tester, const {})?.color, colors.danger);
      expect(_side(tester, const {})?.width, TioButtonTokens.outlineWidth);
    });

    testWidgets('never falls back to the primary action colour',
        (tester) async {
      for (final mode in TioThemeMode.values) {
        final colors = await _pump(
          tester,
          TioButton.destructive(label: 'Remove', onPressed: () {}),
          mode: mode,
        );

        // In light mode primary and danger differ; asserting inequality in
        // every mode is what catches a variant silently routed to secondary.
        expect(_foreground(tester, const {}), colors.danger);
        expect(_foreground(tester, const {}), isNot(colors.primary));
      }
    });

    testWidgets('keeps danger colours while loading', (tester) async {
      final colors = await _pump(
        tester,
        TioButton.destructive(
          label: 'Remove',
          loading: true,
          loadingLabel: 'Removing',
          onPressed: () {},
        ),
        settle: false,
      );

      // A loading button is disabled, so without the loading carve-out the
      // shared disabled treatment would grey out the spinner mid-delete.
      expect(
        _foreground(tester, const {WidgetState.disabled}),
        colors.danger,
      );
      expect(find.text('Removing'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a genuinely disabled destructive action is not tappable',
        (tester) async {
      var taps = 0;
      final colors = await _pump(
        tester,
        TioButton.destructive(
          label: 'Remove',
          enabled: false,
          onPressed: () => taps++,
        ),
      );

      await tester.tap(find.byType(TioButton));
      expect(taps, 0);
      expect(_outlined(tester).onPressed, isNull);
      expect(
        _foreground(tester, const {WidgetState.disabled}),
        colors.textMuted,
      );
    });

    testWidgets('reduced motion swaps the spinner for a static indicator',
        (tester) async {
      await _pump(
        tester,
        TioButton.destructive(
          label: 'Remove',
          loading: true,
          onPressed: () {},
        ),
        reducedMotion: true,
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    });

    testWidgets('composes a trailing icon and honours semanticLabel',
        (tester) async {
      await _pump(
        tester,
        TioButton.destructive(
          label: 'Remove',
          semanticLabel: 'Remove this image',
          trailing: const Icon(Icons.delete_outline_rounded),
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      // Trailing sits after the label, not before it.
      expect(
        tester.getCenter(find.byIcon(Icons.delete_outline_rounded)).dx,
        greaterThan(tester.getCenter(find.text('Remove')).dx),
      );
      expect(
        tester.getSemantics(find.byType(TioButton)),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          label: 'Remove this image',
        ),
      );
    });
  });

  group('shared governed geometry', () {
    testWidgets('destructive inherits the same chassis as secondary',
        (tester) async {
      await _pump(
        tester,
        TioButton.destructive(label: 'Remove', onPressed: () {}),
      );
      final destructive = _effectiveStyle(tester);

      await _pump(
        tester,
        TioButton.secondary(label: 'Cancel', onPressed: () {}),
      );
      final secondary = _effectiveStyle(tester);

      // Geometry is shared; only the colour roles differ. This is the whole
      // point of the variant living inside TioButton.
      expect(
        destructive.minimumSize?.resolve(const {}),
        secondary.minimumSize?.resolve(const {}),
      );
      expect(
        destructive.minimumSize?.resolve(const {})?.height,
        TioButtonTokens.height,
      );
      expect(
        destructive.shape?.resolve(const {}),
        secondary.shape?.resolve(const {}),
      );
      expect(
        destructive.padding?.resolve(const {}),
        secondary.padding?.resolve(const {}),
      );
    });

    testWidgets('expand stretches the destructive action to full width',
        (tester) async {
      await _pump(
        tester,
        TioButton.destructive(
          label: 'Remove',
          expand: true,
          onPressed: () {},
        ),
      );

      final width = tester.getSize(find.byType(TioButton)).width;
      expect(width, tester.getSize(find.byType(Scaffold)).width);
    });
  });
}
