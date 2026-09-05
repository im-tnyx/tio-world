import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_settings/settings.dart';

import 'calendar_preferences_controller.dart';

/// Settings-owned, device-local Calendar Preferences.
final calendarPreferencesRepositoryProvider =
    Provider<CalendarPreferencesRepository>(
  (ref) => SharedPreferencesCalendarPreferencesRepository(),
);

final calendarPreferencesControllerProvider =
    ChangeNotifierProvider<CalendarPreferencesController>((ref) {
  final controller = CalendarPreferencesController(
    ref.watch(calendarPreferencesRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// The single effective week start every calendar surface reads.
///
/// Features watch this rather than the controller so that a screen cannot
/// reach the preference itself, let alone persist one of its own.
final resolvedFirstDayOfWeekProvider = Provider<int>((ref) {
  return ref.watch(calendarPreferencesControllerProvider).resolvedFirstDayOfWeek;
});
