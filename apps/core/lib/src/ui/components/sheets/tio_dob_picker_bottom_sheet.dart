import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../buttons/tio_button.dart';
import '../pickers/tio_wheel_picker.dart';

/// Shows the custom 3-column (Day, Month, Year) Date of Birth picker bottom sheet.
Future<DateTime?> showTioDobPickerBottomSheet({
  required BuildContext context,
  DateTime? initialDate,
  int startYear = 1950,
  int? endYear,
}) {
  final now = DateTime.now();
  final resolvedEndYear =
      endYear ?? (now.year - 12); // Minimum 12-13+ years for fitness
  final resolvedInitial = initialDate ?? DateTime(2000, 1, 1);
  final clampedInitial = DateTime(
    resolvedInitial.year.clamp(startYear, resolvedEndYear),
    resolvedInitial.month,
    resolvedInitial.day,
  );

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => TioDobPickerBottomSheet(
      initialDate: clampedInitial,
      startYear: startYear,
      endYear: resolvedEndYear,
    ),
  );
}

/// Standalone / Reusable Bottom Sheet for Settings & Personal Info
class TioDobPickerBottomSheet extends StatefulWidget {
  const TioDobPickerBottomSheet({
    required this.initialDate,
    this.startYear = 1950,
    required this.endYear,
    super.key,
  });

  final DateTime initialDate;
  final int startYear;
  final int endYear;

  @override
  State<TioDobPickerBottomSheet> createState() =>
      _TioDobPickerBottomSheetState();
}

