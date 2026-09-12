/// Device-local presentation preferences for the Meal Diary.
///
/// These values control only how existing MealLog truth is presented. They do
/// not own, rewrite, or clear `MealLogEntry.consumedAt` or `MealLogEntry.note`.
final class MealDiaryDisplayPreferences {
  const MealDiaryDisplayPreferences({
    this.showMealTimes = true,
    this.mealNotesEnabled = true,
    this.showMealNotePreview = false,
    this.showMealSectionNutrition = true,
  });

  final bool showMealTimes;
  final bool mealNotesEnabled;
  final bool showMealNotePreview;

  /// Whether a Meal Category section header renders its trailing Calories +
  /// Protein aggregate group. This is one switch for the whole group by
  /// design; it never hides calories/protein inside an individual card, and
  /// it never changes what aggregate value is actually known.
  final bool showMealSectionNutrition;

  MealDiaryDisplayPreferences copyWith({
    bool? showMealTimes,
    bool? mealNotesEnabled,
    bool? showMealNotePreview,
    bool? showMealSectionNutrition,
  }) {
    return MealDiaryDisplayPreferences(
      showMealTimes: showMealTimes ?? this.showMealTimes,
      mealNotesEnabled: mealNotesEnabled ?? this.mealNotesEnabled,
      showMealNotePreview:
          showMealNotePreview ?? this.showMealNotePreview,
      showMealSectionNutrition:
          showMealSectionNutrition ?? this.showMealSectionNutrition,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MealDiaryDisplayPreferences &&
      showMealTimes == other.showMealTimes &&
      mealNotesEnabled == other.mealNotesEnabled &&
      showMealNotePreview == other.showMealNotePreview &&
      showMealSectionNutrition == other.showMealSectionNutrition;

  @override
  int get hashCode => Object.hash(
        showMealTimes,
        mealNotesEnabled,
        showMealNotePreview,
        showMealSectionNutrition,
      );

  @override
  String toString() =>
      'MealDiaryDisplayPreferences('
      'showMealTimes: $showMealTimes, '
      'mealNotesEnabled: $mealNotesEnabled, '
      'showMealNotePreview: $showMealNotePreview, '
      'showMealSectionNutrition: $showMealSectionNutrition)';
}
