import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

Future<(BoxDecoration, double)> _render(
  WidgetTester tester, {
  required TioThemeMode mode,
  double? outlinedBorderWidth,
}) async {
  late TioColors palette;
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => TioTheme(
      config: TioThemeConfig(mode: mode),
      child: child ?? const SizedBox.shrink(),
    ),
    home: Scaffold(
      body: Builder(builder: (context) {
        palette = context.tioColors;
        return TioCard(
          variant: TioCardVariant.outlined,
          outlinedBorderWidth: outlinedBorderWidth,
          child: const SizedBox(height: 38, width: 72),
        );
      }),
    ),
  ));
  final box = find.descendant(
    of: find.byType(TioCard),
    matching: find.byType(Container),
  );
  final decoration = tester.widget<Container>(box).decoration! as BoxDecoration;
  expect(decoration.borderRadius, BorderRadius.circular(TioCardTokens.radius));
  expect(decoration.color, Colors.transparent);
  expect((decoration.border! as Border).top.color, palette.outlineStrong);
  return (decoration, tester.getSize(box).height);
}

void main() {
  for (final mode in [
    TioThemeMode.light,
    TioThemeMode.dark,
    TioThemeMode.tioDark,
  ]) {
    testWidgets('outlined TioCard retains 1dp default in ${mode.name}',
        (tester) async {
      final (decoration, height) = await _render(tester, mode: mode);
      expect((decoration.border! as Border).top.width, TioStroke.width1);
      expect(height, 38 + 2 * TioCardTokens.padding + 2 * TioStroke.width1);
    });

    testWidgets('outlined TioCard accepts governed 0.75dp in ${mode.name}',
        (tester) async {
      final (decoration, height) = await _render(
        tester,
        mode: mode,
        outlinedBorderWidth: TioCardTokens.borderThin,
      );
      expect((decoration.border! as Border).top.width, TioStroke.width075);
      expect(height,
          38 + 2 * TioCardTokens.padding + 2 * TioStroke.width075);
    });
  }

  test('outlinedBorderWidth cannot be used on other card variants', () {
    expect(
      () => TioCard(
        variant: TioCardVariant.surface,
        outlinedBorderWidth: TioStroke.width075,
        child: const SizedBox(),
      ),
      throwsAssertionError,
    );
    expect(
      () => TioCard(
        variant: TioCardVariant.outlined,
        outlinedBorderWidth: 0,
        child: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });
}
