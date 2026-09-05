import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

/// Opens a [TioEditorSheet] and returns the tester's harness.
///
/// Every case goes through [showTioEditorSheet] rather than pumping the widget
/// directly, so the route-level flags the component depends on — no drag, no
/// Flutter drag handle, scroll-controlled — are exercised too.
Future<void> _open(
  WidgetTester tester, {
  required Widget content,
  Widget? actions,
  String? supportingText,
  Widget? titleTrailing,
  bool canDismiss = true,
  Size? surfaceSize,
  double textScale = 1,
}) async {
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTioEditorSheet<void>(
              context: context,
              builder: (_) => TioEditorSheet(
                title: 'Daily Step Goal',
                supportingText: supportingText,
                titleTrailing: titleTrailing,
                canDismiss: canDismiss,
                content: content,
                actions: actions,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  final sheet = find.byKey(const ValueKey('tio-editor-sheet'));
  final handle = find.byKey(const ValueKey('tio-editor-sheet-handle'));

  group('chrome', () {
    testWidgets('renders handle, title and supporting text', (tester) async {
      await _open(
        tester,
        content: const Text('Body'),
        supportingText: 'Recommended: 10,000 steps/day',
      );

      expect(sheet, findsOneWidget);
      expect(handle, findsOneWidget);
      expect(find.text('Daily Step Goal'), findsOneWidget);
      expect(find.text('Recommended: 10,000 steps/day'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('omits supporting text when none is given', (tester) async {
      await _open(tester, content: const Text('Body'));

      expect(find.text('Daily Step Goal'), findsOneWidget);
      // Only the title and the content live inside the sheet — no empty
      // supporting-text slot and no gap standing in for one.
      expect(
        find.descendant(of: sheet, matching: find.byType(Text)),
        findsNWidgets(2),
      );
    });

    testWidgets('renders a title trailing affordance on the title row',
        (tester) async {
      await _open(
        tester,
        content: const Text('Body'),
        titleTrailing: IconButton(
          key: const ValueKey('mode-switch'),
          onPressed: () {},
          icon: const Icon(Icons.tune),
        ),
      );

      expect(find.byKey(const ValueKey('mode-switch')), findsOneWidget);
      // Sharing a Row with the title, not stacked above or below it.
      expect(
        find.ancestor(
          of: find.byKey(const ValueKey('mode-switch')),
          matching: find.ancestor(
            of: find.text('Daily Step Goal'),
            matching: find.byType(Row),
          ),
        ),
        findsWidgets,
      );
    });
  });

  group('pinned action invariant', () {
    testWidgets('actions are not descendants of the scroll view',
        (tester) async {
      await _open(
        tester,
        content: const Text('Body'),
        actions: TioButton.primary(
          key: const ValueKey('save'),
          label: 'Save',
          onPressed: () {},
        ),
      );

      // The whole point of the component: a scroll view exists for the body,
      // and the commit action is outside it.
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byKey(const ValueKey('save')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.text('Body'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('long content scrolls while the action stays put',
        (tester) async {
      await _open(
        tester,
        surfaceSize: const Size(400, 600),
        content: Column(
          children: [
            for (var i = 0; i < 40; i++) SizedBox(height: 40, child: Text('r$i')),
          ],
        ),
        actions: TioButton.primary(
          key: const ValueKey('save'),
          label: 'Save',
          onPressed: () {},
        ),
      );

      final before = tester.getRect(find.byKey(const ValueKey('save')));
      expect(find.text('r0'), findsOneWidget);

      await tester.drag(find.text('r0'), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Content moved; the action did not.
      expect(tester.getRect(find.byKey(const ValueKey('save'))), before);
      expect(find.byKey(const ValueKey('save')), findsOneWidget);
    });

    testWidgets('action stays on screen when the keyboard is raised',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var insets = EdgeInsets.zero;
      late StateSetter setOuter;

      // The insets override must sit ABOVE the Navigator, or the sheet route
      // never sees it — which is exactly how a keyboard reaches a real sheet.
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(viewInsets: insets),
                child: TioTheme(child: child ?? const SizedBox.shrink()),
              );
            },
          ),
          home: Scaffold(
            body: Builder(
              builder: (inner) => TextButton(
                onPressed: () => showTioEditorSheet<void>(
                  context: inner,
                  builder: (_) => TioEditorSheet(
                    title: 'Daily Step Goal',
                    content: Column(
                      children: [
                        for (var i = 0; i < 20; i++)
                          SizedBox(height: 40, child: Text('r$i')),
                      ],
                    ),
                    actions: TioButton.primary(
                      key: const ValueKey('save'),
                      label: 'Save',
                      onPressed: () {},
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      setOuter(() => insets = const EdgeInsets.only(bottom: 300));
      await tester.pumpAndSettle();

      final save = find.byKey(const ValueKey('save'));
      expect(save, findsOneWidget);

      // Reachable means inside the visible area above the keyboard, not merely
      // present in the tree.
      final rect = tester.getRect(save);
      expect(rect.bottom, lessThanOrEqualTo(600 - 300));
      expect(rect.top, greaterThanOrEqualTo(0));
    });
  });

  group('action variants', () {
    testWidgets('no actions renders no action region', (tester) async {
      await _open(tester, content: const Text('Body'));

      expect(sheet, findsOneWidget);
      expect(find.byType(TioButton), findsNothing);
    });

    testWidgets('a single action renders', (tester) async {
      await _open(
        tester,
        content: const Text('Body'),
        actions: TioButton.primary(label: 'Save', onPressed: () {}),
      );

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('multiple actions render side by side', (tester) async {
      await _open(
        tester,
        content: const Text('Body'),
        actions: Row(
          children: [
            Expanded(
              child: TioButton.secondary(label: 'Reset', onPressed: () {}),
            ),
            const SizedBox(width: TioSpacing.md),
            Expanded(
              child: TioButton.primary(label: 'Save', onPressed: () {}),
            ),
          ],
        ),
      );

      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(
        tester.getRect(find.text('Reset')).left,
        lessThan(tester.getRect(find.text('Save')).left),
      );
    });

    testWidgets('stacked actions render vertically', (tester) async {
      await _open(
        tester,
        content: const Text('Body'),
        actions: Column(
          children: [
            TioButton.primary(label: 'Save', onPressed: () {}),
            const SizedBox(height: TioSpacing.sm),
            TioButton.secondary(label: 'Remove', onPressed: () {}),
          ],
        ),
      );

      expect(
        tester.getRect(find.text('Save')).top,
        lessThan(tester.getRect(find.text('Remove')).top),
      );
    });
  });

  group('dismissal', () {
    testWidgets('dragging the handle down dismisses when allowed',
        (tester) async {
      await _open(tester, content: const Text('Body'));

      expect(sheet, findsOneWidget);
      await tester.drag(handle, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(sheet, findsNothing);
    });

    testWidgets('canDismiss false holds the sheet open', (tester) async {
      await _open(tester, content: const Text('Body'), canDismiss: false);

      await tester.drag(handle, const Offset(0, 120));
      await tester.pumpAndSettle();

      expect(sheet, findsOneWidget);
    });

    testWidgets('an upward drag never dismisses', (tester) async {
      await _open(tester, content: const Text('Body'));

      await tester.drag(handle, const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(sheet, findsOneWidget);
    });
  });

  group('constrained height and large text', () {
    testWidgets('short sheet does not stretch to fill the screen',
        (tester) async {
      await _open(
        tester,
        surfaceSize: const Size(400, 800),
        content: const SizedBox(height: 40, child: Text('Body')),
        actions: TioButton.primary(label: 'Save', onPressed: () {}),
      );

      // mainAxisSize.min: the sheet hugs its content rather than filling.
      expect(tester.getSize(sheet).height, lessThan(400));
    });

    testWidgets('large text scale keeps the action reachable', (tester) async {
      await _open(
        tester,
        textScale: 2,
        surfaceSize: const Size(400, 600),
        content: Column(
          children: [
            for (var i = 0; i < 12; i++) const Text('A long editor line'),
          ],
        ),
        actions: TioButton.primary(
          key: const ValueKey('save'),
          label: 'Save',
          onPressed: () {},
        ),
      );

      final save = find.byKey(const ValueKey('save'));
      expect(save, findsOneWidget);
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(600));
      expect(tester.takeException(), isNull);
    });
  });

  group('navigator choice', () {
    /// Chrome outside a nested navigator, with the editor opened from inside
    /// it — the shape a `StatefulShellRoute` branch produces.
    Future<int Function()> pumpNested(
      WidgetTester tester, {
      required bool useRootNavigator,
    }) async {
      var chromeTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              TioTheme(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  key: const ValueKey('chrome-action'),
                  onPressed: () => chromeTaps++,
                  icon: const Icon(Icons.today),
                ),
              ],
            ),
            body: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (branchContext) => TextButton(
                  key: const ValueKey('open'),
                  onPressed: () => showTioEditorSheet<void>(
                    context: branchContext,
                    useRootNavigator: useRootNavigator,
                    builder: (_) => const TioEditorSheet(
                      title: 'Editor',
                      content: Text('Body'),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      expect(find.byType(TioEditorSheet), findsOneWidget);

      return () => chromeTaps;
    }

    testWidgets('the default leaves chrome outside the branch reachable',
        (tester) async {
      final chromeTaps = await pumpNested(tester, useRootNavigator: false);

      await tester.tap(find.byKey(const ValueKey('chrome-action')));
      await tester.pumpAndSettle();

      expect(chromeTaps(), 1, reason: 'the barrier covers only the branch');
    });

    testWidgets('useRootNavigator puts the barrier over the chrome too',
        (tester) async {
      final chromeTaps = await pumpNested(tester, useRootNavigator: true);

      await tester.tap(
        find.byKey(const ValueKey('chrome-action')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(chromeTaps(), 0, reason: 'the barrier absorbs the chrome tap');
      // The tap did not simply miss: it landed on the barrier, which is what
      // dismissed the sheet. That only happens if the barrier is over the app
      // bar, which is only true on the root navigator.
      expect(find.byType(TioEditorSheet), findsNothing);
    });
  });
}
