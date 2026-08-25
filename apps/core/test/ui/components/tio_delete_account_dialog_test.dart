import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  Widget buildApp({
    required Future<void> Function() onDeleteConfirmed,
    ValueChanged<bool>? onResult,
  }) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await showTioDeleteAccountOverlay(
                context: context,
                onDeleteConfirmed: onDeleteConfirmed,
              );
              onResult?.call(result);
            },
            child: const Text('Open Delete Flow'),
          ),
        ),
      ),
    );
  }

  Future<TestGesture> completeHold(WidgetTester tester) async {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('hold_to_delete_button'))),
    );
    // Let the tap recognizer deliver onTapDown before advancing the
    // five-second AnimationController. A single five-second jump can resolve
    // the gesture only at the end of that pump, starting the animation late.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    return gesture;
  }

  testWidgets('runs 5-second long press to confirmed delete completion',
      (tester) async {
    var deleteConfirmed = 0;
    bool? result;

    await tester.pumpWidget(
      buildApp(
        onDeleteConfirmed: () async => deleteConfirmed++,
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.text('Open Delete Flow'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text('Keep Account'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Long press/Hold this\nbutton'), findsOneWidget);
    expect(
      find.text('to delete all your progress permanently.'),
      findsOneWidget,
    );

    await completeHold(tester);
    await tester.pumpAndSettle();

    expect(deleteConfirmed, 1);
    expect(find.text('Account Deleted'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Account Deleted'), findsNothing);
    expect(result, isTrue);
  });

  testWidgets('backend failure stays recoverable in-place and can retry',
      (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      buildApp(
        onDeleteConfirmed: () async {
          attempts += 1;
          if (attempts == 1) {
            throw StateError('server deletion failed');
          }
        },
      ),
    );

    await tester.tap(find.text('Open Delete Flow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await completeHold(tester);
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(find.text('Account Deleted'), findsNothing);
    expect(
      find.text('Account deletion could not be confirmed. Please try again.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hold_to_delete_button')), findsOneWidget);

    await completeHold(tester);
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Account Deleted'), findsOneWidget);
  });

  testWidgets('in-flight delete blocks close, keep-account, back, and duplicates',
      (tester) async {
    final deletion = Completer<void>();
    var attempts = 0;

    await tester.pumpWidget(
      buildApp(
        onDeleteConfirmed: () {
          attempts += 1;
          return deletion.future;
        },
      ),
    );

    await tester.tap(find.text('Open Delete Flow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    await completeHold(tester);
    expect(attempts, 1);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('delete_account_close_button')),
      warnIfMissed: false,
    );
    await tester.tap(
      find.byKey(const ValueKey('delete_account_keep_button')),
      warnIfMissed: false,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Long press/Hold this\nbutton'), findsOneWidget);
    expect(attempts, 1);

    final duplicateGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('hold_to_delete_button'))),
    );
    await tester.pump(const Duration(seconds: 6));
    await duplicateGesture.up();
    await tester.pump();
    expect(attempts, 1);

    deletion.complete();
    await tester.pumpAndSettle();

    expect(find.text('Account Deleted'), findsOneWidget);
  });
}
