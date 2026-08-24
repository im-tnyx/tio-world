import 'app_mode/app_mode_controller.dart';
import 'app_theme_controller.dart';
import 'onboarding/onboarding_status_controller.dart';

Future<void> hydrateStartupControllers({
  required AppModeController appModeController,
  required OnboardingStatusController onboardingStatusController,
  required AppThemeController appThemeController,
}) async {
  final appModeLoad = appModeController.load();
  final appThemeLoad = appThemeController.load();

  await appModeLoad;

  await Future.wait([
    onboardingStatusController.load(),
    appThemeLoad,
  ]);
}
