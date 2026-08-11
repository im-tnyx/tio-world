import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/app_mode/app_mode.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appModeController =
      AppModeController(SharedPreferencesAppModePreference());
  await appModeController.load();

  bootstrap(
    () => ProviderScope(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => appModeController)
      ],
      child: const TioApp(),
    ),
  );
}
