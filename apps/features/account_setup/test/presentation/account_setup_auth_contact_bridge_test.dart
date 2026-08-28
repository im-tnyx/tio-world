import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  Widget app({
    required _BridgedAccountSetupRepository setupRepository,
    Future<void> Function()? onCompleted,
  }) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: AccountSetupFlowPage(
        usernameRepository: _FakeProfileAccountRepository(),
        accountSetupRepository: setupRepository,
        // Legacy constructor input is deliberately false here. The app-composed
        // bridge must remain the authoritative source when it is available.
        hasTrustedPhoneIdentity: false,
        onCompleted: onCompleted ?? () async {},
        onExitRequested: () async {},
      ),
    );
  }

  testWidgets('app bridge plans trusted Phone to optional Email', (tester) async {
    final setupRepository = _BridgedAccountSetupRepository(
      state: const AccountSetupAccountState(username: 'phone.user'),
      hasTrustedEmailIdentity: false,
      hasTrustedPhoneIdentity: true,
      currentEmail: '',
    );

    await tester.pumpWidget(app(setupRepository: setupRepository));
    await tester.pumpAndSettle();

    expect(find.text("What's your email address?"), findsOneWidget);
    expect(find.byKey(const ValueKey('account-setup-mobile-input')), findsNothing);
  });

  testWidgets('Email request delegates through app bridge before completion',
      (tester) async {
    final setupRepository = _BridgedAccountSetupRepository(
      state: const AccountSetupAccountState(username: 'phone.user'),
      hasTrustedEmailIdentity: false,
      hasTrustedPhoneIdentity: true,
      currentEmail: 'pending@example.com',
    );
    var completed = 0;

    await tester.pumpWidget(
      app(
        setupRepository: setupRepository,
        onCompleted: () async => completed++,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<TioInput>(
        find.byKey(const ValueKey('account-setup-email-input')),
      ).controller?.text,
      'pending@example.com',
    );

    await tester.tap(find.byKey(const ValueKey('account-setup-continue')));
    await tester.pump();

    expect(setupRepository.requestedEmails, ['pending@example.com']);
    expect(setupRepository.completeCalls, 1);
    expect(completed, 1);
  });

  testWidgets('both trusted bridge contacts skip complementary collection',
      (tester) async {
    final setupRepository = _BridgedAccountSetupRepository(
      state: const AccountSetupAccountState(username: 'both.user'),
      hasTrustedEmailIdentity: true,
      hasTrustedPhoneIdentity: true,
      currentEmail: 'verified@example.com',
    );
    var completed = 0;

    await tester.pumpWidget(
      app(
        setupRepository: setupRepository,
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

class _BridgedAccountSetupRepository
    implements AccountSetupRepository, AccountSetupAuthContactBridge {
  _BridgedAccountSetupRepository({
    required this.state,
    required this.hasTrustedEmailIdentity,
    required this.hasTrustedPhoneIdentity,
    required this.currentEmail,
  });

  AccountSetupAccountState state;
  int completeCalls = 0;
  final List<String> requestedEmails = [];

  @override
  final bool hasTrustedEmailIdentity;

  @override
  final bool hasTrustedPhoneIdentity;

  @override
  final String currentEmail;

  @override
  Future<AccountSetupAccountState> readAccountSetupState() async => state;

  @override
  Future<void> completeAccountSetup({String? mobile}) async {
    completeCalls++;
    state = AccountSetupAccountState(
      username: state.username,
      mobile: mobile ?? state.mobile,
      isMobileVerified: mobile == null ? state.isMobileVerified : false,
      isCompleted: true,
    );
  }

  @override
  Future<void> requestOptionalEmailVerification(String email) async {
    requestedEmails.add(email);
  }
}

class _FakeProfileAccountRepository implements ProfileAccountRepository {
  @override
  Future<String?> currentUsername() async => null;

  @override
  Future<UsernameAvailabilityCheck> checkUsernameAvailability(
    String username,
  ) async {
    return UsernameAvailabilityCheck(
      normalized: username.trim().toLowerCase(),
      isAvailable: true,
    );
  }

  @override
  Future<bool> isUsernameAvailable(String username) async => true;

  @override
  Future<void> updateUsername(String username) async {}

  @override
  Future<void> updateAccountSettings({
    required String username,
    required String mobile,
  }) async {}
}
