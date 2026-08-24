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

  testWidgets('Verify cannot show local success without a real callback',
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

    await tester.tap(find.text('Verify').first);
    await tester.pumpAndSettle();

    expect(
      find.text('Email verification is unavailable right now.'),
      findsOneWidget,
    );
    expect(find.text('Please enter your Code'), findsNothing);
    expect(find.text('Email verified successfully!'), findsNothing);
  });

  testWidgets('real verification callback controls Email success feedback',
      (tester) async {
    String? verifiedEmail;

    await tester.pumpWidget(
      themedApp(
        home: AccountSettingsPage(
          username: 'santosh_initial',
          email: 'santosh@example.com',
          isEmailVerified: false,
          onVerifyEmailPressed: (email) async {
            verifiedEmail = email;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(verifiedEmail, 'santosh@example.com');
    expect(find.text('Email verified successfully!'), findsOneWidget);
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
                        isEmailVerified: true,
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

  testWidgets('changed phone must verify before Save Changes can persist',
      (tester) async {
    var saveCalls = 0;

    await tester.pumpWidget(
      themedApp(
        home: AccountSettingsPage(
          username: 'santosh_initial',
          email: 'santosh@example.com',
          phoneNumber: '9876543210',
          isEmailVerified: true,
          isPhoneVerified: true,
          onSave: ({required username, required phoneNumber}) async {
            saveCalls++;
          },
        ),
      ),
    );

    final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    await tester.enterText(find.byWidget(textFields.last), '9123456789');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(saveCalls, 0);
    expect(
      find.text('Verify the new phone number before saving.'),
      findsOneWidget,
    );
    expect(find.text('Account Settings'), findsOneWidget);
  });
}
