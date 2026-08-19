import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_core/core.dart';

void main() {
  group('appSessionBootstrapRedirect', () {
    test('loading and failure stay on Splash', () {
      expect(
        appSessionBootstrapRedirect(
          path: FeatureRoutes.home.path,
          state: const AppSessionBootstrapLoading(),
        ),
        AppRoutes.splash.path,
      );
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.splash.path,
          state: const AppSessionBootstrapLoading(),
        ),
        isNull,
      );
      expect(
        appSessionBootstrapRedirect(
          path: FeatureRoutes.home.path,
          state: AppSessionBootstrapFailure(StateError('network')),
        ),
        AppRoutes.splash.path,
      );
    });

    test('unauthenticated users may choose App Mode but not enter protected setup', () {
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.appModeSetup.path,
          state: const AppSessionBootstrapUnauthenticated(),
        ),
        isNull,
      );

      for (final protectedPath in [
        AppRoutes.accountSetup.path,
        AppRoutes.usernameSetup.path,
        AppRoutes.onboarding.path,
        FeatureRoutes.home.path,
      ]) {
        expect(
          appSessionBootstrapRedirect(
            path: protectedPath,
            state: const AppSessionBootstrapUnauthenticated(),
          ),
          AppRoutes.auth.path,
          reason: protectedPath,
        );
      }

      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.login.path,
          state: const AppSessionBootstrapUnauthenticated(),
        ),
        isNull,
      );
    });

    test('incomplete account is gated to generic Account Setup boundary', () {
      const state = AppSessionBootstrapRequiresAccountSetup(userId: 'user-a');
      expect(
        appSessionBootstrapRedirect(
          path: FeatureRoutes.home.path,
          state: state,
        ),
        AppRoutes.accountSetup.path,
      );
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.appModeSetup.path,
          state: state,
        ),
        AppRoutes.accountSetup.path,
      );
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.onboarding.path,
          state: state,
        ),
        AppRoutes.accountSetup.path,
      );
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.usernameSetup.path,
          state: state,
        ),
        AppRoutes.accountSetup.path,
      );
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.accountSetup.path,
          state: state,
        ),
        isNull,
      );
    });

    test('Account Setup complete authenticated users are gated to onboarding', () {
      const state = AppSessionBootstrapRequiresOnboarding(userId: 'user-a');
      expect(
        appSessionBootstrapRedirect(
          path: FeatureRoutes.home.path,
          state: state,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.appModeSetup.path,
          state: state,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.accountSetup.path,
          state: state,
        ),
        AppRoutes.onboarding.path,
      );
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.onboarding.path,
          state: state,
        ),
        isNull,
      );
    });

    test('ready returning users leave all setup entry routes for Home', () {
      const state = AppSessionBootstrapReady(userId: 'user-a');
      for (final path in [
        AppRoutes.splash.path,
        AppRoutes.auth.path,
        AppRoutes.appModeSetup.path,
        AppRoutes.login.path,
        AppRoutes.emailLogin.path,
        AppRoutes.emailSignup.path,
        AppRoutes.accountSetup.path,
        AppRoutes.usernameSetup.path,
        AppRoutes.onboarding.path,
      ]) {
        expect(
          appSessionBootstrapRedirect(path: path, state: state),
          FeatureRoutes.home.path,
          reason: path,
        );
      }

      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.congratulations.path,
          state: state,
        ),
        isNull,
      );
      expect(
        appSessionBootstrapRedirect(
          path: FeatureRoutes.home.path,
          state: state,
        ),
        isNull,
      );
    });
  });
}
