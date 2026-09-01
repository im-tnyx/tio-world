import 'dart:async';

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

  group('username field (#24-D, TioUsernameInputField capsule appearance)', () {
    testWidgets(
        'renders as a fixed-height capsule row, not a floating-label field',
        (tester) async {
      await tester.pumpWidget(
        themedApp(
          home: const AccountSettingsPage(
            username: 'member_initial',
            linkedProvider: 'phone + email',
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('tio-username-input')),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        container.constraints,
        const BoxConstraints.tightFor(height: 56),
      );
      expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);
      expect(find.text('Username'), findsNothing);
    });

    testWidgets(
        'renders the persisted username in a neutral idle state, matching '
        'the pre-#24-D contract', (tester) async {
      await tester.pumpWidget(
        themedApp(
          home: const AccountSettingsPage(
            username: 'member_initial',
            linkedProvider: 'phone + email',
          ),
        ),
      );

      // No status icon of any kind for the account's own already-persisted
      // username -- nothing to check, nothing to save.
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('tio-username-input')),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      // Normal (non status-tinted) border: alpha40, hairline width.
      expect(border.top.width, TioStroke.width1);
    });

    testWidgets('extraInputFormatters still blocks disallowed characters',
        (tester) async {
      await tester.pumpWidget(
        themedApp(
          home: const AccountSettingsPage(username: 'member_initial'),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'bad name!#',
      );
      await tester.pump();

      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('tio-username-input')),
            )
            .controller
            ?.text,
        'badname',
      );
    });

    testWidgets(
        'without a real availability callback, checking never claims false success',
        (tester) async {
      await tester.pumpWidget(
        themedApp(
          home: const AccountSettingsPage(username: 'member_initial'),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'brand_new_handle',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(
        find.text('Username availability could not be verified.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'checking -> available via injected callback shows check and enables Save',
        (tester) async {
      var saveCalls = 0;

      await tester.pumpWidget(
        themedApp(
          home: AccountSettingsPage(
            username: 'member_initial',
            onCheckUsernameAvailability: (handle) async {
              return const UsernameAvailabilityResult(isAvailable: true);
            },
            onSave: ({required username, required phoneNumber}) async {
              saveCalls++;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'brand_new_handle',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(saveCalls, 1);
    });

    testWidgets('unavailable result blocks Save and surfaces suggestions',
        (tester) async {
      var saveCalls = 0;

      await tester.pumpWidget(
        themedApp(
          home: AccountSettingsPage(
            username: 'member_initial',
            onCheckUsernameAvailability: (handle) async {
              return const UsernameAvailabilityResult(
                isAvailable: false,
                message: 'This username is already taken. Try another.',
                suggestions: ['taken_fit', 'taken_95'],
              );
            },
            onSave: ({required username, required phoneNumber}) async {
              saveCalls++;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'taken',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('@taken_fit'), findsOneWidget);
      expect(find.text('@taken_95'), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(saveCalls, 0);
    });

    testWidgets('tapping a suggestion applies it and rechecks availability',
        (tester) async {
      final checked = <String>[];

      await tester.pumpWidget(
        themedApp(
          home: AccountSettingsPage(
            username: 'member_initial',
            onCheckUsernameAvailability: (handle) async {
              checked.add(handle);
              if (handle == 'taken') {
                return const UsernameAvailabilityResult(
                  isAvailable: false,
                  suggestions: ['taken_fit'],
                );
              }
              return const UsernameAvailabilityResult(isAvailable: true);
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'taken',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('@taken_fit'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(checked, ['taken', 'taken_fit']);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('tio-username-input')),
            )
            .controller
            ?.text,
        'taken_fit',
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('a stale in-flight check cannot overwrite a newer typed value',
        (tester) async {
      final pending = <String, Completer<UsernameAvailabilityResult>>{};

      await tester.pumpWidget(
        themedApp(
          home: AccountSettingsPage(
            username: 'member_initial',
            onCheckUsernameAvailability: (handle) {
              final completer = Completer<UsernameAvailabilityResult>();
              pending[handle] = completer;
              return completer.future;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'first_handle',
      );
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'second_handle',
      );
      await tester.pump(const Duration(milliseconds: 500));

      pending['first_handle']!.complete(
        const UsernameAvailabilityResult(isAvailable: true),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      pending['second_handle']!.complete(
        const UsernameAvailabilityResult(isAvailable: true),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets(
        'reverting to the current username while an older check is in flight '
        'cannot be overwritten by that check', (tester) async {
      final pending = <String, Completer<UsernameAvailabilityResult>>{};

      await tester.pumpWidget(
        themedApp(
          home: AccountSettingsPage(
            username: 'member_initial',
            onCheckUsernameAvailability: (handle) {
              final completer = Completer<UsernameAvailabilityResult>();
              pending[handle] = completer;
              return completer.future;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'temporary_handle',
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(pending.containsKey('temporary_handle'), isTrue);

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'member_initial',
      );
      await tester.pump();

      // Reverting to the persisted username is idle/neutral, not available --
      // nothing actually changed, matching the pre-#24-D Account Settings
      // contract. See the "renders the persisted username in a neutral idle
      // state" test above for the initial-mount counterpart.
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);

      pending['temporary_handle']!.complete(
        const UsernameAvailabilityResult(isAvailable: false),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets(
        'a late server conflict on Save blocks the field and offers a fresh recheck',
        (tester) async {
      final onCheckCalls = <String>[];

      await tester.pumpWidget(
        themedApp(
          home: AccountSettingsPage(
            username: 'member_initial',
            phoneNumber: '9876543210',
            isPhoneVerified: true,
            onCheckUsernameAvailability: (handle) async {
              onCheckCalls.add(handle);
              return const UsernameAvailabilityResult(isAvailable: true);
            },
            onSave: ({required username, required phoneNumber}) async {
              throw const TioUsernameConflictException(
                'That username was just taken. Please choose another.',
              );
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'just_taken',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(onCheckCalls, ['just_taken']);

      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(
        find.text('That username was just taken. Please choose another.'),
        findsOneWidget,
      );

      // The refresh token bump reissues a fresh check for the same handle.
      expect(onCheckCalls, ['just_taken', 'just_taken']);
    });
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
