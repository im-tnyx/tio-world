import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme_controller.dart';

final appThemeControllerProvider =
    ChangeNotifierProvider<AppThemeController>((ref) {
  throw StateError(
    'AppThemeController must be overridden at the app composition boundary.',
  );
});
