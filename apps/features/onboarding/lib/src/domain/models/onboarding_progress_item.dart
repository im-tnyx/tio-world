import '../models/profile_step_id.dart';
import '../models/target_step_id.dart';
import '../models/workout_step_id.dart';

/// Sealed hierarchy representing each distinct visible screen in the onboarding journey.
sealed class OnboardingProgressItem {
  const OnboardingProgressItem();

  String get title;
}

class ProfileProgressItem extends OnboardingProgressItem {
  const ProfileProgressItem(this.stepId);

  final ProfileStepId stepId;

  @override
  String get title => 'About you';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileProgressItem &&
          runtimeType == other.runtimeType &&
          stepId == other.stepId;

  @override
  int get hashCode => stepId.hashCode;
}

class WorkoutIntroProgressItem extends OnboardingProgressItem {
  const WorkoutIntroProgressItem();

  @override
  String get title => 'Workout setup';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutIntroProgressItem && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class WorkoutProgressItem extends OnboardingProgressItem {
  const WorkoutProgressItem(this.stepId);

  final WorkoutStepId stepId;

  @override
  String get title => 'Training preferences';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutProgressItem &&
          runtimeType == other.runtimeType &&
          stepId == other.stepId;

  @override
  int get hashCode => stepId.hashCode;
}

class NutritionIntroProgressItem extends OnboardingProgressItem {
  const NutritionIntroProgressItem();

  @override
  String get title => 'Nutrition setup';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionIntroProgressItem && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class NutritionPreferencesProgressItem extends OnboardingProgressItem {
  const NutritionPreferencesProgressItem();

  @override
  String get title => 'Nutrition preferences';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionPreferencesProgressItem &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class TargetsProgressItem extends OnboardingProgressItem {
  const TargetsProgressItem(this.stepId);

  final TargetStepId stepId;

  @override
  String get title => 'Your targets';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetsProgressItem &&
          runtimeType == other.runtimeType &&
          stepId == other.stepId;

  @override
  int get hashCode => stepId.hashCode;
}

class ReviewProgressItem extends OnboardingProgressItem {
  const ReviewProgressItem();

  @override
  String get title => 'Review setup';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewProgressItem && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}
