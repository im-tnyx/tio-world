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

/// The chassis the variant renders through. Destructive and primary share
/// [FilledButton]; secondary and ghost do not.
ButtonStyleButton _chassis(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(
      find.descendant(
        of: find.byType(TioButton),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );

/// The three style layers Flutter consults, in precedence order.
///
/// `themeStyleOf` and `defaultStyleOf` are protected on `ButtonStyleButton`,
/// so they are read through the concrete subtype the variant renders into.
(ButtonStyle?, ButtonStyle?, ButtonStyle) _layers(WidgetTester tester) {
  final context = tester.element(find.bySubtype<ButtonStyleButton>());
  final button = _chassis(tester);
  return switch (button) {
    final FilledButton b => (
        b.style,
        b.themeStyleOf(context),
        b.defaultStyleOf(context)
      ),
    final OutlinedButton b => (
        b.style,
        b.themeStyleOf(context),
        b.defaultStyleOf(context)
      ),
    final TextButton b => (
        b.style,
        b.themeStyleOf(context),
        b.defaultStyleOf(context)
      ),
    _ => throw StateError('Unexpected chassis: ${button.runtimeType}'),
  };
}

/// Resolves the button's effective style the way Flutter does: the widget's
/// own style wins per-property, and the theme fills in everything it leaves
/// null. Reading only the widget style would hide whether governed geometry
/// still reaches the destructive variant.
ButtonStyle _effectiveStyle(WidgetTester tester) {
  final (widget, theme, defaults) = _layers(tester);
  // Precedence must match ButtonStyleButton.build: widget wins, then theme,
  // then framework defaults. `merge` fills this style's nulls from the other,
  // so the widget style has to be the receiver.
  return (widget ?? const ButtonStyle()).merge(theme).merge(defaults);
}

/// Resolves one colour property exactly as `ButtonStyleButton.build` does:
/// each layer is resolved against the states first, and only a null *result*
/// falls through to the next layer.
///
/// This is not the same as merging the styles and resolving once. The
/// destructive variant supplies a property that deliberately resolves to null
/// on the disabled state so the theme's disabled colour applies; a
/// property-level merge would keep the variant's property and report null,
/// hiding the fall-through this contract depends on.
Color? _resolveColor(
  WidgetTester tester,
  WidgetStateProperty<Color?>? Function(ButtonStyle? style) get,
  Set<WidgetState> states,
) {
  final (widget, theme, defaults) = _layers(tester);
  return get(widget)?.resolve(states) ??
      get(theme)?.resolve(states) ??
      get(defaults)?.resolve(states);
}

Color? _foreground(WidgetTester tester, Set<WidgetState> states) =>
    _resolveColor(tester, (s) => s?.foregroundColor, states);

Color? _background(WidgetTester tester, Set<WidgetState> states) =>
    _resolveColor(tester, (s) => s?.backgroundColor, states);

Color? _overlay(WidgetTester tester, Set<WidgetState> states) =>
    _resolveColor(tester, (s) => s?.overlayColor, states);

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

    testWidgets('renders through the filled chassis, not the outlined one',
        (tester) async {
      await _pump(
        tester,
        TioButton.destructive(label: 'Remove', onPressed: () {}),
      );

      expect(
        find.descendant(
          of: find.byType(TioButton),
          matching: find.byType(FilledButton),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(TioButton),
          matching: find.byType(OutlinedButton),
        ),
        findsNothing,
      );
    });

    testWidgets('uses a translucent danger tint behind danger content',
        (tester) async {
      final colors = await _pump(
        tester,
        TioButton.destructive(label: 'Remove', onPressed: () {}),
      );

      expect(
        _background(tester, const {}),
        colors.danger.withAlpha(TioAlpha.alpha35),
      );
      expect(_foreground(tester, const {}), colors.danger);
    });

    testWidgets('carries no outline', (tester) async {
      await _pump(
        tester,
        TioButton.destructive(label: 'Remove', onPressed: () {}),
      );

      // FilledButton sets no side and the variant adds none, so a border
      // appearing here would mean the outlined contract leaked back in.
      expect(_effectiveStyle(tester).side?.resolve(const {}), isNull);
    });

    testWidgets('state layer stays danger-based, not primary-based',
        (tester) async {
      final colors = await _pump(
        tester,
        TioButton.destructive(label: 'Remove', onPressed: () {}),
      );

      expect(
        _overlay(tester, const {WidgetState.pressed}),
        colors.danger.withValues(alpha: TioButtonTokens.pressedStateOpacity),
      );
      expect(
        _overlay(tester, const {WidgetState.focused}),
        colors.danger.withValues(alpha: TioButtonTokens.focusedStateOpacity),
      );
      expect(
        _overlay(tester, const {WidgetState.hovered}),
        colors.danger.withValues(alpha: TioButtonTokens.hoveredStateOpacity),
      );
    });

    testWidgets('never falls back to the primary action colour in any mode',
        (tester) async {
      for (final mode in TioThemeMode.values) {
        final colors = await _pump(
          tester,
          TioButton.destructive(label: 'Remove', onPressed: () {}),
          mode: mode,
        );

        // Asserting in every mode is what catches a variant silently routed
        // back to the primary filled treatment.
        expect(_foreground(tester, const {}), colors.danger);
        expect(_foreground(tester, const {}), isNot(colors.primary));
        expect(
          _background(tester, const {}),
          colors.danger.withAlpha(TioAlpha.alpha35),
        );
        expect(_background(tester, const {}), isNot(colors.primary));
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
      // shared disabled treatment would grey out the tint and spinner
      // mid-delete.
      expect(
        _background(tester, const {WidgetState.disabled}),
        colors.danger.withAlpha(TioAlpha.alpha35),
      );
      expect(
        _foreground(tester, const {WidgetState.disabled}),
        colors.danger,
      );
      expect(find.text('Removing'), findsOneWidget);

      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(spinner.color, colors.danger);

      // Still non-interactive while the delete is in flight.
      expect(_chassis(tester).onPressed, isNull);
    });

    testWidgets(
        'a genuinely disabled destructive action keeps the governed '
        'disabled treatment', (tester) async {
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
      expect(_chassis(tester).onPressed, isNull);

      // The variant returns null for this state so the shared filled-button
      // disabled colours resolve, rather than a second destructive-disabled
      // token family.
      expect(
        _background(tester, const {WidgetState.disabled}),
        colors.primary.withValues(
          alpha: TioButtonTokens.disabledContainerOpacity,
        ),
      );
      expect(
        _foreground(tester, const {WidgetState.disabled}),
        colors.textPrimary.withValues(
          alpha: TioButtonTokens.disabledContentOpacity,
        ),
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
    testWidgets('destructive inherits the same chassis as primary',
        (tester) async {
      await _pump(
        tester,
        TioButton.destructive(label: 'Remove', onPressed: () {}),
      );
      final destructive = _effectiveStyle(tester);

      await _pump(
        tester,
        TioButton.primary(label: 'Save', onPressed: () {}),
      );
      final primary = _effectiveStyle(tester);

      // Geometry is shared; only the colour roles differ. This is the whole
      // point of the variant living inside TioButton.
      expect(
        destructive.minimumSize?.resolve(const {}),
        primary.minimumSize?.resolve(const {}),
      );
      expect(
        destructive.minimumSize?.resolve(const {})?.height,
        TioButtonTokens.height,
      );
      expect(
        destructive.shape?.resolve(const {}),
        primary.shape?.resolve(const {}),
      );
      expect(
        destructive.padding?.resolve(const {}),
        primary.padding?.resolve(const {}),
      );
      expect(
        destructive.textStyle?.resolve(const {}),
        primary.textStyle?.resolve(const {}),
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
