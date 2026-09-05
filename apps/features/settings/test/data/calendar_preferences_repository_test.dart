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

  test('missing key resolves to Monday', () async {
    final repository = SharedPreferencesCalendarPreferencesRepository();

    expect(await repository.read(), const CalendarPreferences());
  });

  for (final preference in FirstDayOfWeekPreference.values) {
    test('${preference.storageValue} round-trips through local storage',
        () async {
      final repository = SharedPreferencesCalendarPreferencesRepository();
      final value = CalendarPreferences(firstDayOfWeek: preference);

      await repository.write(value);

      expect(await repository.read(), value);
      expect(
        await SharedPreferencesAsync().getString(
          SharedPreferencesCalendarPreferencesRepository.storageKey,
        ),
        preference.storageValue,
      );
    });
  }

  test('unknown value resolves to Monday and removes the override', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      SharedPreferencesCalendarPreferencesRepository.storageKey,
      'automatic',
    );
    final repository = SharedPreferencesCalendarPreferencesRepository(
      preferences: preferences,
    );

    expect(await repository.read(), const CalendarPreferences());
    expect(
      await preferences.getString(
        SharedPreferencesCalendarPreferencesRepository.storageKey,
      ),
      isNull,
    );
  });

  test('corrupt stored type resolves to Monday and removes the override',
      () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setInt(
      SharedPreferencesCalendarPreferencesRepository.storageKey,
      1,
    );
    final repository = SharedPreferencesCalendarPreferencesRepository(
      preferences: preferences,
    );

    expect(await repository.read(), const CalendarPreferences());
    expect(
      await preferences.getInt(
        SharedPreferencesCalendarPreferencesRepository.storageKey,
      ),
      isNull,
    );
  });

  test('clear removes the override and restores Monday', () async {
    final repository = SharedPreferencesCalendarPreferencesRepository();
    await repository.write(const CalendarPreferences(
      firstDayOfWeek: FirstDayOfWeekPreference.sunday,
    ));

    await repository.clear();

    expect(await repository.read(), const CalendarPreferences());
  });
}
