import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

Future<void> _pumpCupertinoPicker(
  WidgetTester tester, {
  required DateTime value,
  required DateTime maximumDate,
  DateTime? minimumDate,
  TioDateTimeResolver? resolver,
  ValueChanged<DateTime>? onChanged,
  TioThemeMode mode = TioThemeMode.light,
}) {
  return tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: SizedBox(
          height: TioWheelPickerTokens.viewportHeight,
          child: TioDateTimeWheelPicker(
            value: value,
            maximumDate: maximumDate,
            minimumDate: minimumDate,
            resolveDateTime: resolver,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('TioDateTimeWheelPicker', () {
    testWidgets('uses one native 12-hour Cupertino DateTime drum',
        (tester) async {
      final value = DateTime(2026, 9, 6, 0, 7);
      final maximum = DateTime(2026, 9, 6, 14, 30);
      await _pumpCupertinoPicker(tester, value: value, maximumDate: maximum);

      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.mode, CupertinoDatePickerMode.dateAndTime);
      expect(picker.initialDateTime, value);
      expect(picker.minimumDate, isNull);
      expect(picker.maximumDate, maximum);
      expect(picker.use24hFormat, isFalse);
      expect(find.text('Date'), findsNothing);
      expect(find.text('Hour'), findsNothing);
      expect(find.text('Minute'), findsNothing);
      expect(find.text('AM/PM'), findsNothing);
    });

    testWidgets('passes optional generic lower bounds to the native picker',
        (tester) async {
      final minimum = DateTime(2024, 1, 1);
      final maximum = DateTime(2026, 9, 6, 14, 30);
      await _pumpCupertinoPicker(
        tester,
        value: DateTime(2025, 6, 2, 8),
        minimumDate: minimum,
        maximumDate: maximum,
      );

      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.minimumDate, minimum);
      expect(picker.maximumDate, maximum);
    });

    testWidgets('resolver snap-back recreates the controlled native drum',
        (tester) async {
      final boundary = DateTime(2026, 9, 6, 0, 7);
      DateTime? selected;
      await _pumpCupertinoPicker(
        tester,
        value: boundary,
        maximumDate: boundary,
        resolver: (candidate) =>
            candidate.isAfter(boundary) ? boundary : candidate,
        onChanged: (value) => selected = value,
      );

      final nativePicker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      nativePicker.onDateTimeChanged(DateTime(2026, 9, 6, 0, 8));
      await tester.pump();

      expect(selected, boundary);
      expect(
        find.byKey(const ValueKey('tio-date-time-cupertino-1')),
        findsOneWidget,
      );
    });

    testWidgets('external value update resynchronizes the native drum',
        (tester) async {
      var current = DateTime(2026, 9, 6, 10, 0);
      final maximum = DateTime(2026, 9, 6, 23, 59);

      late StateSetter setState;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return TioDateTimeWheelPicker(
                  value: current,
                  maximumDate: maximum,
                  onChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('tio-date-time-cupertino-0')),
        findsOneWidget,
      );

      setState(() => current = DateTime(2026, 9, 6, 11, 0));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('tio-date-time-cupertino-1')),
        findsOneWidget,
      );
    });

    testWidgets('maximumDate bound change resynchronizes the native drum',
        (tester) async {
      final value = DateTime(2026, 9, 6, 10, 0);
      var maximum = DateTime(2026, 9, 6, 12, 0);

      late StateSetter setState;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return TioDateTimeWheelPicker(
                  value: value,
                  maximumDate: maximum,
                  onChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('tio-date-time-cupertino-0')),
        findsOneWidget,
      );

      setState(() => maximum = DateTime(2026, 9, 6, 13, 0));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('tio-date-time-cupertino-1')),
        findsOneWidget,
      );
    });

    testWidgets('valid detent notifies without recreating native drum',
        (tester) async {
      final boundary = DateTime(2026, 9, 6, 10, 0);
      final maximum = DateTime(2026, 9, 6, 23, 59);
      DateTime? selected;
      await _pumpCupertinoPicker(
        tester,
        value: boundary,
        maximumDate: maximum,
        onChanged: (value) => selected = value,
      );

      final nativePicker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      final validDetent = DateTime(2026, 9, 6, 10, 5);
      nativePicker.onDateTimeChanged(validDetent);
      await tester.pump();

      expect(selected, validDetent);
      expect(
        find.byKey(const ValueKey('tio-date-time-cupertino-0')),
        findsOneWidget,
      );
    });

    testWidgets('selection treatment derives from the active Tio theme',
        (tester) async {
      await _pumpCupertinoPicker(
        tester,
        value: DateTime(2026, 9, 6, 10, 30),
        maximumDate: DateTime(2026, 9, 6, 14, 30),
        mode: TioThemeMode.oled,
      );

      final theme =
          tester.widgetList<CupertinoTheme>(find.byType(CupertinoTheme)).last;
      expect(
        theme.data.textTheme.dateTimePickerTextStyle.color,
        TioColors.oled.textPrimary,
      );
      expect(
        theme.data.textTheme.dateTimePickerTextStyle.fontSize,
        TioFontSize.size18,
      );

      final pill = tester.widget<Container>(
        find.byKey(const ValueKey('tio-date-time-wheel-selection-pill')),
      );
      final decoration = pill.decoration as BoxDecoration;
      expect(
        decoration.color,
        TioColors.oled.surfaceVariant.withAlpha(
          TioWheelPickerTokens.selectionSurfaceAlpha,
        ),
      );
      expect(
        decoration.borderRadius,
        BorderRadius.circular(TioRadius.md),
      );
    });
  });

  group('TioDateTimePickerPopup', () {
    testWidgets('presents overlay card anchored to child without bottom sheet route',
        (tester) async {
      final anchorKey = GlobalKey();
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: Center(
              child: TioDateTimePickerPopup(
                anchorKey: anchorKey,
                isOpen: true,
                onDismiss: () => dismissed = true,
                value: DateTime(2026, 9, 6, 10, 0),
                maximumDate: DateTime(2026, 9, 6, 12, 0),
                onChanged: (_) {},
                child: Container(
                  key: anchorKey,
                  width: 120,
                  height: 48,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('tio-date-time-picker-popup')), findsOneWidget);
      expect(find.byType(ModalBottomSheetRoute), findsNothing);
      expect(find.byKey(anchorKey), findsOneWidget);

      // Tap outside dismisses popup
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(dismissed, isTrue);
    });
  });
}
