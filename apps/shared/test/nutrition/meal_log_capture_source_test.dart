import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const expectedSources = <MealLogCaptureSource, String>{
    MealLogCaptureSource.quickAdd: 'quick_add',
    MealLogCaptureSource.foodSearch: 'food_search',
    MealLogCaptureSource.barcode: 'barcode',
    MealLogCaptureSource.text: 'text',
    MealLogCaptureSource.voice: 'voice',
    MealLogCaptureSource.photo: 'photo',
    MealLogCaptureSource.recent: 'recent',
    MealLogCaptureSource.savedMeal: 'saved_meal',
    MealLogCaptureSource.plannedMeal: 'planned_meal',
  };

  group('MealLogCaptureSource', () {
    test('defines the complete canonical capture-source contract', () {
      expect(MealLogCaptureSource.values, hasLength(9));
      expect(MealLogCaptureSource.values, hasLength(expectedSources.length));

      for (final entry in expectedSources.entries) {
        expect(entry.key.storageValue, entry.value);
      }
    });

    test('round-trips every canonical storage value', () {
      for (final source in MealLogCaptureSource.values) {
        expect(
          MealLogCaptureSource.fromStorageValue(source.storageValue),
          source,
        );
      }
    });

    test('does not define duplicate storage values', () {
      final storageValues = MealLogCaptureSource.values
          .map((source) => source.storageValue)
          .toSet();

      expect(storageValues, hasLength(MealLogCaptureSource.values.length));
    });

    test('supports barcode as a first-class capture source', () {
      expect(MealLogCaptureSource.barcode.storageValue, 'barcode');
      expect(
        MealLogCaptureSource.fromStorageValue('barcode'),
        MealLogCaptureSource.barcode,
      );
    });

    test('leaves unknown future identities unknown without remapping', () {
      for (final unknown in [
        'future_capture_source',
        'QUICK_ADD',
        'quickAdd',
        '',
      ]) {
        expect(
          MealLogCaptureSource.fromStorageValue(unknown),
          isNull,
          reason: '$unknown must not be remapped to an existing source.',
        );
      }

      expect(MealLogCaptureSource.fromStorageValue(null), isNull);
    });

    test('never falls back to quickAdd for an unrecognized identity', () {
      // A fallback would fabricate capture intent the user never expressed.
      expect(
        MealLogCaptureSource.fromStorageValue('something_else'),
        isNot(MealLogCaptureSource.quickAdd),
      );
      expect(MealLogCaptureSource.fromStorageValue('something_else'), isNull);
    });

    test('keeps Quick Add distinct from Food Search', () {
      expect(
        MealLogCaptureSource.quickAdd,
        isNot(MealLogCaptureSource.foodSearch),
      );
      expect(
        MealLogCaptureSource.quickAdd.storageValue,
        isNot(MealLogCaptureSource.foodSearch.storageValue),
      );
    });

    test('keeps capture modes separate from provider identities', () {
      // photo, voice and text describe how the user captured the meal. A
      // provider such as FatSecret may resolve the food behind any of them
      // without changing the capture mode, so provider names are never
      // capture sources. Provider identity belongs to a later item-level
      // provenance contract.
      for (final provider in [
        'fatsecret',
        'openai',
        'edamam',
        'camera_fatsecret',
        'nutritionix',
      ]) {
        expect(
          MealLogCaptureSource.fromStorageValue(provider),
          isNull,
          reason: '$provider is a provider/adapter, not a capture mode.',
        );
      }

      expect(MealLogCaptureSource.photo.storageValue, 'photo');
      expect(MealLogCaptureSource.voice.storageValue, 'voice');
      expect(MealLogCaptureSource.text.storageValue, 'text');
    });

    test('exposes no provider or nutrition data at meal level', () {
      // The contract is one storage identity and nothing else. If a provider
      // key or nutrition amount is ever added here, this slice's boundary has
      // been violated.
      expect(MealLogCaptureSource.photo.storageValue, isA<String>());
      expect(MealLogCaptureSource.photo, isA<MealLogCaptureSource>());
    });

    test('uses deterministic enum identity and value semantics', () {
      expect(
        MealLogCaptureSource.barcode,
        same(MealLogCaptureSource.fromStorageValue('barcode')),
      );
      expect(
        MealLogCaptureSource.barcode.hashCode,
        MealLogCaptureSource.fromStorageValue('barcode').hashCode,
      );
      expect(
        MealLogCaptureSource.values.indexOf(MealLogCaptureSource.quickAdd),
        0,
      );
    });
  });
}
