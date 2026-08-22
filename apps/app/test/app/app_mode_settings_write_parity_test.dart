import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('Settings save failure preserves current mode and shows retry error',
      (tester) async {
    final preference = _FakeAppModePreference(AppMode.workout);
    final controller = AppModeController(preference);
    await controller.load();
    final repository = _RecordingAppPreferencesRepository(
      error: StateError('remote write failed'),
    );
    controller.setAuthenticatedWriteRepository(repository);

    await tester.pumpWidget(
      _SettingsTestApp(
        child: AppModeSettingsPage(
          currentMode: AppMode.workout,
          onModeChanged: controller.select,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('app-mode-settings-nutrition')),
    );
    await tester.pump();
    await tester.tap(find.text('Save App Mode'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not update App Mode. Please try again.'),
      findsOneWidget,
    );
    expect(controller.selectedMode, AppMode.workout);
    expect(controller.activeDestinations, AppMode.workout.guidedDestinations);
    expect(preference.storedMode, AppMode.workout);
    expect(repository.updates, hasLength(1));
    expect(repository.updates.single.appMode, AppMode.nutrition);
  });

  testWidgets('Settings save publishes mode only after canonical success',
      (tester) async {
    final preference = _FakeAppModePreference(AppMode.workout);
    final controller = AppModeController(preference);
    await controller.load();
    final repository = _RecordingAppPreferencesRepository(
      onUpsert: (update) {
        expect(controller.selectedMode, AppMode.workout);
        expect(preference.storedMode, AppMode.workout);
        expect(update.appMode, AppMode.hybrid);
        expect(update.activeTabs, AppMode.hybrid.guidedDestinations);
      },
    );
    controller.setAuthenticatedWriteRepository(repository);

    await tester.pumpWidget(
      _SettingsTestApp(
        child: AppModeSettingsPage(
          currentMode: AppMode.workout,
          onModeChanged: controller.select,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('app-mode-settings-hybrid')),
    );
    await tester.pump();
    await tester.tap(find.text('Save App Mode'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not update App Mode. Please try again.'),
      findsNothing,
    );
    expect(repository.updates, hasLength(1));
    expect(repository.updates.single.appMode, AppMode.hybrid);
    expect(
      repository.updates.single.activeTabs,
      AppMode.hybrid.guidedDestinations,
    );
    expect(controller.selectedMode, AppMode.hybrid);
    expect(controller.activeDestinations, AppMode.hybrid.guidedDestinations);
    expect(preference.storedMode, AppMode.hybrid);
  });
}

class _SettingsTestApp extends StatelessWidget {
  const _SettingsTestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, appChild) => TioTheme(
        config: const TioThemeConfig(),
        child: appChild ?? const SizedBox.shrink(),
      ),
      home: child,
    );
  }
}

class _RecordingAppPreferencesRepository implements AppPreferencesRepository {
  _RecordingAppPreferencesRepository({this.onUpsert, this.error});

  final void Function(AppPreferencesUpdate update)? onUpsert;
  final Object? error;
  final List<AppPreferencesUpdate> updates = [];

  @override
  Future<AppPreferencesState> read() async =>
      const AppPreferencesState.missing();

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    updates.add(preferences);
    onUpsert?.call(preferences);
    if (error case final value?) throw value;
  }
}

class _FakeAppModePreference implements AppModePreference {
  _FakeAppModePreference(this.storedMode);

  AppMode? storedMode;

  @override
  Future<void> clear() async => storedMode = null;

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async => storedMode = mode;
}
