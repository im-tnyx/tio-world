import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P1 Splash/bootstrap navigation ownership', () {
    test('Splash stays presentation-only', () {
      final splashSource = File(
        '../features/splash/lib/src/presentation/screen/splash_screen.dart',
      ).readAsStringSync();

      expect(splashSource, isNot(contains('onCheckInitialDestination')));
      expect(splashSource, isNot(contains('context.go(')));
      expect(splashSource, isNot(contains('.timeout(')));
      expect(splashSource, isNot(contains("package:go_router/go_router.dart")));
      expect(splashSource, isNot(contains('AppRoutes.auth.path')));
    });

    test('app router remains the startup destination authority', () {
      final routerSource = File('lib/app/router.dart').readAsStringSync();

      expect(
        routerSource,
        contains('initialLocation: AppRoutes.splash.path'),
      );
      expect(routerSource, contains('appSessionBootstrapRedirect('));
      expect(
        routerSource,
        contains('appSessionBootstrapController.refresh()'),
      );
      expect(routerSource, contains('AppSessionBootstrapFailure'));
    });
  });
}
