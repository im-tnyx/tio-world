/// How a nutrient recommendation is meant to be read.
///
/// A `maximum` is a ceiling not to exceed; a `target` is an amount to reach.
enum NutrientGoalType { maximum, target }

/// How a recommended amount is phrased against the user's intake.
///
/// `lessThan` is a strict boundary: the number itself is already too much, so
/// it must never be rendered as a bare amount. `atMost` includes the number.
/// `target` is neither a ceiling nor a floor.
enum NutrientGoalComparison { atMost, lessThan, target }
