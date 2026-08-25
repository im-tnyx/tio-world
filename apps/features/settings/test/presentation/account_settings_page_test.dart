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

  testWidgets('loads persisted account fields and saves after trusted state',
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
    expect(textFields, hasLength(3));
    expect(textFields[0].controller?.text, 'santosh_initial');
    expect(textFields[1].controller?.text, 'santosh@example.com');
    expect(textFields[2].controller?.text, '9876543210');
    expect(find.byIcon(Icons.verified_rounded), findsNWidgets(2));

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(savedUsername, 'santosh_initial');
    expect(savedPhoneNumber, '9876543210');
    expect(find.text('Open Account Settings'), findsOneWidget);
    expect(find.text('Account Settings'), findsNothing);
  });

  testWidgets('changed Email must verify before Save Changes can persist',
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
    await tester.enterText(find.byWidget(textFields[1]), 'new@example.com');
    await tester.pump();

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(saveCalls, 0);
    expect(
      find.text('Verify the new email before saving.'),
      findsOneWidget,
    );
    expect(find.text('Account Settings'), findsOneWidget);
  });

  testWidgets('changed Email can save only after provider callback succeeds',
      (tester) async {
    var saveCalls = 0;
    String? verificationTarget;

    await tester.pumpWidget(
      themedApp(
        home: AccountSettingsPage(
          username: 'santosh_initial',
          email: 'santosh@example.com',
          phoneNumber: '9876543210',
          isEmailVerified: true,
          isPhoneVerified: true,
          onVerifyEmailPressed: (email) async {
            verificationTarget = email;
            return true;
          },
          onSave: ({required username, required phoneNumber}) async {
            saveCalls++;
          },
        ),
      ),
    );

    final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    await tester.enterText(find.byWidget(textFields[1]), 'new@example.com');
    await tester.pump();

    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();
    expect(verificationTarget, 'new@example.com');

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(saveCalls, 1);
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
