import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

/// Which day the Meal Diary is showing.
///
/// This is Nutrition's thin adapter over the reusable core calendar. Nutrition
/// owns the selected date and the diary's date policy; the calendar owns only
/// how dates are rendered and navigated.
///
/// Deliberately absent here: any week-start preference. First day of week is
/// one app-wide Calendar Preferences value, so a `nutritionFirstDayOfWeek`
/// would be exactly the duplication that ownership rule exists to prevent.
class MealDiaryDateController extends ChangeNotifier {
  MealDiaryDateController({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _observedToday = localToday;
    _selectedDate = _observedToday;
  }

  /// How far back the diary lets the user navigate.
  ///
  /// A bounded window rather than an open-ended past, because an unbounded
  /// strip has no meaningful start. Once real logging history exists, this
  /// should follow that history instead of a fixed span.
  static const int historyWindowDays = 365;

  final DateTime Function() _clock;
  final TioDateCalendarController calendarController =
      TioDateCalendarController();
  late DateTime _selectedDate;

  /// The local day this controller last told its listeners about. Reading the
  /// clock in a getter is not enough on its own: nothing rebuilds merely
  /// because midnight passed, so the diary would keep offering yesterday as
  /// the latest selectable day until some unrelated rebuild happened.
  late DateTime _observedToday;
  bool _isTodayVisible = true;

  /// Today in the device's own local date terms.
  ///
  /// Read through the clock on every access so a session that crosses midnight
  /// does not keep yesterday as today. This is the seam a canonical local-date
  /// and timezone resolver replaces later; nothing below it reads the clock.
  DateTime get localToday {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get selectedDate => _selectedDate;

  /// Whether the diary is already showing the current local day.
  bool get isOnToday => _selectedDate == localToday;

  /// Whether the active calendar page's primary week/month contains Today.
  bool get isTodayVisible => _isTodayVisible;

  /// The Today action is needed when either selection or viewport is away.
  bool get shouldShowTodayAction => !isOnToday || !_isTodayVisible;

  /// Earliest reachable diary day.
  DateTime get minDate {
    final today = localToday;
    return DateTime(today.year, today.month, today.day - historyWindowDays);
  }

  /// The diary records what was eaten, so it stops at today. The core calendar
  /// has no such rule of its own — a future planning surface passes its own
  /// horizon instead.
  DateTime get maxDate => localToday;

  bool isSelectable(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(minDate) && !day.isAfter(maxDate);
  }

  void select(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (!isSelectable(day) || day == _selectedDate) return;
    _selectedDate = day;
    notifyListeners();
  }

  void updateVisibleDateRange(DateTime firstDate, DateTime lastDate) {
    final today = localToday;
    final start = DateTime(firstDate.year, firstDate.month, firstDate.day);
    final end = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final isVisible = !today.isBefore(start) && !today.isAfter(end);
    if (_isTodayVisible == isVisible) return;
    _isTodayVisible = isVisible;
    notifyListeners();
  }

  /// Re-reads the local day and notifies if it has rolled over.
  ///
  /// Safe to call as often as the host likes — it is a no-op on the same day.
  /// The selected date is deliberately left alone: someone reading Tuesday's
  /// diary at midnight should still be reading Tuesday's diary at 00:01. Only
  /// what counts as today, and therefore the range end, moves.
  ///
  /// The page drives this from the app lifecycle rather than from a timer. A
  /// long-lived timer would keep this controller alive behind an unmounted
  /// screen for the rest of the day, so the rollover is picked up when the app
  /// comes back to the foreground. An app left open and untouched across local
  /// midnight therefore updates on the next resume or interaction.
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
}

final mealDiaryDateControllerProvider =
    ChangeNotifierProvider.autoDispose<MealDiaryDateController>(
  (ref) => MealDiaryDateController(),
);
