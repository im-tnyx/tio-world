class NutritionTargetInputs {
  const NutritionTargetInputs({
    this.heightCm,
    this.weightKg,
    this.dateOfBirth,
    this.gender,
    this.activityLevel,
    this.primaryGoal,
    this.goalPaceKgPerWeek,
    this.dailyStepTarget,
  });

  final double? heightCm;
  final double? weightKg;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? activityLevel;
  final String? primaryGoal;
  final double? goalPaceKgPerWeek;
  final int? dailyStepTarget;

  int? calculateAge([DateTime? now]) {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final currentDate = now ?? DateTime.now();
    var age = currentDate.year - dob.year;
    final monthDiff = currentDate.month - dob.month;
    if (monthDiff < 0 || (monthDiff == 0 && currentDate.day < dob.day)) {
      age--;
    }
    return age >= 0 ? age : null;
  }
}
