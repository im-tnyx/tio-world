import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  Widget themedApp({required Widget home}) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: home,
    );
  }

  testWidgets('AccountSettingsPage opens OTP verification popup on tapping verify',
      (tester) async {
    await tester.pumpWidget(
      themedApp(
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

  testWidgets('loads persisted phone and saves account fields before popping',
      (tester) async {
    String? savedUsername;
    String? savedPhoneNumber;

    await tester.pumpWidget(
      themedApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AccountSettingsPage(
                        username: 'santosh_initial',
                        email: 'santosh@example.com',
                        phoneNumber: '9876543210',
                        isPhoneVerified: true,
                        onSave: ({
                          required username,
                          required phoneNumber,
                        }) async {
                          savedUsername = username;
                          savedPhoneNumber = phoneNumber;
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Open Account Settings'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Account Settings'));
    await tester.pumpAndSettle();

    final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(textFields, hasLength(2));
    expect(textFields.first.controller?.text, 'santosh_initial');
    expect(textFields.last.controller?.text, '9876543210');
    expect(find.byIcon(Icons.verified_rounded), findsNWidgets(2));

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(savedUsername, 'santosh_initial');
    expect(savedPhoneNumber, '9876543210');
    expect(find.text('Open Account Settings'), findsOneWidget);
    expect(find.text('Account Settings'), findsNothing);
  });
}
