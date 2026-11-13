import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('unset and explicit OFF remain distinct and owner-scoped', () async {
    final firstOwner = SharedPreferencesWorkoutRuntimeSettingsRepository(
      ownerId: 'owner-a',
    );
    final secondOwner = SharedPreferencesWorkoutRuntimeSettingsRepository(
      ownerId: 'owner-b',
    );

    expect(await firstOwner.readDefaultRestSeconds(), isNull);
    expect(await secondOwner.readDefaultRestSeconds(), isNull);

    await firstOwner.writeDefaultRestSeconds(0);
    expect(await firstOwner.readDefaultRestSeconds(), 0);
    expect(await secondOwner.readDefaultRestSeconds(), isNull);

    await firstOwner.writeDefaultRestSeconds(90);
    expect(await firstOwner.readDefaultRestSeconds(), 90);
    expect(await secondOwner.readDefaultRestSeconds(), isNull);
  });

  test('unsupported or mistyped values are removed instead of guessed',
      () async {
    final preferences = SharedPreferencesAsync();
    final repository = SharedPreferencesWorkoutRuntimeSettingsRepository(
      ownerId: 'owner-a',
      preferences: preferences,
    );
    final key =
        SharedPreferencesWorkoutRuntimeSettingsRepository.storageKeyFor('owner-a');

    await preferences.setInt(key, 601);
    expect(await repository.readDefaultRestSeconds(), isNull);
    expect(await preferences.getInt(key), isNull);

    await preferences.setString(key, '90');
    expect(await repository.readDefaultRestSeconds(), isNull);
    expect(await preferences.getString(key), isNull);
  });

  test('vibration defaults OFF, remains device-local and owner-isolated',
      () async {
    final a = SharedPreferencesWorkoutRuntimeSettingsRepository(ownerId: 'a');
    final b = SharedPreferencesWorkoutRuntimeSettingsRepository(ownerId: 'b');
    expect(await a.readRestTimerVibrationEnabled(), isFalse);
    expect(await b.readRestTimerVibrationEnabled(), isFalse);

    await a.writeRestTimerVibrationEnabled(true);
    expect(await a.readRestTimerVibrationEnabled(), isTrue);
    expect(await b.readRestTimerVibrationEnabled(), isFalse);
    expect(
      await SharedPreferencesWorkoutRuntimeSettingsRepository(ownerId: 'a')
          .readRestTimerVibrationEnabled(),
      isTrue,
    );
    await a.writeRestTimerVibrationEnabled(false);
    expect(await a.readRestTimerVibrationEnabled(), isFalse);
  });

  test('malformed vibration preference fails safely OFF', () async {
    final prefs = SharedPreferencesAsync();
    final key =
        SharedPreferencesWorkoutRuntimeSettingsRepository.vibrationStorageKeyFor(
      'owner-a',
    );
    await prefs.setString(key, 'true');
    final repo = SharedPreferencesWorkoutRuntimeSettingsRepository(
      ownerId: 'owner-a', preferences: prefs,
    );
    expect(await repo.readRestTimerVibrationEnabled(), isFalse);
    expect(await prefs.getString(key), isNull);
  });

  test('supported 5-second values round-trip and clear restores unset',
      () async {
    final repository = SharedPreferencesWorkoutRuntimeSettingsRepository(
      ownerId: 'owner-a',
    );
    for (final value in [0, 5, 60, 90, 600]) {
      await repository.writeDefaultRestSeconds(value);
      expect(await repository.readDefaultRestSeconds(), value);
    }

    await repository.clearDefaultRestSeconds();
    expect(await repository.readDefaultRestSeconds(), isNull);
  });
}
