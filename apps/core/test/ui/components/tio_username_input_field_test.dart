import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // #24-D: reverting to the current persisted username while an older
  // request is in flight. Distinct from the existing "stale result" test --
  // this exercises the interaction between the generation guard and the
  // already-matches-current-username fast path, not just two different
  // in-flight handles.
  testWidgets(
      'reverting to the current username while an older request is in '
      'flight cannot be overwritten by that request', (tester) async {
    final controller = TextEditingController(text: 'alpha');
    addTearDown(controller.dispose);
    final betaResult = Completer<UsernameAvailabilityResult>();

    await tester.pumpWidget(
      buildTestApp(
        TioUsernameInputField(
          controller: controller,
          currentUsername: 'alpha',
          onCheckAvailability: (username) {
            if (username == 'beta') return betaResult.future;
            throw StateError('Unexpected check for $username');
          },
        ),
      ),
    );

    // user types: alpha -> beta (request beta starts, debounced)
    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'beta',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // user changes back to: alpha (the current persisted username) before
    // beta resolves. The current-username fast path applies immediately,
    // with no network round trip.
    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'alpha',
    );
    await tester.pump();

    final fieldWhileReverted = tester.widget<TioUsernameInputField>(
      find.byType(TioUsernameInputField),
    );
    expect(controller.text, 'alpha');
    // Nothing renders an unavailable/checking state for the reverted value.
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(fieldWhileReverted.currentUsername, 'alpha');

    // beta resolves late. It must not resurrect a stale status for a value
    // the user has already moved away from.
    betaResult.complete(
      const UsernameAvailabilityResult(
        isAvailable: false,
        message: 'beta should never be shown',
      ),
    );
    await tester.pump();

    expect(controller.text, 'alpha');
    expect(find.text('beta should never be shown'), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  group('capsule appearance (#24-D, evidenced by Account Settings)', () {
    testWidgets('renders the fixed 56dp filled row with no floating label',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestApp(
          TioUsernameInputField(
            controller: controller,
            appearance: TioUsernameFieldAppearance.capsule,
            hintText: 'username',
            onCheckAvailability: (_) async =>
                const UsernameAvailabilityResult(isAvailable: true),
          ),
        ),
      );

      // No Material floating label -- the caller owns any external label.
      expect(find.text('Username'), findsNothing);
      expect(find.text('username'), findsOneWidget); // the hint

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('tio-username-input')),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(
        container.constraints,
        const BoxConstraints.tightFor(height: 56),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, TioColors.light.surfaceRaised);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(TioRadius.lg),
      );

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('tio-username-input')),
      );
      expect(field.decoration!.filled, isFalse);
      expect(field.decoration!.border, InputBorder.none);
      expect(field.cursorColor, TioColors.light.primary);

      expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);
      expect(find.byIcon(Icons.alternate_email), findsNothing);
    });

    testWidgets(
        'border tints available (primary) and unavailable (danger), '
        'unlike the outlined appearance', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestApp(
          TioUsernameInputField(
            controller: controller,
            appearance: TioUsernameFieldAppearance.capsule,
            onCheckAvailability: (_) async =>
                const UsernameAvailabilityResult(isAvailable: true),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'available.user',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('tio-username-input')),
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (container.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, TioColors.light.primary.withAlpha(80));
      expect(border.top.width, 1.5);
    });

    testWidgets('applies extraInputFormatters after the built-in ones',
        (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestApp(
          TioUsernameInputField(
            controller: controller,
            appearance: TioUsernameFieldAppearance.capsule,
            extraInputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_.]')),
            ],
            onCheckAvailability: (_) async =>
                const UsernameAvailabilityResult(isAvailable: true),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'santosh#123',
      );
      await tester.pump();

      // '#' is rejected at keystroke time, not shown then rejected later.
      expect(controller.text, 'santosh123');
    });

    testWidgets(
        'suggestions render the caption and the evidenced alpha50 '
        'border, unlike outlined', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestApp(
          TioUsernameInputField(
            controller: controller,
            appearance: TioUsernameFieldAppearance.capsule,
            onCheckAvailability: (username) async =>
                const UsernameAvailabilityResult(
              isAvailable: false,
              suggestions: ['taken_alt'],
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tio-username-input')),
        'taken',
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(find.text('Suggestions:'), findsOneWidget);
      expect(find.text('@taken_alt'), findsOneWidget);

      final pill = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('@taken_alt'),
              matching: find.byType(Container),
            )
            .first,
      );
      final border = (pill.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, TioColors.light.primary.withAlpha(50));
    });

    testWidgets('outlined appearance renders none of the capsule-only chrome',
        (tester) async {
      // Regression: adding capsule must not leak into the existing default.
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

      expect(find.text('Username'), findsOneWidget); // floating label present
      expect(find.byIcon(Icons.alternate_email_rounded), findsNothing);
      expect(find.byIcon(Icons.alternate_email), findsOneWidget);

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('tio-username-input')),
      );
      expect(field.decoration!.filled, isFalse);
      expect(field.decoration!.border, isNot(InputBorder.none));
    });
  });
}
