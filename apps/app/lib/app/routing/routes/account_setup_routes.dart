import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_splash/splash.dart';

List<RouteBase> buildAccountSetupRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required ProfileAccountRepository? Function() profileAccountRepository,
  required AccountSetupRepository? Function() accountSetupRepository,
  required AuthSessionState? Function() authSessionState,
  required Future<void> Function() onExitRequested,
  required Future<void> Function() onCompleted,
}) {
  return [
    GoRoute(
      path: AppRoutes.accountSetup.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final usernameRepository = profileAccountRepository();
        final setupRepository = accountSetupRepository();
        if (usernameRepository == null || setupRepository == null) {
          return const SplashScreen(
            failureMessage: 'Account setup is unavailable right now.',
          );
        }
        final authState = authSessionState();
        final currentPhone = authState is AuthSessionAuthenticated
            ? authState.session.phone?.trim()
            : null;
        return AccountSetupFlowPage(
          usernameRepository: usernameRepository,
          accountSetupRepository: setupRepository,
          hasTrustedPhoneIdentity:
              currentPhone != null && currentPhone.isNotEmpty,
          onExitRequested: onExitRequested,
          onCompleted: onCompleted,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.usernameSetup.path,
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) => AppRoutes.accountSetup.path,
    ),
  ];
}
