import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_profile/profile.dart';

void main() {
  Widget host({
    required GlobalKey<UsernameStepState> stepKey,
    required _FakeProfileAccountRepository repository,
    String initialUsername = '',
  }) {
    return MaterialApp(
      theme: ThemeData(extensions: const [TioColors.light]),
      home: Scaffold(
        body: UsernameStep(
          key: stepKey,
          repository: repository,
          initialUsername: initialUsername,
          enabled: true,
          onCanContinueChanged: (_) {},
        ),
      ),
    );
  }

  testWidgets('missing username starts blank with only the generic hint',
      (tester) async {
    final key = GlobalKey<UsernameStepState>();
    final repository = _FakeProfileAccountRepository();

    await tester.pumpWidget(host(stepKey: key, repository: repository));

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('tio-username-input')),
    );
    expect(field.controller!.text, isEmpty);
    expect(field.decoration?.hintText, 'e.g. your.name');
    expect(repository.checked, isEmpty);
  });

  testWidgets('persisted canonical username hydrates without a new check',
      (tester) async {
    final key = GlobalKey<UsernameStepState>();
    final repository = _FakeProfileAccountRepository();

    await tester.pumpWidget(
      host(
        stepKey: key,
        repository: repository,
        initialUsername: 'existing.user',
      ),
    );

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('tio-username-input')),
    );
    expect(field.controller!.text, 'existing.user');
    expect(key.currentState!.username, 'existing.user');
    expect(repository.checked, isEmpty);
  });

  testWidgets('renders server-verified alternatives when username is taken',
      (tester) async {
    final key = GlobalKey<UsernameStepState>();
    final repository = _FakeProfileAccountRepository(
      available: false,
      suggestions: const [
        'taken.user27',
        'taken.user_314',
        'taken.user.82',
      ],
    );

    await tester.pumpWidget(host(stepKey: key, repository: repository));

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'taken.user',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(repository.checked, ['taken.user']);
    expect(
      find.text('This username is already taken. Try one of these instead:'),
      findsOneWidget,
    );
    expect(find.text('@taken.user27'), findsOneWidget);
    expect(find.text('@taken.user_314'), findsOneWidget);
    expect(find.text('@taken.user.82'), findsOneWidget);
  });

  testWidgets('tapping a suggestion rechecks it before showing available',
      (tester) async {
    final key = GlobalKey<UsernameStepState>();
    final repository = _FakeProfileAccountRepository(
      available: false,
      suggestions: const ['typed.user27'],
    );

    await tester.pumpWidget(host(stepKey: key, repository: repository));

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'typed.user',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    repository.available = true;
    repository.suggestions = const [];
    await tester.tap(find.text('@typed.user27'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(repository.checked, ['typed.user', 'typed.user27']);
    expect(find.text('@typed.user27 is available!'), findsOneWidget);
  });

  testWidgets('save race refreshes server alternatives and stays retryable',
      (tester) async {
    final key = GlobalKey<UsernameStepState>();
    final repository = _FakeProfileAccountRepository(failNextSave: true);

    await tester.pumpWidget(host(stepKey: key, repository: repository));

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'race.user',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(await key.currentState!.submit(), isFalse);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(repository.checked, ['race.user', 'race.user']);
    expect(
      find.text('That username was just taken. Please choose another.'),
      findsOneWidget,
    );
    expect(find.text('@race.user_482'), findsOneWidget);
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
    if (failNextSave) {
      failNextSave = false;
      available = false;
      suggestions = const ['race.user_482'];
      throw const UsernameUnavailableException(
        reason: UsernameAvailabilityReason.taken,
        suggestions: ['race.user_482'],
      );
    }
  }

  @override
  Future<void> updateAccountSettings({
    required String username,
    required String mobile,
  }) async {}
}
