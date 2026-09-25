import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

const _longTitle = 'A title long enough to run into the end of the top bar '
    'and be ellipsized well before it gets there';

Future<void> _pump(WidgetTester tester, TioAppBar appBar) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(child: child!),
      home: Scaffold(appBar: appBar),
    ),
  );
}

Finder get _backIcon =>
    find.descendant(of: find.byType(BackButton), matching: find.byType(Icon));

double _gapAfterBackIcon(WidgetTester tester, String title) =>
    tester.getTopLeft(find.text(title)).dx -
    tester.getTopRight(_backIcon).dx;

void main() {
  testWidgets('uses the canonical top-bar height', (tester) async {
    await _pump(tester, const TioAppBar(title: Text('Title')));

    expect(
      tester.getSize(find.byType(AppBar)).height,
      TioNavigationTokens.topBarHeight,
    );
    expect(
      const TioAppBar().preferredSize.height,
      TioNavigationTokens.topBarHeight,
    );
  });

  testWidgets('starts the title the canonical gap after the back icon',
      (tester) async {
    await _pump(
      tester,
      const TioAppBar(leading: BackButton(), title: Text('Title')),
    );

    expect(tester.getTopLeft(_backIcon).dx, TioSpacing.lg);
    expect(
      _gapAfterBackIcon(tester, 'Title'),
      TioNavigationTokens.topBarTitleGap,
    );
  });

  testWidgets('leaves the leading button its whole tap target',
      (tester) async {
    var backTaps = 0;
    var titleTaps = 0;
    await _pump(
      tester,
      TioAppBar(
        leading: BackButton(onPressed: () => backTaps++),
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => titleTaps++,
          child: const Text('Title'),
        ),
      ),
    );

    // The title is painted within the back button's tap target.
    final back = tester.getRect(find.byType(BackButton));
    expect(tester.getTopLeft(find.text('Title')).dx, lessThan(back.right));

    await tester.tapAt(Offset(back.right - 1, back.center.dy));
    expect(backTaps, 1);
    expect(titleTaps, 0);

    await tester.tap(find.text('Title'));
    expect(titleTaps, 1);
  });

  testWidgets('hits an interactive title where it is painted',
      (tester) async {
    Offset? tapDown;
    await _pump(
      tester,
      TioAppBar(
        leading: const BackButton(),
        title: GestureDetector(
          key: const ValueKey('title'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => tapDown = details.localPosition,
          child: const SizedBox(height: 40, width: double.infinity),
        ),
      ),
    );

    final title = tester.getRect(find.byKey(const ValueKey('title')));
    const inside = Offset(20, 10);
    await tester.tapAt(title.topLeft + inside);
    expect(tapDown, inside);

    // Nothing past the painted title reaches it.
    tapDown = null;
    await tester.tapAt(Offset(title.right + 4, title.center.dy));
    expect(tapDown, isNull);
  });

  testWidgets('mirrors the gap in right-to-left layouts', (tester) async {
    var backTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: TioTheme(child: child!),
        ),
        home: Scaffold(
          appBar: TioAppBar(
            leading: BackButton(onPressed: () => backTaps++),
            title: const Text('Title'),
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(_backIcon).dx - tester.getTopRight(find.text('Title')).dx,
      TioNavigationTokens.topBarTitleGap,
    );
    final back = tester.getRect(find.byType(BackButton));
    await tester.tapAt(Offset(back.left + 1, back.center.dy));
    expect(backTaps, 1);
  });

  testWidgets('keeps the gap for an implied back button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(child: child!),
        home: const Scaffold(),
      ),
    );
    unawaited(
      Navigator.of(tester.element(find.byType(Scaffold))).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(appBar: TioAppBar(title: Text('Pushed'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _gapAfterBackIcon(tester, 'Pushed'),
      TioNavigationTokens.topBarTitleGap,
    );
  });

  testWidgets('insets the title from the edge without a leading widget',
      (tester) async {
    await _pump(tester, const TioAppBar(title: Text('Title')));

    expect(find.byType(BackButton), findsNothing);
    expect(tester.getTopLeft(find.text('Title')).dx, TioSpacing.lg);
  });

  for (final withLeading in [true, false]) {
    final label = withLeading ? 'with' : 'without';

    testWidgets('keeps a long title clear of the trailing edge ($label '
        'leading)', (tester) async {
      await _pump(
        tester,
        TioAppBar(
          leading: withLeading ? const BackButton() : null,
          title: const Text(_longTitle),
        ),
      );

      final width = tester.getSize(find.byType(AppBar)).width;
      expect(
        tester.getTopRight(find.text(_longTitle)).dx,
        width - TioSpacing.lg,
      );
    });

    testWidgets('keeps a long title clear of the actions ($label leading)',
        (tester) async {
      await _pump(
        tester,
        TioAppBar(
          leading: withLeading ? const BackButton() : null,
          title: const Text(_longTitle),
          actions: [
            IconButton(
              key: const ValueKey('action'),
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
          ],
        ),
      );

      expect(
        tester.getTopRight(find.text(_longTitle)).dx,
        tester.getTopLeft(find.byKey(const ValueKey('action'))).dx -
            TioSpacing.lg,
      );
    });
  }

  testWidgets(
    'start-aligns the title on every platform',
    (tester) async {
      await _pump(
        tester,
        const TioAppBar(leading: BackButton(), title: Text('Title')),
      );

      expect(
        _gapAfterBackIcon(tester, 'Title'),
        TioNavigationTokens.topBarTitleGap,
      );
    },
    variant: TargetPlatformVariant.all(),
  );
}
