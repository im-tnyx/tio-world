import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  Widget app({
    required _FakeProfileAccountRepository usernameRepository,
    required _FakeAccountSetupRepository setupRepository,
    bool trustedPhone = false,
    Future<void> Function()? onCompleted,
    Future<void> Function()? onExit,
  }) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: AccountSetupFlowPage(
        usernameRepository: usernameRepository,
        accountSetupRepository: setupRepository,
        hasTrustedPhoneIdentity: trustedPhone,
        onCompleted: onCompleted ?? () async {},
        onExitRequested: onExit ?? () async {},
      ),
    );
  }

  testWidgets('fresh account flows Username then optional Mobile', (tester) async {
    final usernameRepository = _FakeProfileAccountRepository();
    final setupRepository = _FakeAccountSetupRepository(
      const AccountSetupAccountState(),
    );
    var completed = 0;

    await tester.pumpWidget(
      app(
        usernameRepository: usernameRepository,
        setupRepository: setupRepository,
        onCompleted: () async => completed++,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your username'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.textContaining('Skip'), findsNothing);
    expect(
      find.byKey(const ValueKey('account-setup-username-helper')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('account-setup-mobile-info')),
      findsNothing,
    );

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'Tio.User',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('account-setup-continue')));
    await tester.pumpAndSettle();

    expect(usernameRepository.saved, ['tio.user']);
    expect(find.text("What's your mobile number?"), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-setup-mobile-helper')),
      findsOneWidget,
    );
    expect(
      find.text('Mobile is optional. You can leave it blank and continue.'),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('account-setup-mobile-info')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('account-setup-continue')));
    await tester.pump();

    expect(setupRepository.completeCalls, 1);
    expect(setupRepository.lastMobile, '');
    expect(completed, 1);
  });

  testWidgets('Mobile info action opens explanatory reusable TioSheet',
      (tester) async {
    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: _FakeAccountSetupRepository(
          const AccountSetupAccountState(username: 'existing.user'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Why do we need this information?'),
      findsOneWidget,
    );
    expect(
      tester.widget(find.byKey(const ValueKey('account-setup-mobile-info'))),
      isA<TioInlineInfoAction>(),
    );

    await tester.tap(find.byKey(const ValueKey('account-setup-mobile-info')));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const ValueKey('account-setup-mobile-info-sheet'));
    expect(sheet, findsOneWidget);
    expect(find.byType(TioSheet), findsOneWidget);
    expect(
      find.text('Why we ask for your mobile number'),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.textContaining('account recovery')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.textContaining('future verification'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.textContaining('Account Settings')),
      findsOneWidget,
    );
  });

  testWidgets('entered mobile persists but remains unverified', (tester) async {
    final setupRepository = _FakeAccountSetupRepository(
      const AccountSetupAccountState(username: 'existing.user'),
    );
    var completed = 0;

    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: setupRepository,
        onCompleted: () async => completed++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('account-setup-mobile-input')),
      '9876543210',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('account-setup-continue')));
    await tester.pump();

    expect(setupRepository.lastMobile, '+91 9876543210');
    expect(setupRepository.state.isMobileVerified, isFalse);
    expect(setupRepository.state.isCompleted, isTrue);
    expect(completed, 1);
  });

  testWidgets('resume after username opens directly at Mobile', (tester) async {
    final setupRepository = _FakeAccountSetupRepository(
      const AccountSetupAccountState(username: 'existing.user'),
    );

    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: setupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("What's your mobile number?"), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('Choose your username'), findsNothing);
    expect(
      find.byKey(const ValueKey('account-setup-mobile-info')),
      findsOneWidget,
    );
  });

  testWidgets('trusted phone skips optional Mobile after username',
      (tester) async {
    final usernameRepository = _FakeProfileAccountRepository();
    final setupRepository = _FakeAccountSetupRepository(
      const AccountSetupAccountState(),
    );
    var completed = 0;

    await tester.pumpWidget(
      app(
        usernameRepository: usernameRepository,
        setupRepository: setupRepository,
        trustedPhone: true,
        onCompleted: () async => completed++,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your username'), findsOneWidget);
    expect(find.text('1 / 1'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'phone.user',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('account-setup-continue')));
    await tester.pump();

    expect(setupRepository.completeCalls, 1);
    expect(setupRepository.lastMobile, isNull);
    expect(completed, 1);
  });

  testWidgets('first-step Back exits parent flow', (tester) async {
    var exits = 0;
    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: _FakeAccountSetupRepository(
          const AccountSetupAccountState(),
        ),
        onExit: () async => exits++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-setup-back-button')));
    await tester.pump();

    expect(exits, 1);
  });

  testWidgets('Back from Mobile returns to Username before exiting', (tester) async {
    var exits = 0;
    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: _FakeAccountSetupRepository(
          const AccountSetupAccountState(),
        ),
        onExit: () async => exits++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'back.user',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('account-setup-continue')));
    await tester.pumpAndSettle();
    expect(find.text("What's your mobile number?"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('account-setup-back-button')));
    await tester.pumpAndSettle();

    expect(find.text('Choose your username'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-setup-mobile-info')),
      findsNothing,
    );
    expect(exits, 0);
  });

  testWidgets('Account Setup footer stays fixed without an extra divider',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(
        usernameRepository: _FakeProfileAccountRepository(),
        setupRepository: _FakeAccountSetupRepository(
          const AccountSetupAccountState(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('account-setup-back-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-setup-content')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-setup-footer')), findsOneWidget);
    expect(find.byKey(const ValueKey('account-setup-continue')), findsOneWidget);
    expect(find.text('Choose your username'), findsOneWidget);

    final helper = find.byKey(const ValueKey('account-setup-username-helper'));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('account-setup-content')),
        matching: helper,
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('account-setup-footer')),
        matching: helper,
      ),
      findsNothing,
    );

    final footer = tester.widget<Container>(
      find.byKey(const ValueKey('account-setup-footer')),
    );
    expect(footer.decoration, isNull);

    final footerRect = tester.getRect(
      find.byKey(const ValueKey('account-setup-footer')),
    );
    expect(footerRect.bottom, closeTo(852, 1));
    expect(tester.takeException(), isNull);
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
