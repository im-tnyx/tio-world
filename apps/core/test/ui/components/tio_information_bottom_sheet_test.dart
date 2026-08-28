import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('information sheet renders and dismisses through its primary action',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTioInformationBottomSheet(
                context: context,
                title: 'Information',
                message: 'Helpful explanation.',
                actionLabel: 'Understood',
                icon: Icons.info_outline_rounded,
              ),
              child: const Text('Open information'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open information'));
    await tester.pumpAndSettle();

    expect(find.byType(TioInformationBottomSheet), findsOneWidget);
    expect(find.byType(TioSheet), findsOneWidget);
    expect(find.text('Information'), findsOneWidget);
    expect(find.text('Helpful explanation.'), findsOneWidget);
    expect(find.text('Understood'), findsOneWidget);

    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();

    expect(find.byType(TioInformationBottomSheet), findsNothing);
  });

  testWidgets('confirmation sheet returns the selected result', (tester) async {
    bool? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                confirmed = await showTioConfirmationBottomSheet(
                  context: context,
                  title: 'Confirm',
                  message: 'Continue with this action?',
                  cancelLabel: 'Stay',
                  confirmLabel: 'Continue',
                );
              },
              child: const Text('Open confirmation'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });
}
