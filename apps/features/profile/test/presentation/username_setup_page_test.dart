import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  testWidgets('requires verified availability before continuing', (tester) async {
    final repository = _FakeProfileAccountRepository();
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [TioColors.light]),
        home: UsernameSetupPage(
          repository: repository,
          onCompleted: () async => completed = true,
        ),
      ),
    );

    FilledButton button() => tester.widget<FilledButton>(
          find.byKey(const ValueKey('username-setup-continue')),
        );

    expect(button().onPressed, isNull);
    expect(find.textContaining('Skip'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'Tio.User',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(repository.checked, ['tio.user']);
    expect(button().onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('username-setup-continue')));
    await tester.pump();

    expect(repository.saved, ['tio.user']);
    expect(completed, isTrue);
  });

  testWidgets('keeps continue disabled when username is unavailable',
      (tester) async {
    final repository = _FakeProfileAccountRepository(available: false);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [TioColors.light]),
        home: UsernameSetupPage(
          repository: repository,
          onCompleted: () async {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'taken.user',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('username-setup-continue')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('This username is already taken.'), findsOneWidget);
  });
}

class _FakeProfileAccountRepository implements ProfileAccountRepository {
  _FakeProfileAccountRepository({this.available = true});

  final bool available;
  final List<String> checked = [];
  final List<String> saved = [];

  @override
  Future<String?> currentUsername() async => null;

  @override
  Future<bool> isUsernameAvailable(String username) async {
    checked.add(username);
    return available;
  }

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
