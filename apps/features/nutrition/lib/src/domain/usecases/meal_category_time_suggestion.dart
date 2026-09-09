import '../models/meal_category.dart';

/// Which canonical meal a local time of day most likely belongs to.
///
/// A convenience, never a rule. Nothing is forbidden by the clock: the reader
/// may file a meal under any active category at any hour, and this only
/// decides what the editor offers before they say otherwise.
///
/// ## Why only the canonical four
///
/// These four carry a shared meaning — `breakfast` is the morning meal for
/// every reader, whatever they have renamed it to. A custom category carries
/// no such meaning: `Pre Workout` could be 06:00 or 18:00, and inferring a
/// schedule from a name the reader invented would be guessing about their day.
/// So custom categories are never suggested, and are always one tap away.
///
/// ## Why the boundaries sit where they do
///
/// ```text
/// 04:00 – 10:59   breakfast
/// 11:00 – 15:59   lunch
/// 18:00 – 22:59   dinner
/// everything else snacks
/// ```
///
/// The gaps are deliberate. 16:00–17:59 is neither lunch nor dinner for most
/// people, and 23:00–03:59 is nobody's dinner; both fall to `snacks`, which is
/// what a meal outside the three anchors usually is. That keeps a suggestion
/// available at every hour without stretching any of the three to cover time
/// it does not own.
///
/// These are a heuristic and are documented as one. TNYX-70 will let the
/// reader state their own meal times, and when it does this can be improved or
/// replaced by that — their answer beats ours. Nothing here is stored on a
/// `MealCategory`; the mapping is computed, not persisted.
MealCategoryDefaultKey suggestedMealCategoryKey(DateTime consumedLocal) {
  final hour = consumedLocal.hour;
  if (hour >= 4 && hour < 11) return MealCategoryDefaultKey.breakfast;
  if (hour >= 11 && hour < 16) return MealCategoryDefaultKey.lunch;
  if (hour >= 18 && hour < 23) return MealCategoryDefaultKey.dinner;
  return MealCategoryDefaultKey.snacks;
}

/// The id the editor should start on, or null when there is nothing to offer.
///
/// Resolved to a **stable id**, never to a name: a reader who renamed Lunch to
/// `Midday Meal` still gets that category at 13:00, because the match is on
/// [MealCategory.defaultKey].
///
/// Null when the suggested canonical category is not among [activeItems] —
/// archived, say. Nothing else is substituted: falling through to another
/// category would be inventing a schedule for it, and an empty control is
/// honest where a wrong one is not.
String? suggestedMealCategoryId({
  required DateTime consumedLocal,
  required Iterable<MealCategory> activeItems,
}) {
  final key = suggestedMealCategoryKey(consumedLocal);
  for (final item in activeItems) {
    if (item.defaultKey == key) return item.id;
  }
  return null;
}
