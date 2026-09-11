/// Device-local presentation preferences for the Meal Diary.
///
/// These values control only how existing MealLog truth is presented. They do
/// not own, rewrite, or clear `MealLogEntry.consumedAt` or `MealLogEntry.note`.
final class MealDiaryDisplayPreferences {
  const MealDiaryDisplayPreferences({
    this.showMealTimes = true,
    this.mealNotesEnabled = true,
    this.showMealNotePreview = false,
  });

  final bool showMealTimes;
  final bool mealNotesEnabled;
  final bool showMealNotePreview;

  MealDiaryDisplayPreferences copyWith({
    bool? showMealTimes,
    bool? mealNotesEnabled,
    bool? showMealNotePreview,
  }) {
    return MealDiaryDisplayPreferences(
      showMealTimes: showMealTimes ?? this.showMealTimes,
      mealNotesEnabled: mealNotesEnabled ?? this.mealNotesEnabled,
      showMealNotePreview:
          showMealNotePreview ?? this.showMealNotePreview,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MealDiaryDisplayPreferences &&
      showMealTimes == other.showMealTimes &&
      mealNotesEnabled == other.mealNotesEnabled &&
      showMealNotePreview == other.showMealNotePreview;

  @override
  int get hashCode => Object.hash(
        showMealTimes,
        mealNotesEnabled,
        showMealNotePreview,
      );

  @override
  String toString() =>
      'MealDiaryDisplayPreferences('
      'showMealTimes: $showMealTimes, '
      'mealNotesEnabled: $mealNotesEnabled, '
      'showMealNotePreview: $showMealNotePreview)';
}
