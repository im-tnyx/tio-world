import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  Widget buildApp({required VoidCallback? onTap}) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: Scaffold(
        body: Center(
          child: TioInlineInfoAction(
            key: const ValueKey('info-action'),
            label: 'Why do we need this information?',
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  testWidgets('uses the canonical compact visual contract', (tester) async {
    await tester.pumpWidget(buildApp(onTap: () {}));

    final label = tester.widget<Text>(
      find.text('Why do we need this information?'),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));

    expect(label.style?.fontSize, TioFontSize.size12);
    expect(label.style?.fontWeight, TioFontWeight.w500);
    expect(icon.size, TioSize.dp16);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('invokes callback and exposes button semantics', (tester) async {
    var taps = 0;
    await tester.pumpWidget(buildApp(onTap: () => taps++));

    await tester.tap(find.byKey(const ValueKey('info-action')));
    await tester.pump();

    expect(taps, 1);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('info-action'))).hasFlag(
            SemanticsFlag.isButton,
          ),
      isTrue,
    );
  });
}
