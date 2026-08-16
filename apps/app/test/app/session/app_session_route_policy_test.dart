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

    test('unauthenticated users can use auth routes but not protected routes', () {
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.splash.path,
          state: const AppSessionBootstrapUnauthenticated(),
        ),
        AppRoutes.auth.path,
      );
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.login.path,
          state: const AppSessionBootstrapUnauthenticated(),
        ),
        isNull,
      );
      expect(
        appSessionBootstrapRedirect(
          path: FeatureRoutes.home.path,
          state: const AppSessionBootstrapUnauthenticated(),
        ),
        AppRoutes.auth.path,
      );
    });

    test('incomplete authenticated users are gated to onboarding', () {
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
          path: AppRoutes.login.path,
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
      expect(
        appSessionBootstrapRedirect(
          path: AppRoutes.congratulations.path,
          state: state,
        ),
        isNull,
      );
    });

    test('ready returning users leave bootstrap/auth entry routes for Home', () {
      const state = AppSessionBootstrapReady(userId: 'user-a');
      for (final path in [
        AppRoutes.splash.path,
        AppRoutes.auth.path,
        AppRoutes.login.path,
        AppRoutes.emailLogin.path,
        AppRoutes.emailSignup.path,
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
