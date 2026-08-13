import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_mode/app_mode.dart';
import 'app/app_theme.dart';
import 'app/bootstrap.dart';

void main() {
  final appModeController =
      AppModeController(SharedPreferencesAppModePreference());
  final appThemeController =
      AppThemeController(SharedPreferencesAppThemePreference());

  bootstrap(
    () => AppThemeBootstrap(
      controller: appThemeController,
      child: AppModeBootstrap(
        controller: appModeController,
        child: ProviderScope(
          overrides: [
            appModeControllerProvider.overrideWith((ref) => appModeController),
            appThemeControllerProvider
                .overrideWith((ref) => appThemeController),
          ],
          child: const TioApp(),
        ),
      ),
    ),
  );
}
