import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  testWidgets('system Back uses Account Setup parent exit handling',
      (tester) async {
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: AccountSetupFlowPage(
          usernameRepository: _UsernameRepository(),
          accountSetupRepository: _SetupRepository(),
          hasTrustedPhoneIdentity: false,
          onCompleted: () async {},
          onExitRequested: () async => exits++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(exits, 1);
    expect(find.text('Choose your username'), findsOneWidget);
  });
}

class _SetupRepository implements AccountSetupRepository {
  @override
  Future<AccountSetupAccountState> readAccountSetupState() async =>
      const AccountSetupAccountState();

  @override
  Future<void> completeAccountSetup({String? mobile}) async {}
}

class _UsernameRepository implements ProfileAccountRepository {
  @override
  Future<String?> currentUsername() async => null;

  @override
  Future<UsernameAvailabilityCheck> checkUsernameAvailability(
    String username,
  ) async =>
      UsernameAvailabilityCheck(
        normalized: username.trim().toLowerCase(),
        isAvailable: true,
      );

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
