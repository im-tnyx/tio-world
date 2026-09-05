import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import 'tio_wheel_picker.dart';

typedef TioDateTimeResolver = DateTime Function(DateTime candidate);

/// A controlled, coherent local DateTime wheel.
///
/// Core owns only generic calendar/time composition. Feature callers own
/// business defaults and constraints through [resolveDateTime]. For example,
/// Nutrition can snap a future Meal attempt to a fresh current-local minute
/// without teaching Core anything about meals or persistence.
class TioDateTimeWheelPicker extends StatefulWidget {
  const TioDateTimeWheelPicker({
    required this.value,
    required this.maximumDate,
    required this.onChanged,
    super.key,
    this.minimumDate,
    this.today,
    this.resolveDateTime,
  });

  final DateTime value;
  final DateTime maximumDate;
  final DateTime? minimumDate;
  final DateTime? today;
  final TioDateTimeResolver? resolveDateTime;
  final ValueChanged<DateTime> onChanged;

  @override
  State<TioDateTimeWheelPicker> createState() =>
      _TioDateTimeWheelPickerState();
}

class _TioDateTimeWheelPickerState extends State<TioDateTimeWheelPicker> {
  late DateTime _selected;
  var _syncRevision = 0;

  @override
  void initState() {
    super.initState();
    assert(
      widget.minimumDate == null ||
          !widget.minimumDate!.isAfter(widget.maximumDate),
    );
    _selected = _bound(_minute(widget.value));
  }

  @override
  void didUpdateWidget(covariant TioDateTimeWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _bound(_minute(widget.value));
    if (next != _selected) _selected = next;
  }

  DateTime _minute(DateTime value) => DateTime(
        value.year,
        value.month,
        value.day,
        value.hour,
        value.minute,
      );

