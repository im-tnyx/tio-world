import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        extensions: const [TioColors.light],
      ),
      home: Scaffold(body: child),
    );
  }

  testWidgets('uses a neutral name-style username hint by default', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildTestApp(
        TioUsernameInputField(
          controller: controller,
          onCheckAvailability: (_) async =>
              const UsernameAvailabilityResult(isAvailable: true),
        ),
      ),
    );

    expect(find.text('e.g. your.name'), findsOneWidget);
    expect(find.text('e.g. santosh_99'), findsNothing);
  });

  testWidgets('normalizes input to lowercase and enforces 30 character maximum',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      buildTestApp(
        TioUsernameInputField(
          controller: controller,
          onCheckAvailability: (_) async =>
              const UsernameAvailabilityResult(isAvailable: true),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
    );
    await tester.pump();

    expect(controller.text, 'abcdefghijklmnopqrstuvwxyz1234');
    expect(controller.text.length, tioUsernameMaxLength);
  });

  testWidgets('ignores a stale availability result after input changes',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final firstResult = Completer<UsernameAvailabilityResult>();
    final secondResult = Completer<UsernameAvailabilityResult>();

    await tester.pumpWidget(
      buildTestApp(
        TioUsernameInputField(
          controller: controller,
          onCheckAvailability: (username) {
            if (username == 'firstuser') return firstResult.future;
            if (username == 'seconduser') return secondResult.future;
            throw StateError('Unexpected username: $username');
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'FirstUser',
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'SecondUser',
    );
    await tester.pump(const Duration(milliseconds: 400));

    secondResult.complete(
      const UsernameAvailabilityResult(isAvailable: true),
    );
    await tester.pump();
    expect(find.text('@seconduser is available!'), findsOneWidget);

    firstResult.complete(
      const UsernameAvailabilityResult(
        isAvailable: false,
        message: 'Old result must not win.',
      ),
    );
    await tester.pump();

    expect(find.text('@seconduser is available!'), findsOneWidget);
    expect(find.text('Old result must not win.'), findsNothing);
  });

  testWidgets('rechecks a suggestion before marking it available',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final checkedHandles = <String>[];
    final changedHandles = <String>[];

    await tester.pumpWidget(
      buildTestApp(
        TioUsernameInputField(
          controller: controller,
          onChanged: changedHandles.add,
          onCheckAvailability: (username) async {
            checkedHandles.add(username);
            if (username == 'candidate') {
              return const UsernameAvailabilityResult(
                isAvailable: false,
                suggestions: ['candidate_2'],
              );
            }
            return const UsernameAvailabilityResult(isAvailable: true);
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'candidate',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('@candidate_2'), findsOneWidget);
    expect(checkedHandles, ['candidate']);

    await tester.tap(find.text('@candidate_2'));
    await tester.pump();

    expect(controller.text, 'candidate_2');
    expect(changedHandles, ['candidate', 'candidate_2']);
    expect(find.text('@candidate_2 is available!'), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(checkedHandles, ['candidate', 'candidate_2']);
    expect(find.text('@candidate_2 is available!'), findsOneWidget);
  });

  testWidgets('refresh token rechecks without reporting a user text change',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final checkedHandles = <String>[];
    final changedHandles = <String>[];
    var refreshToken = 0;
    late StateSetter setHarnessState;

    await tester.pumpWidget(
      buildTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            setHarnessState = setState;
            return TioUsernameInputField(
              controller: controller,
              availabilityRefreshToken: refreshToken,
              onChanged: changedHandles.add,
              onCheckAvailability: (username) async {
                checkedHandles.add(username);
                return const UsernameAvailabilityResult(isAvailable: true);
              },
            );
          },
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'race.user',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(checkedHandles, ['race.user']);
    expect(changedHandles, ['race.user']);

    setHarnessState(() => refreshToken++);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(checkedHandles, ['race.user', 'race.user']);
    expect(changedHandles, ['race.user']);
  });
}
