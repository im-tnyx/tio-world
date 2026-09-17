import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
        builder: (context, appChild) => TioTheme(child: appChild!),
        home: Scaffold(body: child),
      );

  testWidgets('confirmation intent defaults to standard', (tester) async {
    await tester.pumpWidget(app(TioConfirmationCard(
      title: 'Confirm',
      message: 'Continue?',
      confirmLabel: 'Continue',
      cancelLabel: 'Cancel',
      onConfirm: () {},
      onCancel: () {},
    )));

    final card = tester.widget<TioConfirmationCard>(
      find.byType(TioConfirmationCard),
    );
    expect(card.intent, TioConfirmationIntent.standard);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('destructive intent uses destructive shared button',
      (tester) async {
    await tester.pumpWidget(app(TioConfirmationCard(
      title: 'Log Out',
      message: 'Are you sure?',
      confirmLabel: 'Log Out',
      cancelLabel: 'Cancel',
      intent: TioConfirmationIntent.destructive,
      onConfirm: () {},
      onCancel: () {},
    )));

    final card = tester.widget<TioConfirmationCard>(
      find.byType(TioConfirmationCard),
    );
    expect(card.intent, TioConfirmationIntent.destructive);

    final filled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Log Out'),
    );
    final colors = tester.element(find.byType(TioConfirmationCard)).tioColors;
    final background = filled.style?.backgroundColor?.resolve(<WidgetState>{});
    final foreground = filled.style?.foregroundColor?.resolve(<WidgetState>{});

    expect(background, colors.danger.withAlpha(TioAlpha.alpha35));
    expect(foreground, colors.danger);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
  });
}
