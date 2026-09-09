import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

/// Opens the presenter and records what it resolved to.
///
/// `sawResult` distinguishes "returned null" from "has not returned yet",
/// which matters for the dismissal cases: a test that only checked the value
/// would pass while the sheet was still open.
Future<_Harness> _open(
  WidgetTester tester, {
  TioThemeMode mode = TioThemeMode.light,
}) async {
  final harness = _Harness();

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              harness.result =
                  await showTioRemoveImageConfirmationBottomSheet(context);
              harness.sawResult = true;
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  return harness;
}

class _Harness {
  bool? result;
  bool sawResult = false;
}

Finder _action(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(TioButton),
    );

TioButton _button(WidgetTester tester, String label) =>
    tester.widget<TioButton>(_action(label));

void main() {
  group('shell', () {
    testWidgets('renders the copy and both actions', (tester) async {
      await _open(tester);

      expect(find.text('Remove Image'), findsOneWidget);
      expect(
        find.text('Are you sure you want to remove this image?'),
        findsOneWidget,
      );
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps its raised surface and safe area', (tester) async {
      await _open(tester);

      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(SafeArea),
        ),
        findsWidgets,
      );
    });
  });

  group('actions are the shared button family', () {
    testWidgets('Remove is a destructive TioButton, full width',
        (tester) async {
      await _open(tester);
      final remove = _button(tester, 'Remove');

      expect(remove.variant, TioButtonVariant.destructive);
      expect(remove.expand, isTrue);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('Cancel is a secondary TioButton, full width', (tester) async {
      await _open(tester);
      final cancel = _button(tester, 'Cancel');

      // Cancel stays non-destructive; there is deliberately no cancel variant.
      expect(cancel.variant, TioButtonVariant.secondary);
      expect(cancel.expand, isTrue);
    });

    testWidgets('each action renders through its variant chassis',
        (tester) async {
      await _open(tester);

      // The old actions were hand-built from InkWell + Container + Row.
      // Destructive rides primary's filled chassis; secondary stays outlined.
      expect(
        find.descendant(
          of: _action('Remove'),
          matching: find.byType(FilledButton),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _action('Remove'),
          matching: find.byType(OutlinedButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: _action('Cancel'),
          matching: find.byType(OutlinedButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('destructive Remove differs from Cancel in every theme mode',
        (tester) async {
      for (final mode in TioThemeMode.values) {
        await _open(tester, mode: mode);

        expect(_button(tester, 'Remove').variant,
            TioButtonVariant.destructive);
        expect(_button(tester, 'Cancel').variant, TioButtonVariant.secondary);

        // Close before the next mode. pumpWidget keeps the Navigator, so an
        // open sheet would cover the trigger on the following iteration.
        await tester.tapAt(const Offset(400, 40));
        await tester.pumpAndSettle();
      }
    });
  });

  group('result semantics', () {
    testWidgets('Remove resolves true', (tester) async {
      final harness = await _open(tester);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(harness.sawResult, isTrue);
      expect(harness.result, isTrue);
    });

    testWidgets('Cancel resolves false', (tester) async {
      final harness = await _open(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(harness.sawResult, isTrue);
      expect(harness.result, isFalse);
    });

    testWidgets('the top close affordance resolves false', (tester) async {
      final harness = await _open(tester);

      // Two close glyphs exist: the sheet's own header affordance and
      // Cancel's trailing icon. Position is what tells them apart, and
      // asserting it means a reordering fails loudly instead of silently
      // testing the wrong one.
      expect(find.byIcon(Icons.close_rounded), findsNWidgets(2));
      final close = find.byIcon(Icons.close_rounded).first;
      expect(
        tester.getCenter(close).dy,
        lessThan(tester.getTopLeft(_action('Remove')).dy),
      );

      await tester.tap(close);
      await tester.pumpAndSettle();

      expect(harness.sawResult, isTrue);
      expect(harness.result, isFalse);
    });

    testWidgets('dismissing by tapping the barrier resolves null',
        (tester) async {
      final harness = await _open(tester);

      // Above the sheet, on the modal barrier.
      await tester.tapAt(const Offset(400, 40));
      await tester.pumpAndSettle();

      expect(harness.sawResult, isTrue);
      expect(harness.result, isNull);
    });

    testWidgets('system back resolves null', (tester) async {
      final harness = await _open(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(harness.sawResult, isTrue);
      expect(harness.result, isNull);
    });
  });
}
