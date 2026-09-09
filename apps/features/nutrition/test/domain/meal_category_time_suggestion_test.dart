import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

MealCategory _category({
  required String id,
  required String displayName,
  required int order,
  MealCategoryDefaultKey? defaultKey,
}) =>
    MealCategory(
      id: id,
      defaultKey: defaultKey,
      displayName: displayName,
      active: true,
      order: order,
    );

List<MealCategory> _canonical({Set<String> without = const {}}) => [
      for (final entry in const [
        (id: 'meal_slot_1', key: MealCategoryDefaultKey.breakfast, name: 'Breakfast'),
        (id: 'meal_slot_2', key: MealCategoryDefaultKey.lunch, name: 'Lunch'),
        (id: 'meal_slot_3', key: MealCategoryDefaultKey.dinner, name: 'Dinner'),
        (id: 'meal_slot_4', key: MealCategoryDefaultKey.snacks, name: 'Snacks'),
      ])
        if (!without.contains(entry.id))
          _category(
            id: entry.id,
            defaultKey: entry.key,
            displayName: entry.name,
            order: 0,
          ),
    ];

DateTime _at(int hour, [int minute = 0]) =>
    DateTime(2026, 9, 9, hour, minute);

void main() {
  group('which canonical meal an hour points at', () {
    test('the three anchors own their own hours', () {
      const expected = <int, MealCategoryDefaultKey>{
        4: MealCategoryDefaultKey.breakfast,
        7: MealCategoryDefaultKey.breakfast,
        10: MealCategoryDefaultKey.breakfast,
        11: MealCategoryDefaultKey.lunch,
        13: MealCategoryDefaultKey.lunch,
        15: MealCategoryDefaultKey.lunch,
        18: MealCategoryDefaultKey.dinner,
        20: MealCategoryDefaultKey.dinner,
        22: MealCategoryDefaultKey.dinner,
      };

      for (final entry in expected.entries) {
        expect(
          suggestedMealCategoryKey(_at(entry.key)),
          entry.value,
          reason: '${entry.key}:00',
        );
      }
    });

    test('the hours none of them own fall to snacks', () {
      // Deliberate gaps: late afternoon is nobody's lunch or dinner, and the
      // small hours are nobody's dinner. Stretching an anchor to cover them
      // would claim more than the hour says.
      for (final hour in [16, 17, 23, 0, 2, 3]) {
        expect(
          suggestedMealCategoryKey(_at(hour)),
          MealCategoryDefaultKey.snacks,
          reason: '$hour:00',
        );
      }
    });

    test('the boundaries land on the minute', () {
      expect(
        suggestedMealCategoryKey(_at(10, 59)),
        MealCategoryDefaultKey.breakfast,
      );
      expect(
        suggestedMealCategoryKey(_at(11, 0)),
        MealCategoryDefaultKey.lunch,
      );
      expect(
        suggestedMealCategoryKey(_at(15, 59)),
        MealCategoryDefaultKey.lunch,
      );
      expect(
        suggestedMealCategoryKey(_at(16, 0)),
        MealCategoryDefaultKey.snacks,
      );
    });
  });

  group('resolving that to something selectable', () {
    test('returns the durable id, never the name', () {
      expect(
        suggestedMealCategoryId(
          consumedLocal: _at(13),
          activeItems: _canonical(),
        ),
        'meal_slot_2',
      );
    });

    test('a renamed canonical category keeps its role', () {
      // The match is on defaultKey, so renaming Lunch does not move what 13:00
      // suggests — and the reader sees their own name for it.
      final renamed = [
        _category(
          id: 'meal_slot_2',
          defaultKey: MealCategoryDefaultKey.lunch,
          displayName: 'Midday Meal',
          order: 1,
        ),
      ];

      expect(
        suggestedMealCategoryId(consumedLocal: _at(13), activeItems: renamed),
        'meal_slot_2',
      );
    });

    test('a custom category is never suggested', () {
      // `Pre Workout` could be 06:00 or 18:00. Inferring a schedule from a
      // name the reader invented would be guessing about their day.
      final onlyCustom = [
        _category(
          id: 'meal_slot_aaaaaaaa-aaaa-4aaa-8aaa-000000000000',
          displayName: 'Lunch',
          order: 0,
        ),
      ];

      expect(
        suggestedMealCategoryId(
          consumedLocal: _at(13),
          activeItems: onlyCustom,
        ),
        isNull,
        reason: 'even one named exactly like the canonical meal',
      );
    });

    test('an archived canonical category suggests nothing at all', () {
      // Nothing is substituted: an empty control is honest where a wrong one
      // is not.
      expect(
        suggestedMealCategoryId(
          consumedLocal: _at(13),
          activeItems: _canonical(without: {'meal_slot_2'}),
        ),
        isNull,
      );
    });
  });
}
