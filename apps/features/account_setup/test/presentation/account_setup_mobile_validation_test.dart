import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  testWidgets('optional Mobile continues only when blank or complete',
      (tester) async {
    final setupRepository = _MobileSetupRepository();

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: AccountSetupFlowPage(
          usernameRepository: _ProfileAccountRepository(),
          accountSetupRepository: setupRepository,
          hasTrustedPhoneIdentity: false,
          onCompleted: () async {},
          onExitRequested: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final continueFinder =
        find.byKey(const ValueKey('account-setup-continue'));
    FilledButton continueButton() => tester.widget<FilledButton>(continueFinder);

    expect(continueButton().onPressed, isNotNull);

    await tester.enterText(
      find.byKey(const ValueKey('account-setup-mobile-input')),
      '91234',
    );
    await tester.pump();
    expect(continueButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('account-setup-mobile-input')),
      '9123456789',
    );
    await tester.pump();
    expect(continueButton().onPressed, isNotNull);

    await tester.tap(continueFinder);
    await tester.pump();
    expect(setupRepository.lastMobile, '+91 9123456789');
  });
}

class _MobileSetupRepository implements AccountSetupRepository {
  String? lastMobile;

  @override
  Future<AccountSetupAccountState> readAccountSetupState() async {
    return const AccountSetupAccountState(username: 'existing.user');
  }

  @override
  Future<void> completeAccountSetup({String? mobile}) async {
    lastMobile = mobile;
  }
}

class _ProfileAccountRepository implements ProfileAccountRepository {
  @override
  Future<String?> currentUsername() async => 'existing.user';

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
