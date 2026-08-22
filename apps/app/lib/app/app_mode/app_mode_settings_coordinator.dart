import 'package:tio_shared/shared.dart';

import 'app_mode_controller.dart';

/// Coordinates authenticated Settings App Mode updates.
///
/// Canonical account preferences must commit before the runtime controller
/// publishes the new mode. The controller then refreshes its legacy local
/// preference as a best-effort cache of the already-accepted canonical state.
final class AppModeSettingsCoordinator {
  const AppModeSettingsCoordinator({
    required AppPreferencesRepository? appPreferencesRepository,
    required AppModeController appModeController,
  })  : _appPreferencesRepository = appPreferencesRepository,
        _appModeController = appModeController;

  final AppPreferencesRepository? _appPreferencesRepository;
  final AppModeController _appModeController;

  Future<void> changeMode(AppMode mode) async {
    final repository = _appPreferencesRepository;
    if (repository == null) {
      throw StateError(
        'Canonical App preferences are unavailable for Settings updates.',
      );
    }

    final update = AppPreferencesUpdate.guided(mode);
    await repository.upsert(update);
    await _appModeController.applyCanonicalUpdate(update);
  }
}
