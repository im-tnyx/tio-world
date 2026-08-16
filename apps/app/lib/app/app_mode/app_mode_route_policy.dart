import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

List<ShellTab> guidedShellTabs(AppMode mode) {
  return mode.guidedDestinations
      .map(ShellTab.fromDestination)
      .toList(growable: false);
}

String? appModeRedirect(
    {required String path,
    required AppMode? selectedMode,
    required OnboardingStatus onboardingStatus}) {
  final modeRequiredPaths = <String>{
    FeatureRoutes.home.path,
    FeatureRoutes.workout.path,
    FeatureRoutes.nutrition.path,
    FeatureRoutes.ai.path,
    FeatureRoutes.progress.path,
    AppRoutes.profile.path,
    AppRoutes.profileAvatar.path,
    AppRoutes.settings.path,
    AppRoutes.appSettings.path,
    AppRoutes.appModeSettings.path,
    AppRoutes.themeSettings.path,
  };

  final onboardingComplete = onboardingStatus == OnboardingStatus.completed;

  if (!onboardingComplete) {
    return modeRequiredPaths.contains(path) ? AppRoutes.onboarding.path : null;
  }

  if (path == AppRoutes.onboarding.path) return FeatureRoutes.home.path;

  final isShellPath =
      shellBranchRegistry.any((branch) => branch.route.path == path);

  if (selectedMode == null) {
    if (isShellPath && path != FeatureRoutes.home.path) {
      return FeatureRoutes.home.path;
    }
    return null;
  }

  final allowedPaths =
      guidedShellTabs(selectedMode).map((tab) => tab.route.path).toSet();
  if (isShellPath && !allowedPaths.contains(path)) {
    return FeatureRoutes.home.path;
  }

  return null;
}
