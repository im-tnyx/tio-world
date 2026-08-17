import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  testWidgets('username checkpoint uses auth chrome and fixed footer',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var backCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: UsernameSetupPage(
          repository: _FakeProfileAccountRepository(),
          onCompleted: () async {},
          onBack: () async => backCalls++,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('username-setup-back-button')), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Choose your username'), findsOneWidget);
    expect(find.byKey(const ValueKey('username-setup-content')), findsOneWidget);
    expect(find.byKey(const ValueKey('username-setup-footer')), findsOneWidget);
    expect(find.byKey(const ValueKey('username-setup-continue')), findsOneWidget);

    final footerRect = tester.getRect(
      find.byKey(const ValueKey('username-setup-footer')),
    );
    expect(footerRect.bottom, closeTo(852, 1));

    await tester.tap(find.byKey(const ValueKey('username-setup-back-button')));
    await tester.pump();
    expect(backCalls, 1);
    expect(tester.takeException(), isNull);
  });
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
