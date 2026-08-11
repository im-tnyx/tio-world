import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_shared/shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('persists a mode for a newly created preference adapter', () async {
    final firstAdapter = SharedPreferencesAppModePreference();
    await firstAdapter.write(AppMode.hybrid);

    final restartedAdapter = SharedPreferencesAppModePreference();

    expect(await restartedAdapter.read(), AppMode.hybrid);
  });

  test('treats an invalid persisted value as a missing mode', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
      'app_mode': 'unsupported',
    });

    final restartedAdapter = SharedPreferencesAppModePreference();

    expect(await restartedAdapter.read(), isNull);
  });
}
