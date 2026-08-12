import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('mode change redirects an active hidden branch to Home',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    router.go(FeatureRoutes.nutrition.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        FeatureRoutes.nutrition.path);
    expect(find.text('Nutrition'), findsWidgets);

    await controller.select(AppMode.workout);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        FeatureRoutes.home.path);
    expect(find.text('Nutrition'), findsNothing);
    expect(find.text('Home'), findsWidgets);
  });
}

class _MemoryAppModePreference implements AppModePreference {
  _MemoryAppModePreference(this.mode);

  AppMode? mode;

  @override
  Future<void> clear() async => mode = null;

  @override
  Future<AppMode?> read() async => mode;

  @override
  Future<void> write(AppMode mode) async => this.mode = mode;
}