  DateTime _date(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  int _calendarDaysBetween(DateTime later, DateTime earlier) => DateTime.utc(
        later.year,
        later.month,
        later.day,
      ).difference(DateTime.utc(earlier.year, earlier.month, earlier.day)).inDays;

  DateTime _withDate(DateTime value, DateTime date) => DateTime(
        date.year,
        date.month,
        date.day,
        value.hour,
        value.minute,
      );

  DateTime _bound(DateTime value) {
    final maximum = _date(widget.maximumDate);
    final minimum = widget.minimumDate == null
        ? null
        : _date(widget.minimumDate!);
    final calendarDate = _date(value);
    if (calendarDate.isAfter(maximum)) return _withDate(value, maximum);
    if (minimum != null && calendarDate.isBefore(minimum)) {
      return _withDate(value, minimum);
    }
    return value;
  }

  void _applyCandidate(DateTime candidate) {
    final normalized = _bound(_minute(candidate));
    final resolved = _bound(
      _minute(widget.resolveDateTime?.call(normalized) ?? normalized),
    );
    final wasResolved = resolved != normalized;

    setState(() {
      _selected = resolved;
      if (wasResolved) _syncRevision++;
    });
    widget.onChanged(resolved);
  }

  void _changeDate(TioWheelSelectionChange change) {
    final maximum = _date(widget.maximumDate);
    final date = DateTime(
      maximum.year,
      maximum.month,
      maximum.day - change.index,
    );
    _applyCandidate(_withDate(_selected, date));
  }

  void _changeHour(TioWheelSelectionChange change) =>
      _applyCandidate(_selected.add(Duration(hours: change.itemDelta)));

  void _changeMinute(TioWheelSelectionChange change) =>
      _applyCandidate(_selected.add(Duration(minutes: change.itemDelta)));

  void _changePeriod(TioWheelSelectionChange change) =>
      _applyCandidate(_selected.add(Duration(hours: 12 * change.itemDelta)));

  TextStyle _itemStyle(BuildContext context, bool selected) {
    final colors = context.tioColors;
    return TextStyle(
      fontSize: selected
          ? TioWheelPickerTokens.selectedFontSize
          : TioFontSize.size16,
      fontWeight: selected ? TioFontWeight.w800 : TioFontWeight.w500,
      color: selected
          ? colors.textPrimary
          : colors.textSecondary.withAlpha(TioAlpha.alpha90),
    );
  }

  Widget _item(
    BuildContext context,
    String label,
    bool selected, {
    Key? key,
  }) =>
      Center(
        child: Text(
          label,
          key: key,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _itemStyle(context, selected),
        ),
      );

  Widget _header(BuildContext context, String label) => Center(
        child: Text(
          label,
          style: TextStyle(
            color: context.tioColors.textSecondary,
            fontSize: TioFontSize.size12,
            fontWeight: TioFontWeight.w600,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final maximum = _date(widget.maximumDate);
    final minimum = widget.minimumDate == null
        ? null
        : _date(widget.minimumDate!);
    final dateIndex = _calendarDaysBetween(maximum, _date(_selected));
    final dateCount = minimum == null
        ? null
        : _calendarDaysBetween(maximum, minimum) + 1;
    final hourIndex = (_selected.hour + 11) % 12;
    final minuteIndex = _selected.minute;
    final periodIndex = _selected.hour >= 12 ? 1 : 0;
    final localizations = MaterialLocalizations.of(context);

    return Column(
      key: const ValueKey('tio-date-time-wheel-picker'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(flex: 3, child: _header(context, 'Date')),
            Expanded(flex: 2, child: _header(context, 'Hour')),
            Expanded(flex: 2, child: _header(context, 'Minute')),
            Expanded(flex: 2, child: _header(context, 'AM/PM')),
          ],
        ),
        const SizedBox(height: TioSpacing.xs),
        TioWheelPickerFrame(
          selectionPillKey:
              const ValueKey('tio-date-time-wheel-selection-pill'),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TioWheelPickerColumn(
                  key: const ValueKey('tio-date-time-wheel-date'),
                  selectedIndex: dateIndex,
                  itemCount: dateCount,
                  syncRevision: _syncRevision,
                  semanticLabel: 'Date',
                  semanticValue: localizations.formatMediumDate(_selected),
                  onSelectedItemChanged: _changeDate,
                  itemBuilder: (context, index, selected) {
                    final date = DateTime(
                      maximum.year,
                      maximum.month,
                      maximum.day - index,
                    );
                    final label = widget.today != null &&
                            _sameDate(date, widget.today!)
                        ? 'Today'
                        : localizations.formatShortMonthDay(date);
                    return _item(
                      context,
                      label,
                      selected,
                      key: selected
                          ? const ValueKey('tio-date-time-date-selected')
                          : null,
                    );
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: TioWheelPickerColumn(
                  key: const ValueKey('tio-date-time-wheel-hour'),
                  selectedIndex: hourIndex,
                  itemCount: 12,
                  looping: true,
                  syncRevision: _syncRevision,
                  semanticLabel: 'Hour',
                  semanticValue: '${hourIndex + 1}',
                  onSelectedItemChanged: _changeHour,
                  itemBuilder: (context, index, selected) => _item(
                    context,
                    '${index + 1}',
                    selected,
                    key: selected
                        ? const ValueKey('tio-date-time-hour-selected')
                        : null,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TioWheelPickerColumn(
                  key: const ValueKey('tio-date-time-wheel-minute'),
                  selectedIndex: minuteIndex,
                  itemCount: 60,
                  looping: true,
                  syncRevision: _syncRevision,
                  semanticLabel: 'Minute',
                  semanticValue: minuteIndex.toString().padLeft(2, '0'),
                  onSelectedItemChanged: _changeMinute,
                  itemBuilder: (context, index, selected) => _item(
                    context,
                    index.toString().padLeft(2, '0'),
                    selected,
                    key: selected
                        ? const ValueKey('tio-date-time-minute-selected')
                        : null,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TioWheelPickerColumn(
                  key: const ValueKey('tio-date-time-wheel-period'),
                  selectedIndex: periodIndex,
                  itemCount: 2,
                  looping: true,
                  syncRevision: _syncRevision,
                  semanticLabel: 'AM or PM',
                  semanticValue: periodIndex == 0 ? 'AM' : 'PM',
                  onSelectedItemChanged: _changePeriod,
                  itemBuilder: (context, index, selected) => _item(
                    context,
                    index == 0 ? 'AM' : 'PM',
                    selected,
                    key: selected
                        ? const ValueKey('tio-date-time-period-selected')
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
