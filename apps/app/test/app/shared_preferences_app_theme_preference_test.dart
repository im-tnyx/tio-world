import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_core/core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('persists a theme mode for a newly created preference adapter',
      () async {
    final firstAdapter = SharedPreferencesAppThemePreference();
    await firstAdapter.write(TioThemeMode.oled);

    final restartedAdapter = SharedPreferencesAppThemePreference();

    expect(await restartedAdapter.read(), TioThemeMode.oled);
  });

  test('treats an invalid persisted value as a missing theme mode', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
      'app_theme_mode': 'unsupported',
    });

    final restartedAdapter = SharedPreferencesAppThemePreference();

    expect(await restartedAdapter.read(), isNull);
  });
}
