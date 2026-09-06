import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';

/// Feature-owned constraint hook for a candidate emitted by the native drum.
typedef TioDateTimeResolver = DateTime Function(DateTime candidate);

/// Tio's controlled, theme-adapted Cupertino-style DateTime drum.
///
/// Core owns only DateTime presentation and generic bounds. A caller supplies
/// domain constraints through [resolveDateTime]; Core never learns whether a
/// selected value belongs to a meal, weight, or workout record.
class TioDateTimeWheelPicker extends StatefulWidget {
  const TioDateTimeWheelPicker({
    required this.value,
    required this.maximumDate,
    required this.onChanged,
    super.key,
    this.minimumDate,
    this.resolveDateTime,
  });

  final DateTime value;
  final DateTime maximumDate;
  final DateTime? minimumDate;
  final TioDateTimeResolver? resolveDateTime;
  final ValueChanged<DateTime> onChanged;

  @override
  State<TioDateTimeWheelPicker> createState() => _TioDateTimeWheelPickerState();
}

class _TioDateTimeWheelPickerState extends State<TioDateTimeWheelPicker> {
  late DateTime _displayedValue;
  DateTime? _lastAndroidHapticValue;
  var _pickerRevision = 0;

  @override
  void initState() {
    super.initState();
    assert(
      widget.minimumDate == null ||
          !widget.minimumDate!.isAfter(widget.maximumDate),
    );
    _displayedValue = _constrain(_minute(widget.value));
  }

  @override
  void didUpdateWidget(covariant TioDateTimeWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _constrain(_minute(widget.value));
    final boundsChanged = widget.minimumDate != oldWidget.minimumDate ||
        widget.maximumDate != oldWidget.maximumDate;
    if (next == _displayedValue && !boundsChanged) return;

    // CupertinoDatePicker reads initialDateTime once. A narrow re-key keeps a
    // caller-resolved snap-back and fresh bounds visually controlled without
    // recreating the native drum after every ordinary valid detent.
    _displayedValue = next;
    _pickerRevision++;
  }

  DateTime _minute(DateTime value) => DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
      );

  DateTime _constrain(DateTime value) {
    final minimum = widget.minimumDate;
    if (minimum != null && value.isBefore(minimum)) return _minute(minimum);
    if (value.isAfter(widget.maximumDate)) return _minute(widget.maximumDate);
    return value;
  }

  void _onNativeChanged(DateTime candidate) {
    final minuteCandidate = _minute(candidate);
    final resolved = _constrain(
      _minute(widget.resolveDateTime?.call(minuteCandidate) ?? minuteCandidate),
    );
    final needsResync = resolved != minuteCandidate;

    if (defaultTargetPlatform != TargetPlatform.iOS &&
        _lastAndroidHapticValue != minuteCandidate) {
      // CupertinoPicker already supplies the native iOS selection tick. Its
      // Android implementation intentionally does not, so add exactly one
      // Tio selection haptic for each emitted settled native detent there.
      _lastAndroidHapticValue = minuteCandidate;
      HapticFeedback.selectionClick();
    }

    if (resolved != _displayedValue || needsResync) {
      setState(() {
        _displayedValue = resolved;
        if (needsResync) _pickerRevision++;
      });
    }
    widget.onChanged(resolved);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final materialTheme = Theme.of(context);
    final pickerTextStyle =
        CupertinoTheme.of(context).textTheme.dateTimePickerTextStyle.copyWith(
              color: colors.textPrimary,
              fontSize: TioFontSize.size18,
              fontFamily: materialTheme.textTheme.bodyLarge?.fontFamily,
            );

    return Semantics(
      key: const ValueKey('tio-date-time-wheel-picker'),
      container: true,
      label: 'Date and time picker',
      child: CupertinoTheme(
        data: CupertinoThemeData(
          brightness: materialTheme.brightness,
          primaryColor: colors.textPrimary,
          textTheme: CupertinoTextThemeData(
            dateTimePickerTextStyle: pickerTextStyle,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Selection pill rendered behind the wheel text, matching the
            // DOB / weight / height picker z-order convention.
            Container(
              key: const ValueKey('tio-date-time-wheel-selection-pill'),
              height: TioWheelPickerTokens.selectionHeight,
              margin: const EdgeInsets.symmetric(
                horizontal: TioWheelPickerTokens.selectionHorizontalMargin,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withAlpha(
                  TioWheelPickerTokens.selectionSurfaceAlpha,
                ),
                borderRadius: BorderRadius.circular(TioRadius.md),
              ),
            ),
            CupertinoDatePicker(
              key: ValueKey('tio-date-time-cupertino-$_pickerRevision'),
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: _displayedValue,
              minimumDate: widget.minimumDate,
              maximumDate: widget.maximumDate,
              use24hFormat: false,
              itemExtent: TioWheelPickerTokens.itemExtent,
              backgroundColor: TioPalette.transparent,
              onDateTimeChanged: _onNativeChanged,
              // Suppress the native overlay — it renders above the wheel text.
              // The pill Container above this picker provides the behind-text
              // selection highlight instead.
              selectionOverlayBuilder: (
                context, {
                required selectedIndex,
                required columnCount,
              }) =>
                  const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
