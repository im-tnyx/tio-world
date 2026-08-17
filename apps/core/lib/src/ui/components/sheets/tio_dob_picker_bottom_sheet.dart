import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import '../buttons/tio_button.dart';

/// Shows the custom 3-column (Day, Month, Year) Date of Birth picker bottom sheet.
Future<DateTime?> showTioDobPickerBottomSheet({
  required BuildContext context,
  DateTime? initialDate,
  int startYear = 1950,
  int? endYear,
}) {
  final now = DateTime.now();
  final resolvedEndYear = endYear ?? (now.year - 12); // Minimum 12-13+ years for fitness
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
    final colors = TioTheme.colors(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TioRadius.extraLarge),
        ),
        border: Border.all(
          color: colors.outlineStrong.withAlpha(25),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.large,
            TioSpacing.large,
            TioSpacing.large,
            TioSpacing.extraLarge,
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
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textSecondary,
                      size: 24,
                    ),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Subtitle ──
              Text(
                'We use this data to help personalize Tio for you',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: TioSpacing.large),

              // ── Column Headers: Day, Month, Year ──
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Day',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Reusable Pure Wheel Picker ──
              TioDobWheelPicker(
                initialDate: widget.initialDate,
                startYear: widget.startYear,
                endYear: widget.endYear,
                onChanged: (date) => _selectedDate = date,
              ),

              const SizedBox(height: TioSpacing.large),

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
  bool _isSyncingControllers = false;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

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

    final initialYearIndex = _years.indexOf(_selectedYear);

    _dayController = FixedExtentScrollController(
      initialItem: (_selectedDay - 1).clamp(0, 30),
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonthIndex.clamp(0, 11),
    );
    _yearController = FixedExtentScrollController(
      initialItem: initialYearIndex >= 0 ? initialYearIndex : 0,
    );
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
        _syncControllers();
      }
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _syncControllers() {
    final dayIndex = (_selectedDay - 1).clamp(0, 30);
    final monthIndex = _selectedMonthIndex.clamp(0, 11);
    final yearIndex = _years.indexOf(_selectedYear);

    _isSyncingControllers = true;
    try {
      if (_dayController.hasClients && _dayController.selectedItem != dayIndex) {
        _dayController.jumpToItem(dayIndex);
      }
      if (_monthController.hasClients &&
          _monthController.selectedItem != monthIndex) {
        _monthController.jumpToItem(monthIndex);
      }
      if (_yearController.hasClients &&
          yearIndex >= 0 &&
          _yearController.selectedItem != yearIndex) {
        _yearController.jumpToItem(yearIndex);
      }
    } finally {
      _isSyncingControllers = false;
    }
  }

  void _onWheelChanged() {
    if (_isSyncingControllers) return;

    HapticFeedback.selectionClick();
    final dayIndex =
        _dayController.hasClients ? _dayController.selectedItem : 0;
    final monthIndex =
        _monthController.hasClients ? _monthController.selectedItem : 0;
    final yearIndex =
        _yearController.hasClients ? _yearController.selectedItem : 0;

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
    final colors = TioTheme.colors(context);
    final maxDays = _daysInMonth(_selectedYear, _selectedMonthIndex + 1);

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Selection Highlight Pill (Matches Height & Weight Wheels)
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface.withAlpha(200),
              borderRadius: BorderRadius.circular(TioRadius.medium),
            ),
          ),

          // 3 Columns Row (Day | Month | Year)
          Row(
            children: [
              // ── Day Wheel ──
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: _dayController,
                  itemExtent: 44,
                  perspective: 0.004,
                  diameterRatio: 1.3,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (_) => _onWheelChanged(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: maxDays,
                    builder: (context, index) {
                      final day = index + 1;
                      final isSelected = day == _selectedDay;

                      return Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: isSelected ? 22 : 17,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textMuted.withAlpha(120),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Month Wheel ──
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: _monthController,
                  itemExtent: 44,
                  perspective: 0.004,
                  diameterRatio: 1.3,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (_) => _onWheelChanged(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _months.length,
                    builder: (context, index) {
                      final isSelected = index == _selectedMonthIndex;

                      return Center(
                        child: Text(
                          _months[index],
                          style: TextStyle(
                            fontSize: isSelected ? 22 : 17,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textMuted.withAlpha(120),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Year Wheel ──
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: _yearController,
                  itemExtent: 44,
                  perspective: 0.004,
                  diameterRatio: 1.3,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (_) => _onWheelChanged(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _years.length,
                    builder: (context, index) {
                      final year = _years[index];
                      final isSelected = year == _selectedYear;

                      return Center(
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: isSelected ? 22 : 17,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textMuted.withAlpha(120),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
