import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

List<ShellTab> guidedShellTabs(AppMode mode) {
  return mode.guidedDestinations
      .map(ShellTab.fromDestination)
      .toList(growable: false);
}

String? appModeRedirect(
    {required String path, required AppMode? selectedMode}) {
  final modeRequiredPaths = <String>{
    FeatureRoutes.home.path,
    FeatureRoutes.workout.path,
    FeatureRoutes.nutrition.path,
    FeatureRoutes.ai.path,
    FeatureRoutes.progress.path,
    AppRoutes.profile.path,
    AppRoutes.profileAvatar.path,
    AppRoutes.settings.path,
  };

  if (selectedMode == null) {
    return modeRequiredPaths.contains(path) ? AppRoutes.onboarding.path : null;
  }

  if (path == AppRoutes.onboarding.path) return FeatureRoutes.home.path;

  final allowedPaths =
      guidedShellTabs(selectedMode).map((tab) => tab.route.path).toSet();
  final isShellPath =
      shellBranchRegistry.any((branch) => branch.route.path == path);
  if (isShellPath && !allowedPaths.contains(path)) {
    return FeatureRoutes.home.path;
  }

  return null;
}
