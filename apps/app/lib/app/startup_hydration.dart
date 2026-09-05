import 'app_mode/app_mode_controller.dart';
import 'app_theme_controller.dart';
import 'calendar_preferences_controller.dart';
import 'onboarding/onboarding_status_controller.dart';

Future<void> hydrateStartupControllers({
  required AppModeController appModeController,
  required OnboardingStatusController onboardingStatusController,
  required AppThemeController appThemeController,
  required CalendarPreferencesController calendarPreferencesController,
}) async {
  final appModeLoad = appModeController.load();
  final appThemeLoad = appThemeController.load();
  // Read alongside the theme so the first calendar frame is already laid out
  // from the saved week start. Loading it lazily would draw a Monday week and
  // then reshuffle it under a Sunday reader.
  final calendarPreferencesLoad = calendarPreferencesController.load();

  await appModeLoad;

  await Future.wait([
    onboardingStatusController.load(),
    appThemeLoad,
    calendarPreferencesLoad,
  ]);
}
