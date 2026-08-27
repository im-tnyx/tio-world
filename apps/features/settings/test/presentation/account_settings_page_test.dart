import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  Widget themedApp({
    required Widget home,
    GoogleIdentityLinkController? googleIdentityLinkController,
  }) {
    return ProviderScope(
      overrides: [
        if (googleIdentityLinkController != null)
          googleIdentityLinkControllerProvider.overrideWithValue(
            googleIdentityLinkController,
          ),
      ],
      child: MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: home,
      ),
    );
  }

  testWidgets('Verify cannot show local success without a real callback',
      (tester) async {
    await tester.pumpWidget(
      themedApp(
        home: const AccountSettingsPage(
          username: 'member_initial',
          email: 'member@example.com',
          phoneNumber: '9876543210',
          isEmailVerified: false,
          isPhoneVerified: false,
          linkedProvider: 'phone + email',
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
          username: 'member_initial',
          email: 'member@example.com',
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

    expect(verifiedEmail, 'member@example.com');
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
                        username: 'member_initial',
                        email: 'member@example.com',
                        phoneNumber: '9876543210',
                        isEmailVerified: true,
                        isPhoneVerified: true,
                        linkedProvider: 'phone + email',
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

    final textFields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(textFields, hasLength(3));
    expect(textFields[0].controller?.text, 'member_initial');
    expect(textFields[1].controller?.text, 'member@example.com');
    expect(textFields[2].controller?.text, '9876543210');
    expect(find.byIcon(Icons.verified_rounded), findsNWidgets(2));
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Connected'), findsNothing);

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(savedUsername, 'member_initial');
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
          username: 'member_initial',
          email: 'member@example.com',
          phoneNumber: '9876543210',
          isEmailVerified: true,
          isPhoneVerified: true,
          onSave: ({required username, required phoneNumber}) async {
            saveCalls++;
          },
        ),
      ),
    );

    final textFields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
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
          username: 'member_initial',
          email: 'member@example.com',
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

    final textFields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
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
          username: 'member_initial',
          email: 'member@example.com',
          phoneNumber: '9876543210',
          isEmailVerified: true,
          isPhoneVerified: true,
          onSave: ({required username, required phoneNumber}) async {
            saveCalls++;
          },
        ),
      ),
    );

    final textFields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
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

  testWidgets('Phone plus Email identity shows Google Connect, not Connected',
      (tester) async {
    await tester.pumpWidget(
      themedApp(
        home: const AccountSettingsPage(
          username: 'member',
          linkedProvider: 'Phone + Email',
        ),
      ),
    );

    expect(find.text('Google'), findsOneWidget);
    expect(find.byKey(const ValueKey('google-connect-action')), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.byKey(const ValueKey('google-connected-badge')), findsNothing);
    expect(find.text('Connected'), findsNothing);
  });

  testWidgets('authoritative Google link success changes Connect to Connected',
      (tester) async {
    final controller = _FakeGoogleIdentityLinkController(result: true);

    await tester.pumpWidget(
      themedApp(
        googleIdentityLinkController: controller,
        home: const AccountSettingsPage(
          username: 'member',
          linkedProvider: 'Phone + Email',
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('google-connect-action')));
    await tester.pumpAndSettle();

    expect(controller.calls, 1);
    expect(find.text('Connect'), findsNothing);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Google connected successfully!'), findsOneWidget);
  });

  testWidgets('cancelled Google link keeps Connect state', (tester) async {
    final controller = _FakeGoogleIdentityLinkController(result: false);

    await tester.pumpWidget(
      themedApp(
        googleIdentityLinkController: controller,
        home: const AccountSettingsPage(
          username: 'member',
          linkedProvider: 'Phone + Email',
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('google-connect-action')));
    await tester.pumpAndSettle();

    expect(controller.calls, 1);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Connected'), findsNothing);
  });

  testWidgets('Google provider evidence renders Connected immediately',
      (tester) async {
    await tester.pumpWidget(
      themedApp(
        home: const AccountSettingsPage(
          username: 'member',
          linkedProvider: 'Phone + Email + Google',
        ),
      ),
    );

    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Connect'), findsNothing);
  });
}

final class _FakeGoogleIdentityLinkController
    implements GoogleIdentityLinkController {
  _FakeGoogleIdentityLinkController({required this.result});

  final bool result;
  int calls = 0;

  @override
  Future<bool> linkGoogleIdentity() async {
    calls++;
    return result;
  }
}
