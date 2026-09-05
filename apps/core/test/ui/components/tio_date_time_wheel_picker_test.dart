import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

const _dateWheel = ValueKey('tio-date-time-wheel-date');
const _hourWheel = ValueKey('tio-date-time-wheel-hour');
const _minuteWheel = ValueKey('tio-date-time-wheel-minute');
const _periodWheel = ValueKey('tio-date-time-wheel-period');

Future<void> _pumpPicker(
  WidgetTester tester, {
  required DateTime value,
  required DateTime maximumDate,
  DateTime? minimumDate,
  TioDateTimeResolver? resolver,
  ValueChanged<DateTime>? onChanged,
  TioThemeMode mode = TioThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: Center(
          child: TioDateTimeWheelPicker(
            value: value,
            maximumDate: maximumDate,
            minimumDate: minimumDate,
            today: maximumDate,
            resolveDateTime: resolver,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _selectedText(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

Future<void> _next(WidgetTester tester, Key key) async {
  await tester.drag(
    find.byKey(key),
    const Offset(0, -TioWheelPickerTokens.itemExtent),
  );
  await tester.pumpAndSettle();
}

Future<void> _previous(WidgetTester tester, Key key) async {
  await tester.drag(
    find.byKey(key),
    const Offset(0, TioWheelPickerTokens.itemExtent),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('generic columns expose finite and looping delegate behavior',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: TioWheelPickerTokens.viewportHeight,
          child: Row(
            children: [
              Expanded(
                child: TioWheelPickerColumn(
                  selectedIndex: 0,
                  itemCount: 3,
                  onSelectedItemChanged: (_) {},
                  itemBuilder: (_, index, selected) => Text('$index'),
                ),
              ),
              Expanded(
                child: TioWheelPickerColumn(
                  selectedIndex: 0,
                  itemCount: 3,
                  looping: true,
                  onSelectedItemChanged: (_) {},
                  itemBuilder: (_, index, selected) => Text('$index'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final wheels = tester
        .widgetList<ListWheelScrollView>(find.byType(ListWheelScrollView))
        .toList();
    expect(wheels, hasLength(2));
    expect(
      (wheels.first.childDelegate as ListWheelChildBuilderDelegate).childCount,
      3,
    );
    expect(
      (wheels.last.childDelegate as ListWheelChildBuilderDelegate).childCount,
      isNull,
    );
  });

  testWidgets('initializes all columns from the supplied DateTime',
      (tester) async {
    await _pumpPicker(
      tester,
      value: DateTime(2026, 9, 5, 23, 7, 42),
      maximumDate: DateTime(2026, 9, 6),
    );

    expect(_selectedText(tester, 'tio-date-time-date-selected'), 'Sep 5');
    expect(_selectedText(tester, 'tio-date-time-hour-selected'), '11');
    expect(_selectedText(tester, 'tio-date-time-minute-selected'), '07');
    expect(_selectedText(tester, 'tio-date-time-period-selected'), 'PM');
  });

  testWidgets('minute rollover synchronizes hour and AM/PM', (tester) async {
    DateTime? selected;
    await _pumpPicker(
      tester,
      value: DateTime(2026, 9, 5, 11, 59),
      maximumDate: DateTime(2026, 9, 6),
      onChanged: (value) => selected = value,
    );

    await _next(tester, _minuteWheel);

    expect(selected, DateTime(2026, 9, 5, 12));
    expect(_selectedText(tester, 'tio-date-time-hour-selected'), '12');
    expect(_selectedText(tester, 'tio-date-time-minute-selected'), '00');
    expect(_selectedText(tester, 'tio-date-time-period-selected'), 'PM');
  });

  testWidgets('hour wheel rolls continuously from 11 to 12', (tester) async {
    DateTime? selected;
    await _pumpPicker(
      tester,
      value: DateTime(2026, 9, 5, 22, 15),
      maximumDate: DateTime(2026, 9, 6),
      onChanged: (value) => selected = value,
    );

    await _next(tester, _hourWheel);

    expect(selected, DateTime(2026, 9, 5, 23, 15));
    expect(_selectedText(tester, 'tio-date-time-hour-selected'), '11');
    expect(_selectedText(tester, 'tio-date-time-period-selected'), 'PM');
  });

  testWidgets('AM/PM wheel changes the coherent DateTime by twelve hours',
      (tester) async {
    DateTime? selected;
    await _pumpPicker(
      tester,
      value: DateTime(2026, 9, 5, 10, 30),
      maximumDate: DateTime(2026, 9, 6),
      onChanged: (value) => selected = value,
    );

    await _next(tester, _periodWheel);

    expect(selected, DateTime(2026, 9, 5, 22, 30));
    expect(_selectedText(tester, 'tio-date-time-period-selected'), 'PM');
  });

  testWidgets('midnight forward increments the selected date', (tester) async {
    DateTime? selected;
    await _pumpPicker(
      tester,
      value: DateTime(2026, 9, 5, 23, 59),
      maximumDate: DateTime(2026, 9, 6),
      onChanged: (value) => selected = value,
    );

    await _next(tester, _minuteWheel);

    expect(selected, DateTime(2026, 9, 6));
    expect(_selectedText(tester, 'tio-date-time-date-selected'), 'Today');
    expect(_selectedText(tester, 'tio-date-time-hour-selected'), '12');
    expect(_selectedText(tester, 'tio-date-time-period-selected'), 'AM');
  });

  testWidgets('midnight reverse decrements the selected date', (tester) async {
    DateTime? selected;
    await _pumpPicker(
      tester,
      value: DateTime(2026, 9, 6),
      maximumDate: DateTime(2026, 9, 6),
      onChanged: (value) => selected = value,
    );

    await _previous(tester, _minuteWheel);

    expect(selected, DateTime(2026, 9, 5, 23, 59));
    expect(_selectedText(tester, 'tio-date-time-date-selected'), 'Sep 5');
    expect(_selectedText(tester, 'tio-date-time-hour-selected'), '11');
    expect(_selectedText(tester, 'tio-date-time-minute-selected'), '59');
    expect(_selectedText(tester, 'tio-date-time-period-selected'), 'PM');
  });

  testWidgets('date maximum is finite while historical dates remain reachable',
      (tester) async {
    final values = <DateTime>[];
    await _pumpPicker(
      tester,
      value: DateTime(2026, 9, 6, 8),
      maximumDate: DateTime(2026, 9, 6),
      onChanged: values.add,
    );

    await _previous(tester, _dateWheel);
    expect(_selectedText(tester, 'tio-date-time-date-selected'), 'Today');
    expect(values, isEmpty, reason: 'the Date wheel cannot pass its maximum');

    await _next(tester, _dateWheel);
    expect(values.single, DateTime(2026, 9, 5, 8));
    expect(_selectedText(tester, 'tio-date-time-date-selected'), 'Sep 5');
  });

  testWidgets('resolver snap-back resynchronizes without duplicate haptics',
      (tester) async {
    final haptics = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    final boundary = DateTime(2026, 9, 6, 0, 7);
    DateTime? selected;
    await _pumpPicker(
      tester,
      value: boundary,
      maximumDate: boundary,
      resolver: (candidate) => candidate.isAfter(boundary) ? boundary : candidate,
      onChanged: (value) => selected = value,
    );

    await _next(tester, _minuteWheel);

    expect(selected, boundary);
    expect(_selectedText(tester, 'tio-date-time-minute-selected'), '07');
    expect(_selectedText(tester, 'tio-date-time-hour-selected'), '12');
    expect(_selectedText(tester, 'tio-date-time-period-selected'), 'AM');
    expect(
      haptics.where((call) => call.arguments == 'HapticFeedbackType.selectionClick'),
      hasLength(1),
    );
  });

  testWidgets('selection pill inherits the active semantic theme',
      (tester) async {
    await _pumpPicker(
      tester,
      value: DateTime(2026, 9, 6, 10, 30),
      maximumDate: DateTime(2026, 9, 6),
      mode: TioThemeMode.oled,
    );

    final pill = tester.widget<Container>(
      find.byKey(const ValueKey('tio-date-time-wheel-selection-pill')),
    );
    final decoration = pill.decoration! as BoxDecoration;
    expect(
      decoration.color,
      TioColors.oled.surfaceVariant.withAlpha(
        TioWheelPickerTokens.selectionSurfaceAlpha,
      ),
    );
  });
}
