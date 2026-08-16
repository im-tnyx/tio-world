import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  testWidgets('AccountSettingsPage opens OTP verification popup on tapping verify',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: const AccountSettingsPage(
          username: 'santosh_initial',
          email: 'santosh@example.com',
          phoneNumber: '9876543210',
          isEmailVerified: false,
          isPhoneVerified: false,
          linkedProvider: 'Google',
        ),
      ),
    );

    expect(find.text('Verify'), findsNWidgets(2));

    // Tap Email Verify
    await tester.tap(find.text('Verify').first);
    await tester.pumpAndSettle();

    // Verify dialog is open
    expect(find.text('Please enter your Code'), findsOneWidget);
    expect(find.text('VERIFY'), findsOneWidget);
    expect(find.text('BACK'), findsOneWidget);

    // Tap BACK to dismiss
    await tester.tap(find.text('BACK'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your Code'), findsNothing);
  });
}
