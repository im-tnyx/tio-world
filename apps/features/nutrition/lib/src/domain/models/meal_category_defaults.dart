import 'meal_category.dart';

final class MealCategoryDefaultDefinition {
  const MealCategoryDefaultDefinition({
    required this.id,
    required this.key,
    required this.displayName,
    required this.order,
  });

  final String id;
  final MealCategoryDefaultKey key;
  final String displayName;
  final int order;

  MealCategory resolve() => MealCategory(
        id: id,
        defaultKey: key,
        displayName: displayName,
        active: true,
        order: order,
      );
}

const canonicalMealCategoryDefaultDefinitions = <MealCategoryDefaultDefinition>[
  MealCategoryDefaultDefinition(
    id: 'meal_slot_1',
    key: MealCategoryDefaultKey.breakfast,
    displayName: 'Breakfast',
    order: 0,
  ),
  MealCategoryDefaultDefinition(
    id: 'meal_slot_2',
    key: MealCategoryDefaultKey.lunch,
    displayName: 'Lunch',
    order: 1,
  ),
  MealCategoryDefaultDefinition(
    id: 'meal_slot_3',
    key: MealCategoryDefaultKey.dinner,
    displayName: 'Dinner',
    order: 2,
  ),
  MealCategoryDefaultDefinition(
    id: 'meal_slot_4',
    key: MealCategoryDefaultKey.snacks,
    displayName: 'Snacks',
    order: 3,
  ),
];
