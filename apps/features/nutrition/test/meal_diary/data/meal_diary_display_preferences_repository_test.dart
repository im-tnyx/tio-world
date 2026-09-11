import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('missing local value resolves the N14 defaults', () async {
    final repository = SharedPreferencesMealDiaryDisplayPreferencesRepository();

    expect(await repository.read(), const MealDiaryDisplayPreferences());
  });

  test('all three preferences round-trip through one versioned snapshot',
      () async {
    final repository = SharedPreferencesMealDiaryDisplayPreferencesRepository();
    const value = MealDiaryDisplayPreferences(
      showMealTimes: false,
      mealNotesEnabled: false,
      showMealNotePreview: true,
    );

    await repository.write(value);

    expect(await repository.read(), value);

    final raw = await SharedPreferencesAsync().getString(
      SharedPreferencesMealDiaryDisplayPreferencesRepository.storageKey,
    );
    final decoded = jsonDecode(raw!) as Map<String, dynamic>;
    expect(decoded['version'], 1);
    expect(decoded['showMealTimes'], isFalse);
    expect(decoded['mealNotesEnabled'], isFalse);
    expect(decoded['showMealNotePreview'], isTrue);
  });

  test('malformed JSON resolves defaults and removes the bad snapshot',
      () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      SharedPreferencesMealDiaryDisplayPreferencesRepository.storageKey,
      '{not-json',
    );
    final repository = SharedPreferencesMealDiaryDisplayPreferencesRepository(
      preferences: preferences,
    );

    expect(await repository.read(), const MealDiaryDisplayPreferences());
    expect(
      await preferences.getString(
        SharedPreferencesMealDiaryDisplayPreferencesRepository.storageKey,
      ),
      isNull,
    );
  });

  test('unknown schema or incomplete values fail closed to defaults', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      SharedPreferencesMealDiaryDisplayPreferencesRepository.storageKey,
      jsonEncode({
        'version': 2,
        'showMealTimes': false,
        'mealNotesEnabled': true,
      }),
    );
    final repository = SharedPreferencesMealDiaryDisplayPreferencesRepository(
      preferences: preferences,
    );

    expect(await repository.read(), const MealDiaryDisplayPreferences());
    expect(
      await preferences.getString(
        SharedPreferencesMealDiaryDisplayPreferencesRepository.storageKey,
      ),
      isNull,
    );
  });

  test('a corrupt stored type resolves defaults and removes the override',
      () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setInt(
      SharedPreferencesMealDiaryDisplayPreferencesRepository.storageKey,
      1,
    );
    final repository = SharedPreferencesMealDiaryDisplayPreferencesRepository(
      preferences: preferences,
    );

    expect(await repository.read(), const MealDiaryDisplayPreferences());
    expect(
      await preferences.getInt(
        SharedPreferencesMealDiaryDisplayPreferencesRepository.storageKey,
      ),
      isNull,
    );
  });

  test('clear removes the local override and restores defaults', () async {
    final repository = SharedPreferencesMealDiaryDisplayPreferencesRepository();
    await repository.write(
      const MealDiaryDisplayPreferences(
        showMealTimes: false,
        mealNotesEnabled: false,
        showMealNotePreview: true,
      ),
    );

    await repository.clear();

    expect(await repository.read(), const MealDiaryDisplayPreferences());
  });
}
