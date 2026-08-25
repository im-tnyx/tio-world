import '../models/models.dart';

class CalculateProfileHealthMetrics {
  const CalculateProfileHealthMetrics();

  ProfileHealthMetrics call(
    ProfileSetupData profile, {
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();
    final ageYears = _calculateAge(profile.dateOfBirth, referenceDate);
    final hasValidDimensions =
        profile.currentWeightKg > 0 && profile.heightCm > 0;

    if (!hasValidDimensions) {
      return ProfileHealthMetrics(
        ageYears: ageYears,
        bmi: null,
        bmrKcal: null,
      );
    }

    final heightM = profile.heightCm / 100.0;
    final bmi = profile.currentWeightKg / (heightM * heightM);
    final base = (10 * profile.currentWeightKg) +
        (6.25 * profile.heightCm) -
        (5 * ageYears);
    final bmr = switch (profile.gender) {
      ProfileGender.male => base + 5,
      ProfileGender.female => base - 161,
      ProfileGender.other => base - 78,
    };

    return ProfileHealthMetrics(
      ageYears: ageYears,
      bmi: double.parse(bmi.toStringAsFixed(1)),
      bmrKcal: bmr.round(),
    );
  }

  int _calculateAge(DateTime dateOfBirth, DateTime referenceDate) {
    var age = referenceDate.year - dateOfBirth.year;
    if (referenceDate.month < dateOfBirth.month ||
        (referenceDate.month == dateOfBirth.month &&
            referenceDate.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}
