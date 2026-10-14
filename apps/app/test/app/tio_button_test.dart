import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('renders all variants through their Material button owners',
      (tester) async {
    var presses = 0;

    await tester.pumpWidget(
      _ButtonTestApp(
        child: Column(
          children: [
            TioButton.primary(
              label: 'Primary',
              onPressed: () => presses++,
            ),
            TioButton.secondary(
              label: 'Secondary',
              onPressed: () => presses++,
            ),
            TioButton.ghost(
              label: 'Ghost',
              onPressed: () => presses++,
            ),
          ],
        ),
      ),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);

    await tester.tap(find.text('Primary'));
    await tester.tap(find.text('Secondary'));
    await tester.tap(find.text('Ghost'));
    expect(presses, 3);
  });

  testWidgets('supporting uses governed filled button with neutral roles',
      (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      _ButtonTestApp(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: TioButton.supporting(
          label: 'Add Set',
          leading: const Icon(Icons.add),
          expand: true,
          onPressed: () => presses++,
        ),
      ),
    );

    final button = tester.widget<TioButton>(find.byType(TioButton));
    final filled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.variant, TioButtonVariant.supporting);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    // Only the reusable supporting role is 40dp in the Set editor;
    // primary/secondary keep the governed global 46dp theme.
    expect(filled.style!.minimumSize!.resolve({})!.height, TioSize.dp40);
    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(TioSize.dp40));
    expect(filled.style!.backgroundColor!.resolve({}),
        TioColors.light.surfaceVariant);
    expect(filled.style!.foregroundColor!.resolve({}),
        TioColors.light.textPrimary);
    expect(filled.style!.foregroundColor!.resolve({WidgetState.disabled}),
        TioColors.light.textMuted);
    await tester.tap(find.text('Add Set'));
    expect(presses, 1);
  });

  for (final mode in [TioThemeMode.dark, TioThemeMode.light]) {
    testWidgets('supporting filled surface is visible in ${mode.name}',
        (tester) async {
      final palette =
          mode == TioThemeMode.dark ? TioColors.oled : TioColors.light;
      await tester.pumpWidget(_ButtonTestApp(
        config: TioThemeConfig(mode: mode),
        child: TioButton.supporting(
          label: 'Add Set',
          leading: const Icon(Icons.add),
          expand: true,
          onPressed: () {},
        ),
      ));
      final filled = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filled.style!.backgroundColor!.resolve({}),
          palette.surfaceVariant);
      expect(filled.style!.backgroundColor!.resolve({}),
          isNot(palette.background));
      expect(filled.style!.foregroundColor!.resolve({}),
          palette.textPrimary);
      expect(filled.style!.minimumSize!.resolve({})!.height,
          TioSize.dp40);
      expect(tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(TioSize.dp40));
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  }

  testWidgets('supporting disables writes and holds its theme when loading',
      (tester) async {
    var presses = 0;
    Widget supporting({bool loading = false}) => _ButtonTestApp(
      config: const TioThemeConfig(mode: TioThemeMode.dark),
      child: TioButton.supporting(
        label: 'Add Set',
        onPressed: () => presses++,
        enabled: false,
        loading: loading,
      ),
    );

    await tester.pumpWidget(supporting());
    var filled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(filled.onPressed, isNull);
    expect(filled.style!.minimumSize!.resolve({WidgetState.disabled})!.height,
        TioSize.dp40);
    expect(filled.style!.backgroundColor!.resolve({WidgetState.disabled}),
        TioColors.oled.surfaceVariant.withValues(
          alpha: TioButtonTokens.disabledContainerOpacity,
        ));
    await tester.tap(find.text('Add Set'));
    expect(presses, 0);

    await tester.pumpWidget(supporting(loading: true));
    await tester.pump();
    filled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(filled.onPressed, isNull);
    expect(filled.style!.minimumSize!.resolve({WidgetState.disabled})!.height,
        TioSize.dp40);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(filled.style!.foregroundColor!.resolve({WidgetState.disabled}),
        TioColors.oled.textPrimary);
    expect(filled.style!.backgroundColor!.resolve({WidgetState.disabled}),
        TioColors.oled.surfaceVariant);
    expect(presses, 0);
  });

  testWidgets('supporting visual surface is 40dp without shrinking '
      'the primary action', (tester) async {
    await tester.pumpWidget(_ButtonTestApp(
      child: Column(
        children: [
          TioButton.supporting(label: 'Add Set', onPressed: () {}),
          TioButton.primary(label: 'Save Routine', onPressed: () {}),
        ],
      ),
    ));
    final buttons = tester.widgetList<FilledButton>(
      find.byType(FilledButton),
    ).toList();
    expect(buttons, hasLength(2));
    expect(buttons[0].style!.minimumSize!.resolve({})!.height, TioSize.dp40);
    expect(buttons[1].style?.minimumSize, isNull);
    final theme = Theme.of(tester.element(find.byType(FilledButton).last));
    expect(theme.filledButtonTheme.style!.minimumSize!.resolve({})!.height,
        TioButtonTokens.height);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled button cannot invoke its callback', (tester) async {
    var presses = 0;

    await tester.pumpWidget(
      _ButtonTestApp(
        child: TioButton.primary(
          label: 'Continue',
          enabled: false,
          onPressed: () => presses++,
        ),
      ),
    );

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.tap(find.text('Continue'));
    expect(presses, 0);
  });

  testWidgets('loading state blocks actions and announces progress',
      (tester) async {
    final semantics = tester.ensureSemantics();
    var presses = 0;
    try {
      await tester.pumpWidget(
        _ButtonTestApp(
          child: TioButton.primary(
            label: 'Continue',
            loading: true,
            loadingLabel: 'Saving',
            onPressed: () => presses++,
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(TioButton));
      expect(node.label, 'Continue');
      expect(node.value, 'Loading');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isLiveRegion, isTrue);
      final filledButton =
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(filledButton.onPressed, isNull);
      final theme = Theme.of(tester.element(find.byType(FilledButton)));
      expect(
        filledButton.style?.backgroundColor?.resolve({WidgetState.disabled}),
        theme.colorScheme.primary,
      );
      expect(find.text('Saving'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Saving'));
      expect(presses, 0);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reduced motion uses a static loading indicator', (tester) async {
    await tester.pumpWidget(
      const _ButtonTestApp(
        config: TioThemeConfig(reducedMotion: true),
        child: TioButton.primary(
          label: 'Continue',
          loading: true,
          onPressed: null,
        ),
      ),
    );

    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        Duration.zero);
  });

  testWidgets('theme exposes visible pressed, focus, and outline states',
      (tester) async {
    late ThemeData theme;

    await tester.pumpWidget(
      _ButtonTestApp(
        child: Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const TioButton.primary(
              label: 'Continue',
              onPressed: null,
            );
          },
        ),
      ),
    );

    final filledOverlay = theme.filledButtonTheme.style?.overlayColor;
    expect(filledOverlay?.resolve({WidgetState.pressed}),
        isNot(Colors.transparent));
    expect(filledOverlay?.resolve({WidgetState.focused}),
        isNot(Colors.transparent));
    expect(filledOverlay?.resolve({WidgetState.disabled}), Colors.transparent);

    final outlinedSide = theme.outlinedButtonTheme.style?.side;
    expect(outlinedSide?.resolve({WidgetState.focused})?.width,
        TioButtonTokens.focusedOutlineWidth);
    expect(outlinedSide?.resolve({})?.width, TioButtonTokens.outlineWidth);
  });

  testWidgets('global text button theme stays finite inside app bar actions',
      (tester) async {
    await tester.pumpWidget(
      _ButtonTestApp(
        child: Scaffold(
          appBar: AppBar(
            actions: [
              TextButton(onPressed: () {}, child: const Text('Plus')),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(TextButton)).width.isFinite, isTrue);
  });

  testWidgets('keyboard focus and Enter activate the button', (tester) async {
    var presses = 0;

    await tester.pumpWidget(
      _ButtonTestApp(
        child: TioButton.primary(
          label: 'Continue',
          onPressed: () => presses++,
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(presses, 1);
  });
}

class _ButtonTestApp extends StatelessWidget {
  const _ButtonTestApp({
    required this.child,
    this.config = const TioThemeConfig(),
  });

  final Widget child;
  final TioThemeConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, appChild) => TioTheme(
        config: config,
        child: appChild ?? const SizedBox.shrink(),
      ),
      home: Scaffold(body: Center(child: child)),
    );
  }
}
