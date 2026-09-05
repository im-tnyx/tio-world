import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

List<ShellTab> shellTabsForDestinations(
  Iterable<AppDestination> destinations,
) {
  return destinations
      .map(ShellTab.fromDestination)
      .toList(growable: false);
}

List<ShellTab> guidedShellTabs(AppMode mode) {
  return shellTabsForDestinations(mode.guidedDestinations);
}

String? appModeRedirect({
  required String path,
  required AppMode? selectedMode,
  required OnboardingStatus onboardingStatus,
  List<AppDestination>? activeDestinations,
}) {
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
    AppRoutes.calendarSettings.path,
  };

  final onboardingComplete = onboardingStatus == OnboardingStatus.completed;

  if (!onboardingComplete) {
    return modeRequiredPaths.contains(path) ? AppRoutes.onboarding.path : null;
  }

  if (path == AppRoutes.onboarding.path) return FeatureRoutes.home.path;

  final isShellPath =
      shellBranchRegistry.any((branch) => branch.route.path == path);

  if (selectedMode == null) {
    final compatibilityPaths = missingModeCompatibilityShellTabs
        .map((tab) => tab.route.path)
        .toSet();
    if (isShellPath && !compatibilityPaths.contains(path)) {
      return FeatureRoutes.home.path;
    }
    return null;
  }

  final effectiveDestinations =
      activeDestinations ?? selectedMode.guidedDestinations;
  final allowedTabs = shellTabsForDestinations(effectiveDestinations);
  final allowedPaths = allowedTabs.map((tab) => tab.route.path).toSet();
  final fallbackPath = allowedTabs.isEmpty
      ? FeatureRoutes.home.path
      : allowedTabs.first.route.path;

  if (isShellPath && !allowedPaths.contains(path)) {
    return fallbackPath;
  }

  return null;
}
