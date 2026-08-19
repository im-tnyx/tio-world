import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  Widget buildApp({
    required TextEditingController controller,
    bool isVerified = false,
    VoidCallback? onVerifyPressed,
  }) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(TioSpacing.lg),
          child: TioMobileNumberField(
            fieldKey: const ValueKey('mobile-field'),
            controller: controller,
            isVerified: isVerified,
            onVerifyPressed: onVerifyPressed,
            onChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('verify action appears only for entered value when opted in',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var verifyCalls = 0;

    await tester.pumpWidget(
      buildApp(
        controller: controller,
        onVerifyPressed: () => verifyCalls++,
      ),
    );

    expect(find.text('🇮🇳'), findsOneWidget);
    expect(find.text('+91'), findsOneWidget);
    expect(find.text('Verify'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('mobile-field')),
      '9876543210',
    );
    await tester.pump();

    expect(find.text('Verify'), findsOneWidget);
    await tester.tap(find.text('Verify'));
    expect(verifyCalls, 1);
  });

  testWidgets('trusted verified state shows badge instead of Verify',
      (tester) async {
    final controller = TextEditingController(text: '9876543210');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildApp(
        controller: controller,
        isVerified: true,
        onVerifyPressed: () {},
      ),
    );

    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(find.text('Verify'), findsNothing);
  });
}
