import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

/// Workout's thin caller-side adapter over the shared Core date calendar.
///
/// TNYX-255 owns navigation state only. Workout domain-backed schedule,
/// completion, plan and history state belong to later slices.
class WorkoutDateController extends ChangeNotifier {
  WorkoutDateController({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _observedToday = localToday;
    _selectedDate = _observedToday;
    _visibleMonth = DateTime(_observedToday.year, _observedToday.month);
  }

  /// Temporary navigation-only horizon for the pre-W1 shell.
  ///
  /// This is not Workout schedule truth. W2 may replace the horizon once the
  /// canonical Workout planning contract exists.
  static const int provisionalNavigationWindowYears = 1;

  final DateTime Function() _clock;
  final TioDateCalendarController calendarController =
      TioDateCalendarController();

  late DateTime _selectedDate;
  late DateTime _observedToday;
  late DateTime _visibleMonth;
  bool _isTodayVisible = true;
  DateTime? _visibleFirstDate;
  DateTime? _visibleLastDate;

  DateTime get localToday {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get selectedDate => _selectedDate;

  bool get isOnToday => _selectedDate == localToday;

  DateTime get visibleMonth => _visibleMonth;

  DateTime? get visibleFirstDate => _visibleFirstDate;

  DateTime? get visibleLastDate => _visibleLastDate;

  bool get isTodayVisible => _isTodayVisible;

  /// Match Meal Diary navigation semantics: the action is useful if either the
  /// selected date or the viewport has moved away from Today.
  bool get shouldShowTodayAction => !isOnToday || !_isTodayVisible;

  DateTime get minDate {
    final today = localToday;
    return DateTime(
      today.year - provisionalNavigationWindowYears,
      today.month,
      today.day,
    );
  }

  DateTime get maxDate {
    final today = localToday;
    return DateTime(
      today.year + provisionalNavigationWindowYears,
      today.month,
      today.day,
    );
  }

  bool isSelectable(DateTime date) {
    final day = _dateOnly(date);
    return !day.isBefore(minDate) && !day.isAfter(maxDate);
  }

  void select(DateTime date) {
    final day = _dateOnly(date);
    if (!isSelectable(day) || day == _selectedDate) return;
    _selectedDate = day;
    notifyListeners();
  }

  void updateVisibleDateRange(DateTime firstDate, DateTime lastDate) {
    final today = localToday;
    final start = _dateOnly(firstDate);
    final end = _dateOnly(lastDate);
    final isVisible = !today.isBefore(start) && !today.isAfter(end);

    // A compact week may span two months. Use its midpoint so the centred
    // month/year describes most of the page the user is actually viewing.
    final spanDays =
        DateTime.utc(end.year, end.month, end.day)
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inDays;
    final midpoint =
        DateTime(start.year, start.month, start.day + spanDays ~/ 2);
    final month = DateTime(midpoint.year, midpoint.month);

    final changed = _isTodayVisible != isVisible ||
        _visibleMonth != month ||
        _visibleFirstDate != start ||
        _visibleLastDate != end;
    if (!changed) return;

    _isTodayVisible = isVisible;
    _visibleMonth = month;
    _visibleFirstDate = start;
    _visibleLastDate = end;
    notifyListeners();
  }

  Duration get durationUntilNextLocalMidnight {
    final now = _clock();
    return DateTime(now.year, now.month, now.day + 1).difference(now);
  }

  /// Refreshes caller-owned Today truth after midnight/app resume.
  ///
  /// Selection deliberately remains where the user left it; after rollover the
  /// Today action becomes available and can bring both selection and viewport
  /// to the new current day.
  void refreshLocalDate() {
    final today = localToday;
    if (_observedToday == today) return;
    _observedToday = today;
    notifyListeners();
  }

  void selectToday() {
    final today = localToday;
    final selectionChanged = _selectedDate != today;
    if (selectionChanged) _selectedDate = today;
    calendarController.jumpToDate(today);
    if (selectionChanged) notifyListeners();
  }

  @override
  void dispose() {
    calendarController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

final workoutDateControllerProvider =
    ChangeNotifierProvider.autoDispose<WorkoutDateController>(
  (ref) => WorkoutDateController(),
);
