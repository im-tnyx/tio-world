import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

/// A fixed August so every case reasons about the same calendar. With the
/// default locale the week starts on Sunday, so the week holding [_selected]
/// runs Aug 16..Aug 22.
final _augustFirst = DateTime(2026, 8, 1);
final _augustLast = DateTime(2026, 8, 31);
final _today = DateTime(2026, 8, 20);
final _selected = DateTime(2026, 8, 18);

/// Pumps the calendar with the caller owning `selectedDate`, which is the whole
/// point of the contract: the widget reports a tap and this harness decides.
/// A test that let the widget keep its own selection would pass while the real
/// controlled-state design was broken.
Future<_CalendarHarness> _pump(
  WidgetTester tester, {
  DateTime? initialSelected,
  DateTime? minDate,
  DateTime? maxDate,
  DateTime? localToday,
  TioDateCalendarController? controller,
  int? resolvedFirstDayOfWeek,
  TioDateCalendarDisplayMode displayMode = TioDateCalendarDisplayMode.compact,
  TioDateDecorationBuilder? decorationBuilder,
  TioDateCalendarVisibleRangeChanged? onVisibleDateRangeChanged,
  bool insideScrollablePage = false,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final harness = _CalendarHarness(initialSelected ?? _selected);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            final calendar = TioDateCalendar(
              selectedDate: harness.selectedDate,
              localToday: localToday ?? _today,
              minDate: minDate ?? _augustFirst,
              maxDate: maxDate ?? _augustLast,
              controller: controller,
              resolvedFirstDayOfWeek: resolvedFirstDayOfWeek,
              displayMode: displayMode,
              decorationBuilder: decorationBuilder,
              onVisibleDateRangeChanged: onVisibleDateRangeChanged,
              onDateSelected: (date) {
                harness.selectedDates.add(date);
                setState(() => harness.selectedDate = date);
              },
              onDisplayModeChanged: harness.displayModes.add,
            );

            if (!insideScrollablePage) return calendar;

            return ListView(
              children: [
                calendar,
                const SizedBox(key: ValueKey('page-content'), height: 1200),
              ],
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return harness;
}

class _CalendarHarness {
  _CalendarHarness(this.selectedDate);

  DateTime selectedDate;
  final List<DateTime> selectedDates = <DateTime>[];
  final List<TioDateCalendarDisplayMode> displayModes =
      <TioDateCalendarDisplayMode>[];
}

Finder _cell(DateTime date) => find.byKey(ValueKey(date));

Finder _pager() => find.byKey(const ValueKey('tio-date-calendar-week-pager'));

Finder _monthPager() =>
    find.byKey(const ValueKey('tio-date-calendar-month-pager'));

Finder _handle() => find.byKey(const ValueKey('tio-date-calendar-handle'));
Finder _grabber() => find.byKey(const ValueKey('tio-date-calendar-grabber'));

Finder _weekdayHeader() =>
    find.byKey(const ValueKey('tio-date-calendar-weekday-header'));

/// The circle painter for one date, which is where every visual layer other
/// than the numeral and the markers is recorded.
RenderObject _circle(WidgetTester tester, DateTime date) => tester.renderObject(
      find.descendant(of: _cell(date), matching: find.byType(CustomPaint)),
    );

/// `PageView` keeps its page count on the delegate rather than exposing it.
int _monthPageCount(WidgetTester tester) =>
    (tester.widget<PageView>(_monthPager()).childrenDelegate
            as SliverChildBuilderDelegate)
        .childCount!;

bool _isMonthMode(WidgetTester tester) => _monthPager().evaluate().isNotEmpty;

TextStyle _numeralStyle(WidgetTester tester, DateTime date) {
  final text = tester.widget<Text>(
    find.descendant(of: _cell(date), matching: find.text('${date.day}')),
  );
  return text.style!;
}

TextStyle _weekdayStyle(WidgetTester tester, String label) {
  final text = tester.widget<Text>(
    find.descendant(of: _weekdayHeader(), matching: find.text(label)),
  );
  return text.style!;
}

void main() {
  group('compact rendering', () {
    testWidgets('shows one whole week under the shared weekday header',
        (tester) async {
      await _pump(tester);

      expect(_pager(), findsOne);
      expect(_weekdayHeader(), findsOne);
      expect(_isMonthMode(tester), isFalse);

      // The week holding the selection, Sunday through Saturday.
      for (var day = 16; day <= 22; day++) {
        expect(_cell(DateTime(2026, 8, day)), findsOne);
      }
      expect(_cell(DateTime(2026, 8, 23)), findsNothing);
    });

    testWidgets('a horizontal drag pages by week and never changes mode',
        (tester) async {
      final visibleRanges = <List<DateTime>>[];
      final harness = await _pump(
        tester,
        onVisibleDateRangeChanged: (firstDate, lastDate) {
          visibleRanges.add(<DateTime>[firstDate, lastDate]);
        },
      );

      expect(
        visibleRanges.last,
        <DateTime>[DateTime(2026, 8, 16), DateTime(2026, 8, 22)],
      );

      await tester.fling(_pager(), const Offset(-400, 0), 1200);
      await tester.pumpAndSettle();

      // The next week, not an arbitrary offset part-way between two weeks.
      expect(_cell(DateTime(2026, 8, 23)), findsOne);
      expect(_cell(DateTime(2026, 8, 29)), findsOne);
      expect(_cell(_selected), findsNothing);

      expect(_isMonthMode(tester), isFalse);
      expect(harness.displayModes, isEmpty);
      expect(
        visibleRanges.last,
        <DateTime>[DateTime(2026, 8, 23), DateTime(2026, 8, 29)],
      );
    });

    testWidgets('tapping an in-range date reports it to the caller',
        (tester) async {
      final harness = await _pump(tester);
      final target = DateTime(2026, 8, 19);

      await tester.tap(_cell(target));
      await tester.pumpAndSettle();

      expect(harness.selectedDates, <DateTime>[target]);
      expect(harness.selectedDate, target);
    });
  });

  group('one controlled selected date', () {
    testWidgets('a compact selection survives expanding', (tester) async {
      final harness = await _pump(tester);
      final target = DateTime(2026, 8, 17);

      await tester.tap(_cell(target));
      await tester.pumpAndSettle();
      await tester.tap(_handle());
      await tester.pumpAndSettle();

      expect(_isMonthMode(tester), isTrue);
      expect(harness.selectedDate, target);
      expect(tester.getSemantics(_cell(target)), isSemantics(isSelected: true));
    });

    testWidgets('the first date row stays fixed while expanding',
        (tester) async {
      final firstRowDate = DateTime(2026, 8, 1);
      await _pump(tester, initialSelected: firstRowDate);
      final compactTop = tester.getTopLeft(_cell(firstRowDate)).dy;

      await tester.tap(_handle());
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(_cell(firstRowDate)).dy, compactTop);
    });

    testWidgets('a month selection is on screen in the strip after collapsing',
        (tester) async {
      final harness = await _pump(tester);
      final target = DateTime(2026, 8, 2);

      await tester.tap(_handle());
      await tester.pumpAndSettle();
      await tester.tap(_cell(target));
      await tester.pumpAndSettle();
      await tester.tap(_handle());
      await tester.pumpAndSettle();

      expect(_isMonthMode(tester), isFalse);
      expect(harness.selectedDate, target);
      expect(_cell(target), findsOne);

      // Paged into view, not merely built off-screen.
      final rect = tester.getRect(_cell(target));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(tester.view.physicalSize.width));
    });

    testWidgets('expansion opens the month containing the selected date',
        (tester) async {
      await _pump(
        tester,
        initialSelected: DateTime(2026, 7, 15),
        minDate: DateTime(2026, 7, 1),
      );

      await tester.tap(_handle());
      await tester.pumpAndSettle();

      expect(_monthPager(), findsOne);
      expect(_cell(DateTime(2026, 7, 15)), findsOne);
      expect(find.text('July 2026'), findsNothing);
      expect(find.byIcon(Icons.chevron_left), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('expanded rendering pages horizontally month by month',
        (tester) async {
      final visibleRanges = <List<DateTime>>[];
      await _pump(
        tester,
        initialSelected: DateTime(2026, 7, 15),
        minDate: DateTime(2026, 7, 1),
        onVisibleDateRangeChanged: (firstDate, lastDate) {
          visibleRanges.add(<DateTime>[firstDate, lastDate]);
        },
      );

      await tester.tap(_handle());
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(_monthPager());
      expect(pageView.controller!.page, 0);
      expect(
        visibleRanges.last,
        <DateTime>[DateTime(2026, 7, 1), DateTime(2026, 7, 31)],
      );

      await tester.fling(_monthPager(), const Offset(-400, 0), 1200);
      await tester.pumpAndSettle();
      expect(pageView.controller!.page, 1);
      expect(_cell(DateTime(2026, 8, 15)), findsOne);
      expect(
        visibleRanges.last,
        <DateTime>[DateTime(2026, 8, 1), DateTime(2026, 8, 31)],
      );

      await tester.fling(_monthPager(), const Offset(400, 0), 1200);
      await tester.pumpAndSettle();
      expect(pageView.controller!.page, 0);
      expect(_cell(DateTime(2026, 7, 15)), findsOne);
    });

    testWidgets('jumpToDate moves the week pager and the month grid',
        (tester) async {
      final controller = TioDateCalendarController();
      addTearDown(controller.dispose);

      await _pump(
        tester,
        controller: controller,
        minDate: DateTime(2026, 7, 1),
        displayMode: TioDateCalendarDisplayMode.month,
      );
      final pageView = tester.widget<PageView>(_monthPager());
      expect(pageView.controller!.page, 1);

      controller.jumpToDate(DateTime(2026, 7, 10));
      await tester.pumpAndSettle();

      expect(pageView.controller!.page, 0);
      expect(_cell(DateTime(2026, 7, 10)), findsOne);
    });
  });

  group('caller-controlled range', () {
    testWidgets('a date past maxDate stays visible but is inert',
        (tester) async {
      final harness = await _pump(tester, maxDate: _today);
      final future = DateTime(2026, 8, 21);

      // Still drawn, because a week with holes punched in it reads as broken…
      expect(_cell(future), findsOne);

      // …but it cannot be picked, in either rendering.
      await tester.tap(_cell(future));
      await tester.pumpAndSettle();
      expect(harness.selectedDates, isEmpty);

      await tester.tap(_handle());
      await tester.pumpAndSettle();
      await tester.tap(_cell(future));
      await tester.pumpAndSettle();
      expect(harness.selectedDates, isEmpty);
      expect(harness.selectedDate, _selected);
    });

    testWidgets('an in-range date next to it is still selectable',
        (tester) async {
      final harness = await _pump(tester, maxDate: _today);

      await tester.tap(_cell(_today));
      await tester.pumpAndSettle();

      expect(harness.selectedDate, _today);
    });
  });

  group('visual grammar', () {
    testWidgets('Sunday uses semantic danger styling like the reference',
        (tester) async {
      final sunday = DateTime(2026, 8, 16);
      await _pump(tester);

      expect(
        _weekdayStyle(tester, 'SUN').color,
        TioColors.light.danger.withAlpha(TioAlpha.alpha140),
      );
      expect(_weekdayStyle(tester, 'MON').color, TioColors.light.textMuted);
      expect(
        _numeralStyle(tester, sunday).color,
        TioColors.light.danger.withAlpha(TioAlpha.alpha179),
      );

      await _pump(tester, initialSelected: sunday);

      expect(_numeralStyle(tester, sunday).color, TioColors.light.danger);

      await _pump(
        tester,
        decorationBuilder: (date) => date == sunday
            ? const TioDateDecoration(fill: TioDateFill.solid)
            : null,
      );

      expect(_numeralStyle(tester, sunday).color, TioColors.light.onPrimary);
    });

    testWidgets('Today stays strong while another date is selected',
        (tester) async {
      await _pump(tester);

      expect(_numeralStyle(tester, _today).fontWeight, TioFontWeight.w700);
      expect(_numeralStyle(tester, _selected).fontWeight, TioFontWeight.w400);
      // Selection is the outer ring, not the Today treatment.
      expect(_circle(tester, _selected), paints..circle());
    });

    testWidgets('missing progress and a real zero render differently',
        (tester) async {
      final undecorated = DateTime(2026, 8, 17);
      final zero = DateTime(2026, 8, 19);

      await _pump(
        tester,
        decorationBuilder: (date) =>
            date == zero ? const TioDateDecoration(progress: 0) : null,
      );

      // A real zero still draws its track, so the user can tell "none yet"
      // from "nothing known".
      expect(_circle(tester, zero), paints..circle());
      expect(_circle(tester, zero), isNot(paints..arc()));

      // Nothing supplied draws nothing at all.
      expect(_circle(tester, undecorated), isNot(paints..circle()));
      expect(_circle(tester, undecorated), isNot(paints..arc()));
    });

    testWidgets('selection, progress, fill and markers compose on one date',
        (tester) async {
      await _pump(
        tester,
        decorationBuilder: (date) => date == _selected
            ? const TioDateDecoration(
                progress: 0.5,
                fill: TioDateFill.solid,
                markerCount: 2,
              )
            : null,
      );

      // fill, progress track, progress arc, then the selection ring outside.
      expect(
        _circle(tester, _selected),
        paints
          ..circle()
          ..circle()
          ..arc()
          ..circle(strokeWidth: 0.5),
      );
      expect(
        find.descendant(of: _cell(_selected), matching: find.byType(Container)),
        findsNWidgets(2),
      );
    });

    testWidgets('a marker row collapses without clamping the caller count',
        (tester) async {
      const decoration = TioDateDecoration(markerCount: 9);

      expect(decoration.markerCount, 9);
      expect(
        decoration.visibleMarkerCount,
        TioDateDecoration.maxRenderedMarkers,
      );
      expect(decoration.hasCollapsedMarkers, isTrue);

      await _pump(
        tester,
        decorationBuilder: (date) => date == _selected ? decoration : null,
      );

      expect(
        find.descendant(of: _cell(_selected), matching: find.byType(Container)),
        findsNWidgets(TioDateDecoration.maxRenderedMarkers),
      );
    });
  });

  group('global first day of week', () {
    Future<List<String>> columnLabels(
      WidgetTester tester,
      int firstDayOfWeek, {
      TextScaler textScaler = TextScaler.noScaling,
    }) async {
      await _pump(
        tester,
        resolvedFirstDayOfWeek: firstDayOfWeek,
        textScaler: textScaler,
      );
      return tester
          .widgetList<Text>(
            find.descendant(of: _weekdayHeader(), matching: find.byType(Text)),
          )
          .map((text) => text.data!)
          .toList();
    }

    testWidgets('a Monday start puts Monday in the first column',
        (tester) async {
      expect((await columnLabels(tester, DateTime.monday)).first, 'MON');
    });

    testWidgets('a Sunday start puts Sunday in the first column',
        (tester) async {
      expect((await columnLabels(tester, DateTime.sunday)).first, 'SUN');
    });

    testWidgets('the resolved week start also frames the compact week',
        (tester) async {
      await _pump(tester, resolvedFirstDayOfWeek: DateTime.monday);

      // A Monday start moves the visible week to Aug 17..Aug 23.
      expect(_cell(DateTime(2026, 8, 17)), findsOne);
      expect(_cell(DateTime(2026, 8, 23)), findsOne);
      expect(_cell(DateTime(2026, 8, 16)), findsNothing);
    });

    testWidgets('three-letter labels fit compact width with large text',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final labels = await columnLabels(
        tester,
        DateTime.monday,
        textScaler: const TextScaler.linear(1.8),
      );

      expect(labels, <String>['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('changing the week start at runtime keeps the selected date',
        (tester) async {
      var firstDayOfWeek = DateTime.monday;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  TioDateCalendar(
                    selectedDate: _selected,
                    localToday: _today,
                    minDate: _augustFirst,
                    maxDate: _augustLast,
                    resolvedFirstDayOfWeek: firstDayOfWeek,
                    onDateSelected: (_) {},
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => firstDayOfWeek = DateTime.sunday),
                    child: const Text('switch'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('switch'));
      await tester.pumpAndSettle();

      final labels = tester.widgetList<Text>(
        find.descendant(of: _weekdayHeader(), matching: find.byType(Text)),
      );
      expect(labels.first.data, 'SUN');
      expect(
        tester.getSemantics(_cell(_selected)),
        isSemantics(isSelected: true),
      );
    });
  });

  group('handle gestures', () {
    testWidgets('a tap toggles the mode and reports it', (tester) async {
      final harness = await _pump(tester);

      await tester.tap(_handle());
      await tester.pumpAndSettle();
      expect(_isMonthMode(tester), isTrue);

      await tester.tap(_handle());
      await tester.pumpAndSettle();
      expect(_isMonthMode(tester), isFalse);

      expect(harness.displayModes, <TioDateCalendarDisplayMode>[
        TioDateCalendarDisplayMode.month,
        TioDateCalendarDisplayMode.compact,
      ]);
    });

    testWidgets('an outside tap collapses the expanded calendar',
        (tester) async {
      final harness = await _pump(
        tester,
        displayMode: TioDateCalendarDisplayMode.month,
        insideScrollablePage: true,
      );
      final outsideTop =
          tester.getTopLeft(find.byKey(const ValueKey('page-content'))).dy;

      await tester.tapAt(Offset(TioSpacing.md, outsideTop + TioSpacing.md));
      await tester.pumpAndSettle();

      expect(_isMonthMode(tester), isFalse);
      expect(
        harness.displayModes,
        <TioDateCalendarDisplayMode>[TioDateCalendarDisplayMode.compact],
      );
    });

    testWidgets('an inside date tap does not collapse the expanded calendar',
        (tester) async {
      final harness = await _pump(
        tester,
        displayMode: TioDateCalendarDisplayMode.month,
      );

      await tester.tap(_cell(_selected));
      await tester.pumpAndSettle();

      expect(_isMonthMode(tester), isTrue);
      expect(harness.displayModes, isEmpty);
    });

    testWidgets('a vertical drag from the handle expands', (tester) async {
      final harness = await _pump(tester);

      await tester.drag(_handle(), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(_isMonthMode(tester), isTrue);
      expect(
        harness.displayModes,
        <TioDateCalendarDisplayMode>[TioDateCalendarDisplayMode.month],
      );
    });

    testWidgets('an ordinary page scroll never changes the mode',
        (tester) async {
      final harness = await _pump(tester, insideScrollablePage: true);

      final before =
          tester.getTopLeft(find.byKey(const ValueKey('page-content')));
      await tester.drag(_cell(_selected), const Offset(0, -200));
      await tester.pumpAndSettle();

      // The page moved, so the gesture really was a vertical page scroll.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('page-content'))).dy,
        lessThan(before.dy),
      );
      expect(_isMonthMode(tester), isFalse);
      expect(harness.displayModes, isEmpty);
    });

    testWidgets('the handle keeps an accessible target and semantics',
        (tester) async {
      await _pump(tester);

      expect(tester.getSize(_handle()).width, 80);
      expect(tester.getSize(_handle()).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(_grabber()), const Size(60, 3));
      final grabber = tester.widget<DecoratedBox>(_grabber());
      final decoration = grabber.decoration as BoxDecoration;
      expect(
        decoration.borderRadius,
        const BorderRadius.all(Radius.circular(1.5)),
      );
      expect(
        tester.getCenter(_grabber()).dx,
        tester.getCenter(_handle()).dx,
      );
      expect(
        tester.getTopLeft(_grabber()).dy - tester.getTopLeft(_handle()).dy,
        1.5,
      );
      expect(
        tester.getSemantics(_handle()),
        isSemantics(isButton: true, label: 'Expand'),
      );
    });
  });

  group('accessibility', () {
    testWidgets('a date says what it is rather than relying on colour',
        (tester) async {
      await _pump(
        tester,
        decorationBuilder: (date) => date == _selected
            ? const TioDateDecoration(
                progress: 0.5,
                semanticsLabel: 'Half of today’s target',
              )
            : null,
      );

      final selectedNode = tester.getSemantics(_cell(_selected));
      expect(selectedNode.label, contains('August 18, 2026'));
      expect(selectedNode.label, contains('Selected'));
      expect(selectedNode.label, contains('Half of today’s target'));
      expect(selectedNode, isSemantics(isSelected: true));

      final todayNode = tester.getSemantics(_cell(_today));
      expect(todayNode.label, contains('Today'));
      expect(todayNode, isSemantics(isSelected: false));
    });
  });

  group('review regressions', () {
    testWidgets('a date numeral holds its vertical position through expansion',
        (tester) async {
      // The existing sibling test pins the cell box. This one pins the glyph
      // inside it, which is what a reader actually watches: an earlier build
      // kept the box still while the numeral hopped 3px because compact and
      // month rows centred the same content in differently sized boxes.
      final firstRowDate = DateTime(2026, 8, 1);
      await _pump(tester, initialSelected: firstRowDate);

      Rect numeral() => tester.getRect(
            find.descendant(
              of: _cell(firstRowDate),
              matching: find.text('${firstRowDate.day}'),
            ),
          );

      final compactNumeral = numeral();
      final compactCell = tester.getRect(_cell(firstRowDate));

      await tester.tap(_handle());
      await tester.pumpAndSettle();

      expect(numeral().top, compactNumeral.top);
      expect(numeral().height, compactNumeral.height);
      expect(tester.getRect(_cell(firstRowDate)).top, compactCell.top);
    });

    Future<void> pumpRange(
      WidgetTester tester, {
      required DateTime minDate,
      required DateTime maxDate,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: TioDateCalendar(
              selectedDate: _selected,
              localToday: _today,
              minDate: minDate,
              maxDate: maxDate,
              displayMode: TioDateCalendarDisplayMode.month,
              onDateSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'a range change with an unchanged week count re-anchors both pagers',
        (tester) async {
      // Aug 1..Aug 31 and Aug 1..Sep 30 both span six weeks, so a comparison
      // that only looks at the week-page count sees no difference, while the
      // month count goes from one to two and September becomes reachable.
      await pumpRange(
        tester,
        minDate: _augustFirst,
        maxDate: _augustLast,
      );
      expect(_monthPageCount(tester), 1);

      await pumpRange(
        tester,
        minDate: _augustFirst,
        maxDate: DateTime(2026, 9, 30),
      );

      // The month pager gained its second page rather than staying anchored to
      // the old range, and the selection is untouched by the range change.
      expect(_monthPageCount(tester), 2);
      expect(_cell(_selected), findsOne);

      await tester.fling(_monthPager(), const Offset(-400, 0), 1200);
      await tester.pumpAndSettle();
      expect(_cell(DateTime(2026, 9, 15)), findsOne);
    });

    testWidgets('a shrinking range clamps the pagers without losing selection',
        (tester) async {
      await pumpRange(
        tester,
        minDate: DateTime(2026, 7, 1),
        maxDate: _augustLast,
      );
      expect(_monthPageCount(tester), 2);

      await pumpRange(
        tester,
        minDate: _augustFirst,
        maxDate: _augustLast,
      );

      expect(_monthPageCount(tester), 1);
      expect(_cell(_selected), findsOne);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'a jump requested before mount is honoured once the pagers '
        'exist', (tester) async {
      final controller = TioDateCalendarController();
      addTearDown(controller.dispose);

      final target = DateTime(2026, 7, 8);
      // Nobody is listening yet: this is the case the widget has to pick up
      // for itself when it initialises.
      controller.jumpToDate(target);

      final harness = await _pump(
        tester,
        controller: controller,
        minDate: DateTime(2026, 7, 1),
      );

      expect(_cell(target), findsOne);
      expect(controller.pendingJump, isNull);
      // Reveal-only: the jump moves the viewport, never the selection.
      expect(harness.selectedDate, _selected);
      expect(harness.selectedDates, isEmpty);
    });

    testWidgets('a pre-mount jump also lands when the calendar opens expanded',
        (tester) async {
      final controller = TioDateCalendarController();
      addTearDown(controller.dispose);

      final target = DateTime(2026, 7, 8);
      controller.jumpToDate(target);

      await _pump(
        tester,
        controller: controller,
        minDate: DateTime(2026, 7, 1),
        displayMode: TioDateCalendarDisplayMode.month,
      );

      // July's page, not the selected date's August page.
      expect(_cell(DateTime(2026, 7, 1)), findsOne);
      expect(controller.pendingJump, isNull);
    });

    testWidgets('large text grows the boxes instead of clipping the glyphs',
        (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(
        tester,
        resolvedFirstDayOfWeek: DateTime.monday,
        textScaler: const TextScaler.linear(1.8),
      );

      void expectFits(Finder box, Finder glyph, String reason) {
        final boxRect = tester.getRect(box);
        final glyphRect = tester.getRect(glyph);
        expect(
          glyphRect.height,
          lessThanOrEqualTo(boxRect.height + 0.01),
          reason: reason,
        );
      }

      expectFits(
        _weekdayHeader(),
        find
            .descendant(of: _weekdayHeader(), matching: find.byType(Text))
            .first,
        'weekday label is taller than the header that holds it',
      );
      expectFits(
        _cell(_selected),
        find.descendant(of: _cell(_selected), matching: find.text('18')),
        'date numeral is taller than the compact cell that holds it',
      );
      expect(tester.takeException(), isNull);

      await tester.tap(_handle());
      await tester.pumpAndSettle();

      expectFits(
        _cell(_selected),
        find.descendant(of: _cell(_selected), matching: find.text('18')),
        'date numeral is taller than the expanded cell that holds it',
      );
      expect(tester.takeException(), isNull);
      // The affordance stays reachable at large text.
      expect(tester.getSize(_handle()).height, greaterThanOrEqualTo(48));
    });

    testWidgets('a Sunday start also survives large text at a narrow width',
        (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(
        tester,
        resolvedFirstDayOfWeek: DateTime.sunday,
        textScaler: const TextScaler.linear(1.8),
      );

      expect(tester.takeException(), isNull);
      expect(_weekdayHeader(), findsOne);
      expect(_cell(_selected), findsOne);
    });
  });

  // _today is Thursday 20 Aug 2026 and _selected is Tuesday 18 Aug 2026, so
  // these two columns are never the same and a test cannot pass by accident.
  group('weekday header Today emphasis', () {
    testWidgets("today's column is emphasised while the rest stay muted",
        (tester) async {
      await _pump(tester);

      expect(_weekdayStyle(tester, 'THU').fontWeight, TioFontWeight.w700);
      for (final other in const ['SUN', 'MON', 'TUE', 'WED', 'FRI', 'SAT']) {
        expect(
          _weekdayStyle(tester, other).fontWeight,
          TioFontWeight.w500,
          reason: '$other is not today and must stay muted',
        );
      }
      // The header and the numeral under it carry one emphasis, not two.
      expect(
        _weekdayStyle(tester, 'THU').color,
        _numeralStyle(tester, _today).color,
      );

      await tester.tap(_handle());
      await tester.pumpAndSettle();

      // The header is shared, so expanding must not drop the emphasis.
      expect(_weekdayStyle(tester, 'THU').fontWeight, TioFontWeight.w700);
    });

    testWidgets('paging away from today drops the emphasis entirely',
        (tester) async {
      await _pump(tester);
      expect(_weekdayStyle(tester, 'THU').fontWeight, TioFontWeight.w700);

      await tester.fling(_pager(), const Offset(400, 0), 1200);
      await tester.pumpAndSettle();

      // Today is off screen, so the header has nothing to point at. The
      // emphasis is dropped rather than left bold over a week Today is not in.
      expect(_cell(_today), findsNothing);
      for (final label in const [
        'SUN',
        'MON',
        'TUE',
        'WED',
        'THU',
        'FRI',
        'SAT',
      ]) {
        expect(
          _weekdayStyle(tester, label).fontWeight,
          TioFontWeight.w500,
          reason: '$label must not inherit the emphasis Today left behind',
        );
      }
      // Sunday keeps its own colour contract, which Today never owned.
      expect(
        _weekdayStyle(tester, 'SUN').color,
        TioColors.light.danger.withAlpha(TioAlpha.alpha140),
      );
    });

    testWidgets('returning to today restores the emphasis', (tester) async {
      final controller = TioDateCalendarController();
      addTearDown(controller.dispose);

      await _pump(tester, controller: controller);

      await tester.fling(_pager(), const Offset(400, 0), 1200);
      await tester.pumpAndSettle();
      expect(_weekdayStyle(tester, 'THU').fontWeight, TioFontWeight.w500);

      // The same reveal seam the Meal Diary Today action drives. Core is not
      // asked to grow a product-level Today button for this.
      controller.jumpToDate(_today);
      await tester.pumpAndSettle();

      expect(_cell(_today), findsOne);
      expect(_weekdayStyle(tester, 'THU').fontWeight, TioFontWeight.w700);
    });

    testWidgets('the month rendering follows the same visible range',
        (tester) async {
      await _pump(tester, displayMode: TioDateCalendarDisplayMode.month);
      expect(_weekdayStyle(tester, 'THU').fontWeight, TioFontWeight.w700);

      // A wider range so there is a Today-less month to page to.
      await _pump(
        tester,
        displayMode: TioDateCalendarDisplayMode.month,
        minDate: DateTime(2026, 6, 1),
        initialSelected: DateTime(2026, 6, 10),
      );

      expect(_weekdayStyle(tester, 'THU').fontWeight, TioFontWeight.w500);
    });

    testWidgets('selecting another date does not move the emphasis',
        (tester) async {
      final harness = await _pump(tester);

      // Monday 17 Aug: a different column from both today and the old
      // selection, so a selection-driven header would visibly follow it.
      await tester.tap(_cell(DateTime(2026, 8, 17)));
      await tester.pumpAndSettle();

      expect(harness.selectedDate, DateTime(2026, 8, 17));
      expect(_weekdayStyle(tester, 'MON').fontWeight, TioFontWeight.w500);
      expect(_weekdayStyle(tester, 'THU').fontWeight, TioFontWeight.w700);
    });

    testWidgets('a Sunday today keeps the Sunday colour and gains the weight',
        (tester) async {
      await _pump(tester);
      final mutedSunday = _weekdayStyle(tester, 'SUN');

      // Sunday 23 Aug 2026, with the selection put in Today's own week so the
      // emphasis is being judged on Today's visibility, not on the selection.
      await _pump(
        tester,
        localToday: DateTime(2026, 8, 23),
        initialSelected: DateTime(2026, 8, 25),
      );
      final todaySunday = _weekdayStyle(tester, 'SUN');

      expect(mutedSunday.fontWeight, TioFontWeight.w500);
      expect(todaySunday.fontWeight, TioFontWeight.w700);
      // Sunday stays red either way; being today only removes the muting.
      expect(todaySunday.color, isNot(mutedSunday.color));
      expect(_weekdayStyle(tester, 'THU').fontWeight, TioFontWeight.w500);
    });
  });
}
