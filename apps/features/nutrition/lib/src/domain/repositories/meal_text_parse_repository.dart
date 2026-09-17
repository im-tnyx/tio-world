import 'package:tio_shared/shared.dart';

/// Provider-neutral categories a protected meal-text parser may map failures to.
///
/// Provider response bodies, model names, HTTP errors, prompts, and credentials
/// deliberately do not cross this boundary. Presentation/controller code can
/// recover from these stable Tio-owned reasons without learning which provider
/// or transport produced them.
enum MealTextParseFailureReason {
  /// The text could not be resolved into any usable meal interpretation.
  unrecognized,

  /// Some food meaning was found, but not enough normalized facts are available
  /// for the current review/save path to continue safely.
  incomplete,

  /// The protected parsing capability is temporarily unavailable.
  unavailable,
}

/// Safe recoverable failure exposed by a meal-text parser implementation.
final class MealTextParseFailure implements Exception {
  const MealTextParseFailure(this.reason);

  final MealTextParseFailureReason reason;

  @override
  String toString() => 'MealTextParseFailure(${reason.name})';
}

/// Nutrition-owned boundary for turning natural-language meal text into a
/// provider-neutral, discardable [MealLoggingDraft].
///
/// The caller supplies normalized non-blank text. Implementations may later use
/// a protected Edge Function, `services/api`, or another approved adapter, but
/// none of those transport/provider details belong in this contract.
///
/// A successful result is still only reviewable draft state. It must never
/// create durable MealLog history by itself.
abstract interface class MealTextParseRepository {
  Future<MealLoggingDraft> parseMealText(String text);
}