class _TioDobPickerBottomSheetState extends State<TioDobPickerBottomSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TioRadius.xl),
        ),
        border: Border.all(
          color: colors.outlineStrong.withAlpha(TioAlpha.alpha25),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.lg,
            TioSpacing.lg,
            TioSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Title & Close Button ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Date of Birth',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size22,
                      letterSpacing: TioLetterSpacing.negative02,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textSecondary,
                      size: TioSize.dp24,
                    ),
                    splashRadius: TioSize.dp20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: TioSize.dp6),

              // ── Subtitle ──
              Text(
                'We use this data to help personalize Tio for you',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: TioFontSize.size14,
                  fontWeight: TioFontWeight.w400,
                ),
              ),

              const SizedBox(height: TioSpacing.lg),

              // ── Column Headers: Day, Month, Year ──
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Day',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size17,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Month',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size17,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Year',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: TioSpacing.md),

              // ── Reusable Pure Wheel Picker ──
              TioDobWheelPicker(
                initialDate: widget.initialDate,
                startYear: widget.startYear,
                endYear: widget.endYear,
                onChanged: (date) => _selectedDate = date,
              ),

              const SizedBox(height: TioSpacing.lg),

              // ── Action Button: Save ──
              TioButton.primary(
                label: 'Save',
                expand: true,
                onPressed: () => Navigator.of(context).pop(_selectedDate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Single Canonical Reusable 3-Column Drum Wheel Picker ──
/// Used directly by Onboarding `AgeScreen` and by Settings `TioDobPickerBottomSheet`.
class TioDobWheelPicker extends StatefulWidget {
  const TioDobWheelPicker({
    required this.initialDate,
    required this.onChanged,
    this.startYear = 1950,
    required this.endYear,
    super.key,
  });

  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;
  final int startYear;
  final int endYear;

  @override
  State<TioDobWheelPicker> createState() => _TioDobWheelPickerState();
}

class _TioDobWheelPickerState extends State<TioDobWheelPicker> {
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late int _selectedDay;
  late int _selectedMonthIndex; // 0-indexed (0 = Jan, 11 = Dec)
  late int _selectedYear;

  late List<int> _years;

  @override
  void initState() {
    super.initState();
    _years = List.generate(
      widget.endYear - widget.startYear + 1,
      (i) => widget.startYear + i,
    );

    final init = widget.initialDate;
    _selectedDay = init.day;
    _selectedMonthIndex = init.month - 1;
    _selectedYear = init.year.clamp(widget.startYear, widget.endYear);

  }

  @override
  void didUpdateWidget(covariant TioDobWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      final init = widget.initialDate;
      if (init.year != _selectedYear ||
          init.month != (_selectedMonthIndex + 1) ||
          init.day != _selectedDay) {
        setState(() {
          _selectedYear = init.year.clamp(widget.startYear, widget.endYear);
          _selectedMonthIndex = (init.month - 1).clamp(0, 11);
          _selectedDay = init.day.clamp(
            1,
            _daysInMonth(_selectedYear, _selectedMonthIndex + 1),
          );
        });
      }
    }
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _onWheelChanged({int? dayIndex, int? monthIndex, int? yearIndex}) {
    dayIndex ??= _selectedDay - 1;
    monthIndex ??= _selectedMonthIndex;
    yearIndex ??= _years.indexOf(_selectedYear);
    final resolvedYear = (yearIndex >= 0 && yearIndex < _years.length)
        ? _years[yearIndex]
        : widget.startYear;
    final resolvedMonth = (monthIndex + 1).clamp(1, 12);
    final maxDays = _daysInMonth(resolvedYear, resolvedMonth);
    final resolvedDay = (dayIndex + 1).clamp(1, maxDays);

    setState(() {
      _selectedYear = resolvedYear;
      _selectedMonthIndex = monthIndex;
      _selectedDay = resolvedDay;
    });

    widget.onChanged(DateTime(resolvedYear, resolvedMonth, resolvedDay));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final maxDays = _daysInMonth(_selectedYear, _selectedMonthIndex + 1);

    return TioWheelPickerFrame(
      selectionPillKey: const ValueKey('tio-dob-wheel-selection-pill'),
      child: Row(
            children: [
              // ── Day Wheel ──
              Expanded(
                child: TioWheelPickerColumn(
                  selectedIndex: _selectedDay - 1,
                  itemCount: maxDays,
                  onSelectedItemChanged: (change) =>
                      _onWheelChanged(dayIndex: change.index),
                  itemBuilder: (context, index, isSelected) {
                      final day = index + 1;
                      return Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: isSelected
                                ? TioWheelPickerTokens.selectedFontSize
                                : TioFontSize.size17,
                            fontWeight: isSelected
                                ? TioFontWeight.w800
                                : TioFontWeight.w500,
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textMuted.withAlpha(TioAlpha.alpha120),
                          ),
                        ),
                      );
                  },
                ),
              ),

              // ── Month Wheel ──
              Expanded(
                child: TioWheelPickerColumn(
                  selectedIndex: _selectedMonthIndex,
                  itemCount: _months.length,
                  onSelectedItemChanged: (change) =>
                      _onWheelChanged(monthIndex: change.index),
                  itemBuilder: (context, index, isSelected) {
                      return Center(
                        child: Text(
                          _months[index],
                          style: TextStyle(
                            fontSize: isSelected
                                ? TioWheelPickerTokens.selectedFontSize
                                : TioFontSize.size17,
                            fontWeight: isSelected
                                ? TioFontWeight.w800
                                : TioFontWeight.w500,
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textMuted.withAlpha(TioAlpha.alpha120),
                          ),
                        ),
                      );
                  },
                ),
              ),

              // ── Year Wheel ──
              Expanded(
                child: TioWheelPickerColumn(
                  selectedIndex: _years.indexOf(_selectedYear),
                  itemCount: _years.length,
                  onSelectedItemChanged: (change) =>
                      _onWheelChanged(yearIndex: change.index),
                  itemBuilder: (context, index, isSelected) {
                      final year = _years[index];
                      return Center(
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: isSelected
                                ? TioWheelPickerTokens.selectedFontSize
                                : TioFontSize.size17,
                            fontWeight: isSelected
                                ? TioFontWeight.w800
                                : TioFontWeight.w500,
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textMuted.withAlpha(TioAlpha.alpha120),
                          ),
                        ),
                      );
                  },
                ),
              ),
            ],
      ),
    );
  }
}
