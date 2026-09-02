import '../models/additional_nutrient_goal.dart';
import '../models/nutrient_recommendation.dart';

/// What a user is allowed to do to one Additional Nutrient Goal right now.
///
/// This is the frozen TNYX-141 eligibility decision expressed once, in the
/// domain, rather than as layout conditions inside an editor. Any surface that
/// offers these actions — the goals editor today, a summary card or a coaching
/// prompt later — asks for the same capability rather than re-deriving the
/// rule and drifting from it.
///
/// The rule itself: a nutrient whose recommendation cannot be derived is not
/// enableable. Turning it on would create a goal with nothing to show, and
/// letting the user type a value instead would use Custom to bypass the very
/// eligibility rule the policy exists to enforce. A goal that is *already*
/// configured keeps its stored value and can still be turned off, because
/// removing user data is never blocked by a missing prerequisite.
final class AdditionalNutrientGoalEditCapability {
  const AdditionalNutrientGoalEditCapability({
    required this.canSetCustomValue,
    required this.canUseRecommendation,
    required this.canTurnOff,
  });

  /// Derives the capability for one nutrient from its current goal and the
  /// recommendation the policy could produce for it.
  factory AdditionalNutrientGoalEditCapability.forGoal({
    required AdditionalNutrientGoal? goal,
    required NutrientRecommendation recommendation,
  }) {
    final isAvailable = recommendation.isAvailable;
    return AdditionalNutrientGoalEditCapability(
      canSetCustomValue: isAvailable,
      // Nothing for "Use Recommended" to change when the goal already sits on
      // the recommendation.
      canUseRecommendation:
          isAvailable && !(goal != null && goal.usesRecommendation),
      canTurnOff: goal != null,
    );
  }

  /// Whether a custom override may be entered or saved.
  final bool canSetCustomValue;

  /// Whether the goal may be moved onto the derived recommendation. This is
  /// also the path that enables an unconfigured nutrient without forcing the
  /// user to invent a Custom value first.
  final bool canUseRecommendation;

  /// Whether the goal may be removed entirely.
  final bool canTurnOff;

  /// True when a configured goal can be seen and removed but not changed —
  /// the state a saved override lands in once its prerequisites go away.
  bool get isValuePreserved =>
      canTurnOff && !canSetCustomValue && !canUseRecommendation;
}
