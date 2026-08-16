import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('TioOtpVerificationDialog opens, takes OTP and verifies successfully',
      (tester) async {
    String? verifiedCode;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                verifiedCode = await showTioOtpVerificationDialog(
                  context: context,
                  targetLabel: 'email',
                  onVerify: (code) async => code == '123456',
                );
              },
              child: const Text('Verify Email'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Verify Email'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your Code'), findsOneWidget);
    expect(
      find.text('Please check your email for the verification code.'),
      findsOneWidget,
    );
    expect(find.text('VERIFY'), findsOneWidget);
    expect(find.text('BACK'), findsOneWidget);

    // Enter wrong code
    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.text('VERIFY'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid code. Please try again.'), findsOneWidget);

    // Enter correct code
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('VERIFY'));
    await tester.pumpAndSettle();

    expect(verifiedCode, '123456');
  });
}
