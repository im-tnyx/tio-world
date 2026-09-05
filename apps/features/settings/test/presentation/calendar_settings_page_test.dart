import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    FirstDayOfWeekPreference initial = FirstDayOfWeekPreference.monday,
    Future<void> Function(FirstDayOfWeekPreference)? onChanged,
    String? errorText,
    // Seven options do not fit a default test viewport, and a `ListView` only
    // builds what it can lay out. A viewport tall enough for the whole list
    // keeps these cases about the choice rather than about scrolling.
    Size surfaceSize = const Size(390, 1400),
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var current = initial;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: StatefulBuilder(
          builder: (context, setState) {
            return CalendarSettingsPage(
              firstDayOfWeek: current,
              errorText: errorText,
              onFirstDayOfWeekChanged: (next) async {
                current = next;
                setState(() {});
                await onChanged?.call(next);
              },
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder optionFor(FirstDayOfWeekPreference option) => find.byKey(
        ValueKey('calendar-first-day-option-${option.storageValue}'),
      );

  testWidgets('offers every day of the week, Monday first and default',
      (tester) async {
    await pumpPage(tester);

    expect(find.text('First day of week'), findsOneWidget);
    expect(find.text('Monday (default)'), findsOneWidget);
    for (final name in const [
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ]) {
      expect(find.text(name), findsOneWidget, reason: '$name must be offered');
    }
    // Only the shipped default is marked as such.
    expect(find.textContaining('(default)'), findsOneWidget);

    // Monday through Sunday, in that order, is what a reader scans.
    final labels = tester
        .widgetList<TioSelectableCard>(find.byType(TioSelectableCard))
        .map((card) => card.semanticLabel)
        .toList();
    expect(labels, [
      'Monday (default)',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ]);
  });

  testWidgets('offers no Automatic or System default choice', (tester) async {
    await pumpPage(tester);

    expect(find.textContaining('Automatic'), findsNothing);
    expect(find.textContaining('System default'), findsNothing);
    expect(find.byType(TioSelectableCard), findsNWidgets(7));
  });

  testWidgets('carries no help text, only the heading and the options',
      (tester) async {
    await pumpPage(tester);

    // Naming a feature would frame an app-global value as that feature's
    // setting; naming "every calendar" would promise screens that do not
    // exist yet; a storage note is implementation detail. The options say
    // everything this screen has to say.
    expect(find.textContaining('Meal Diary'), findsNothing);
    expect(find.textContaining('Nutrition'), findsNothing);
    expect(find.textContaining('every calendar'), findsNothing);
    expect(find.textContaining('this device'), findsNothing);
    expect(find.textContaining('Saved'), findsNothing);
    expect(find.textContaining('Weeks across Tio'), findsNothing);

    // App bar title, heading and seven option labels. Nothing else.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(texts, hasLength(9));
    expect(texts, contains('Calendar'));
    expect(texts, contains('First day of week'));
  });

  testWidgets('announces each option as a selectable button', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpPage(tester);

      expect(
        tester.getSemantics(find.bySemanticsLabel('Monday (default)')),
        isSemantics(isSelected: true, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Wednesday')),
        isSemantics(isSelected: false, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sunday')),
        isSemantics(isSelected: false, isButton: true, hasTapAction: true),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('draws no ordering preview', (tester) async {
    await pumpPage(tester);

    // The day names are the ordering. Drawing it again was decoration.
    expect(
      find.byKey(const ValueKey('calendar-first-day-preview')),
      findsNothing,
    );
    expect(find.textContaining('MON   TUE'), findsNothing);
  });

  testWidgets('tapping an option applies it immediately, no Save step',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final changes = <FirstDayOfWeekPreference>[];
      await pumpPage(tester, onChanged: (next) async => changes.add(next));

      // No Save button exists to press, so the tap itself has to be the commit.
      expect(find.widgetWithText(TioButton, 'Save'), findsNothing);

      await tester.tap(optionFor(FirstDayOfWeekPreference.saturday));
      await tester.pumpAndSettle();

      expect(changes, [FirstDayOfWeekPreference.saturday]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Saturday')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Monday (default)')),
        isSemantics(isSelected: false),
      );

      await tester.tap(optionFor(FirstDayOfWeekPreference.monday));
      await tester.pumpAndSettle();

      expect(changes, [
        FirstDayOfWeekPreference.saturday,
        FirstDayOfWeekPreference.monday,
      ]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Monday (default)')),
        isSemantics(isSelected: true),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('every option is independently reachable', (tester) async {
    final changes = <FirstDayOfWeekPreference>[];
    await pumpPage(tester, onChanged: (next) async => changes.add(next));

    for (final option in FirstDayOfWeekPreference.values) {
      await tester.tap(optionFor(option));
      await tester.pumpAndSettle();
    }

    expect(changes, FirstDayOfWeekPreference.values);
  });

  testWidgets('a failed write surfaces the retryable message', (tester) async {
    await pumpPage(tester, errorText: 'Could not save. Please try again.');

    expect(
      find.byKey(const ValueKey('calendar-first-day-error')),
      findsOneWidget,
    );
    expect(find.text('Could not save. Please try again.'), findsOneWidget);
  });

  testWidgets('renders the whole list on a small phone without exception',
      (tester) async {
    await pumpPage(tester, surfaceSize: const Size(320, 640));

    expect(tester.takeException(), isNull);
    // The list scrolls rather than overflowing, so the last option is reachable.
    await tester.scrollUntilVisible(
      optionFor(FirstDayOfWeekPreference.sunday),
      120,
    );
    expect(optionFor(FirstDayOfWeekPreference.sunday), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
