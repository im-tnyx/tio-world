import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  Widget app({
    required _FakeProfileAccountRepository usernameRepository,
    required _FakeAccountSetupRepository setupRepository,
    bool trustedEmail = false,
    bool trustedPhone = true,
    String initialEmail = '',
    Future<void> Function(String email)? requestEmailVerification,
    Future<void> Function()? onCompleted,
  }) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: AccountSetupFlowPage(
        usernameRepository: usernameRepository,
        accountSetupRepository: setupRepository,
        hasTrustedEmailIdentity: trustedEmail,
        hasTrustedPhoneIdentity: trustedPhone,
        initialEmail: initialEmail,
        requestOptionalEmailVerification: requestEmailVerification,
        onCompleted: onCompleted ?? () async {},
        onExitRequested: () async {},
      ),
    );
  }

  testWidgets('trusted Phone flows Username then optional Email', (tester) async {
    final usernameRepository = _FakeProfileAccountRepository();
    final setupRepository = _FakeAccountSetupRepository(
      const AccountSetupAccountState(),
    );

    await tester.pumpWidget(
      app(
        usernameRepository: usernameRepository,
        setupRepository: setupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your username'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'phone.user',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('account-setup-continue')));
    await tester.pumpAndSettle();

    expect(find.text("What's your email address?"), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-setup-email-input')),
      findsOneWidget,
    );
  });

  testWidgets('optional Email can be skipped and setup completes', (tester) async {
    final setupRepository = _FakeAccountSetupRepository(
      const AccountSetupAccountState(username: 'phone.user'),
    );
    var requestCalls = 0;
    var completed = 0;

    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: setupRepository,
        requestEmailVerification: (_) async => requestCalls++,
        onCompleted: () async => completed++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-setup-continue')));
    await tester.pump();

    expect(requestCalls, 0);
    expect(setupRepository.completeCalls, 1);
    expect(setupRepository.lastMobile, isNull);
    expect(completed, 1);
  });

  testWidgets('entered Email delegates to Auth request before completion',
      (tester) async {
    final setupRepository = _FakeAccountSetupRepository(
      const AccountSetupAccountState(username: 'phone.user'),
    );
    final requested = <String>[];
    var completed = 0;

    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: setupRepository,
        requestEmailVerification: (email) async => requested.add(email),
        onCompleted: () async => completed++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('account-setup-email-input')),
      ' New.User@example.com ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('account-setup-continue')));
    await tester.pump();

    expect(requested, ['New.User@example.com']);
    expect(setupRepository.completeCalls, 1);
    expect(completed, 1);
  });

  testWidgets('malformed optional Email cannot continue', (tester) async {
    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: _FakeAccountSetupRepository(
          const AccountSetupAccountState(username: 'phone.user'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('account-setup-email-input')),
      'not-an-email',
    );
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('account-setup-continue')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('both trusted identities skip complementary contact',
      (tester) async {
    final setupRepository = _FakeAccountSetupRepository(
      const AccountSetupAccountState(username: 'both.user'),
    );
    var completed = 0;

    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: setupRepository,
        trustedEmail: true,
        trustedPhone: true,
        onCompleted: () async => completed++,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('account-setup-email-input')), findsNothing);
    expect(find.byKey(const ValueKey('account-setup-mobile-input')), findsNothing);
    expect(setupRepository.completeCalls, 1);
    expect(completed, 1);
  });
}

class _FakeAccountSetupRepository implements AccountSetupRepository {
  _FakeAccountSetupRepository(this.state);

  AccountSetupAccountState state;
  int completeCalls = 0;
  String? lastMobile;

  @override
  Future<AccountSetupAccountState> readAccountSetupState() async => state;

  @override
  Future<void> completeAccountSetup({String? mobile}) async {
    completeCalls++;
    lastMobile = mobile;
    state = AccountSetupAccountState(
      username: state.username,
      mobile: mobile ?? state.mobile,
      isMobileVerified: mobile == null ? state.isMobileVerified : false,
      isCompleted: true,
    );
  }
}

class _FakeProfileAccountRepository implements ProfileAccountRepository {
  final List<String> saved = [];

  @override
  Future<String?> currentUsername() async => null;

  @override
  Future<UsernameAvailabilityCheck> checkUsernameAvailability(
    String username,
  ) async {
    final normalized = username.trim().toLowerCase();
    return UsernameAvailabilityCheck(
      normalized: normalized,
      isAvailable: true,
    );
  }

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<void> updateUsername(String username) async {
    saved.add(username.trim().toLowerCase());
  }

  @override
  Future<void> updateAccountSettings({
    required String username,
    required String mobile,
  }) async {}
}
