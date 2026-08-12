import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_mode/app_mode.dart';
import 'app/bootstrap.dart';

void main() {
  final appModeController =
      AppModeController(SharedPreferencesAppModePreference());

  bootstrap(
    () => AppModeBootstrap(
      controller: appModeController,
      child: ProviderScope(
        overrides: [
          appModeControllerProvider.overrideWith((ref) => appModeController)
        ],
        child: const TioApp(),
      ),
    ),
  );
}
