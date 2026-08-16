import 'package:tio_core/core.dart';

import 'app_session_bootstrap_state.dart';

final _unauthenticatedPublicPaths = <String>{
  AppRoutes.auth.path,
  AppRoutes.login.path,
  AppRoutes.emailLogin.path,
  AppRoutes.emailSignup.path,
  AppRoutes.forgotPassword.path,
};

final _readyEntryPaths = <String>{
  AppRoutes.splash.path,
  AppRoutes.auth.path,
  AppRoutes.login.path,
  AppRoutes.emailLogin.path,
  AppRoutes.emailSignup.path,
  AppRoutes.forgotPassword.path,
  AppRoutes.onboarding.path,
};

String? appSessionBootstrapRedirect({
  required String path,
  required AppSessionBootstrapState state,
}) {
  switch (state) {
    case AppSessionBootstrapLoading():
    case AppSessionBootstrapFailure():
      return path == AppRoutes.splash.path ? null : AppRoutes.splash.path;
    case AppSessionBootstrapUnauthenticated():
      if (path == AppRoutes.splash.path) return AppRoutes.auth.path;
      return _unauthenticatedPublicPaths.contains(path)
          ? null
          : AppRoutes.auth.path;
    case AppSessionBootstrapRequiresOnboarding():
      if (path == AppRoutes.onboarding.path ||
          path == AppRoutes.congratulations.path) {
        return null;
      }
      return AppRoutes.onboarding.path;
    case AppSessionBootstrapReady():
      return _readyEntryPaths.contains(path) ? FeatureRoutes.home.path : null;
  }
}
