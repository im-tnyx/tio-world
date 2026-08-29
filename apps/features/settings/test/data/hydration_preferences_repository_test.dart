import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('missing key returns the effective 250 ml default', () async {
    final repository = SharedPreferencesHydrationPreferencesRepository();

    expect(await repository.read(), const HydrationPreferences());
  });

  for (final value in [200, 250, 300, 350, 500]) {
    test('stored preset $value ml reads exactly', () async {
      final repository = SharedPreferencesHydrationPreferencesRepository();
      await repository.write(HydrationPreferences(defaultGlassSizeMl: value));

      expect(await repository.read(),
          HydrationPreferences(defaultGlassSizeMl: value));
    });
  }

  test('valid custom value persists for a newly created repository', () async {
    final first = SharedPreferencesHydrationPreferencesRepository();
    await first.write(const HydrationPreferences(defaultGlassSizeMl: 760));

    final restarted = SharedPreferencesHydrationPreferencesRepository();
    expect(await restarted.read(),
        const HydrationPreferences(defaultGlassSizeMl: 760));
  });

  test('invalid values are rejected without rounding or storage', () async {
    final repository = SharedPreferencesHydrationPreferencesRepository();

    for (final value in [40, 49, 55, 255, 2001, 2010]) {
      await expectLater(
        repository.write(HydrationPreferences(defaultGlassSizeMl: value)),
        throwsArgumentError,
      );
    }

    expect(await repository.read(), const HydrationPreferences());
  });

  test('corrupt integer returns 250 ml and removes the override', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setInt(
      SharedPreferencesHydrationPreferencesRepository.storageKey,
      255,
    );
    final repository = SharedPreferencesHydrationPreferencesRepository(
        preferences: preferences);

    expect(await repository.read(), const HydrationPreferences());
    expect(
      await preferences.getInt(
        SharedPreferencesHydrationPreferencesRepository.storageKey,
      ),
      isNull,
    );
  });

  test('corrupt stored type returns 250 ml and removes the override', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      SharedPreferencesHydrationPreferencesRepository.storageKey,
      '300',
    );
    final repository = SharedPreferencesHydrationPreferencesRepository(
        preferences: preferences);

    expect(await repository.read(), const HydrationPreferences());
    expect(
      await preferences.getString(
        SharedPreferencesHydrationPreferencesRepository.storageKey,
      ),
      isNull,
    );
  });

  test('clear removes the override and restores 250 ml', () async {
    final repository = SharedPreferencesHydrationPreferencesRepository();
    await repository.write(const HydrationPreferences(defaultGlassSizeMl: 300));

    await repository.clear();

    expect(await repository.read(), const HydrationPreferences());
  });
}
