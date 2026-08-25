import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  Widget buildApp({
    required Future<void> Function() onDeleteAccountConfirmed,
    required Future<void> Function() onAccountDeleted,
  }) {
    return MaterialApp(
      builder: (context, child) =>
          TioTheme(child: child ?? const SizedBox.shrink()),
      home: AccountSettingsPage(
        username: 'tester',
        email: 'tester@example.com',
        onDeleteAccountConfirmed: onDeleteAccountConfirmed,
        onAccountDeleted: onAccountDeleted,
      ),
    );
  }

  Future<void> openAndConfirmDelete(WidgetTester tester) async {
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final hold = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('hold_to_delete_button'))),
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    await hold.up();
    await tester.pumpAndSettle();
  }

  testWidgets('post-delete finalizer runs only after confirmed success is closed',
      (tester) async {
    var serverDeleteCalls = 0;
    var finalizerCalls = 0;

    await tester.pumpWidget(
      buildApp(
        onDeleteAccountConfirmed: () async => serverDeleteCalls++,
        onAccountDeleted: () async => finalizerCalls++,
      ),
    );

    await openAndConfirmDelete(tester);

    expect(serverDeleteCalls, 1);
    expect(find.text('Account Deleted'), findsOneWidget);
    expect(finalizerCalls, 0);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(finalizerCalls, 1);
  });

  testWidgets('failed server deletion never invokes the post-delete finalizer',
      (tester) async {
    var finalizerCalls = 0;

    await tester.pumpWidget(
      buildApp(
        onDeleteAccountConfirmed: () async {
          throw StateError('server delete failed');
        },
        onAccountDeleted: () async => finalizerCalls++,
      ),
    );

    await openAndConfirmDelete(tester);

    expect(find.text('Account Deleted'), findsNothing);
    expect(
      find.text('Account deletion could not be confirmed. Please try again.'),
      findsOneWidget,
    );
    expect(finalizerCalls, 0);
  });
}
