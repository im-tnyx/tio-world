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

  testWidgets('renders server-verified alternatives when username is taken',
      (tester) async {
    final repository = _FakeProfileAccountRepository(
      available: false,
      suggestions: const ['taken.user.1a2b', 'taken.user.3c4d'],
    );

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
    expect(
      find.text('This username is already taken. Try one of these instead:'),
      findsOneWidget,
    );
    expect(find.text('@taken.user.1a2b'), findsOneWidget);
    expect(find.text('@taken.user.3c4d'), findsOneWidget);
  });

  testWidgets('save race rechecks server and refreshes alternatives',
      (tester) async {
    final repository = _FakeProfileAccountRepository(failNextSave: true);

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
      'race.user',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('username-setup-continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(repository.checked, ['race.user', 'race.user']);
    expect(
      find.text('That username was just taken. Please choose another.'),
      findsOneWidget,
    );
    expect(find.text('@race.user.9f2a'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('username-setup-continue')),
    );
    expect(button.onPressed, isNull);
  });
}

class _FakeProfileAccountRepository implements ProfileAccountRepository {
  _FakeProfileAccountRepository({
    this.available = true,
    this.suggestions = const [],
    this.failNextSave = false,
  });

  bool available;
  List<String> suggestions;
  bool failNextSave;
  final List<String> checked = [];
  final List<String> saved = [];

  @override
  Future<String?> currentUsername() async => null;

  @override
  Future<UsernameAvailabilityCheck> checkUsernameAvailability(
    String username,
  ) async {
    final normalized = username.trim().toLowerCase();
    checked.add(normalized);
    return UsernameAvailabilityCheck(
      normalized: normalized,
      isAvailable: available,
      reason: available ? null : UsernameAvailabilityReason.taken,
      suggestions: suggestions,
    );
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    return (await checkUsernameAvailability(username)).isAvailable;
  }

  @override
  Future<void> updateUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    saved.add(normalized);
    if (failNextSave) {
      failNextSave = false;
      available = false;
      suggestions = const ['race.user.9f2a'];
      throw const UsernameUnavailableException(
        reason: UsernameAvailabilityReason.taken,
        suggestions: ['race.user.9f2a'],
      );
    }
  }

  @override
  Future<void> updateAccountSettings({
    required String username,
    required String mobile,
  }) async {}
}
