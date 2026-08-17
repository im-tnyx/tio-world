import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('TioDeleteAccountOverlay runs 5-second long press to delete flow',
      (tester) async {
    var deleteConfirmed = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await showTioDeleteAccountOverlay(
                  context: context,
                  onDeleteConfirmed: () async => deleteConfirmed++,
                );
              },
              child: const Text('Open Delete Flow'),
            ),
          ),
        ),
      ),
    );

    // Open overlay
    await tester.tap(find.text('Open Delete Flow'));
    await tester.pumpAndSettle();

    // Step 1: Confirm Overlay
    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text('Keep Account'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    // Tap Delete to go to Hold To Delete Step
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Step 2: Hold To Delete Overlay
    expect(find.text('Long press/Hold this\nbutton'), findsOneWidget);
    expect(find.text('to delete all your progress permanently.'), findsOneWidget);

    // Find the hold GestureDetector and hold for 5.5 seconds
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('hold_to_delete_button'))),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(deleteConfirmed, 1);
    expect(find.text('Account Deleted'), findsOneWidget);

    // Tap Close to dismiss
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Account Deleted'), findsNothing);
  });
}
