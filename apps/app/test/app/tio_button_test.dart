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
