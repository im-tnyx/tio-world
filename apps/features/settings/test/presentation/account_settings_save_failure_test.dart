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

  testWidgets(
    'save failure stays on page, preserves values, and allows retry',
    (tester) async {
      var saveAttempts = 0;
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
                          username: 'stable_user',
                          email: 'user@example.com',
                          phoneNumber: '9876543210',
                          onSave: ({
                            required username,
                            required phoneNumber,
                          }) async {
                            saveAttempts += 1;
                            savedUsername = username;
                            savedPhoneNumber = phoneNumber;
                            if (saveAttempts == 1) {
                              throw StateError('temporary persistence failure');
                            }
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

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.last, '9123456789');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(saveAttempts, 1);
      expect(savedUsername, 'stable_user');
      expect(savedPhoneNumber, '9123456789');
      expect(find.text('Account Settings'), findsOneWidget);
      expect(
        find.text('Could not save account settings. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Account settings saved!'), findsNothing);
      expect(find.text('Save Changes'), findsOneWidget);

      final preservedFields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(preservedFields.first.controller?.text, 'stable_user');
      expect(preservedFields.last.controller?.text, '9123456789');

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(saveAttempts, 2);
      expect(find.text('Open Account Settings'), findsOneWidget);
      expect(find.text('Account Settings'), findsNothing);
    },
  );

  testWidgets('missing save callback cannot show false success or pop',
      (tester) async {
    await tester.pumpWidget(
      themedApp(
        home: const AccountSettingsPage(
          username: 'stable_user',
          email: 'user@example.com',
          phoneNumber: '9876543210',
        ),
      ),
    );

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Account Settings'), findsOneWidget);
    expect(
      find.text(
        'Account settings are unavailable right now. Please try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Account settings saved!'), findsNothing);
    expect(find.text('Save Changes'), findsOneWidget);
  });
}
