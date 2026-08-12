import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_mode_controller.dart';

final appModeControllerProvider =
    ChangeNotifierProvider<AppModeController>((ref) {
  throw StateError(
      'AppModeController must be overridden at the app composition boundary.');
});
