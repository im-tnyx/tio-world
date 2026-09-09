import 'package:characters/characters.dart';

import 'meal_categories_validation.dart';

/// The single owner of what a Meal Category display name may be.
///
/// Every path that can put a name into storage — the add and rename editor,
/// the controller, `MealCategory`'s own constructor, the persisted-state codec
/// and any direct domain caller — goes through [canonicalize]. One algorithm,
/// stated once: a name the editor accepts is exactly a name the domain stores,
/// and a caller that skips the editor gets the same answer rather than a
/// looser one.
///
/// Deliberately depends on nothing but the validation codes, so `MealCategory`
/// and `MealCategoriesPolicy` can both reach it without either depending on
/// the other.
abstract final class MealCategoryDisplayNamePolicy {
  /// How long a name may be, counted the way a reader counts it.
  ///
  /// Extended grapheme clusters, not UTF-16 code units: a family emoji is one
  /// character to the person typing it, and a limit that called it eleven
  /// would be measuring the encoding rather than the name.
  static const int maxLength = 24;

  /// Runs of whitespace that collapse to one ordinary space.
  ///
  /// Applied only after [_forbidden] has already refused the line-breaking and
  /// control members of this class, so everything left here is a space
  /// separator standing in for an ordinary space.
  static final RegExp _whitespace = RegExp(r'\s+');

  /// What can never appear inside a stored name.
  ///
  /// C0 controls (tab, newline and carriage return among them), DEL, the C1
  /// block, and the Unicode line and paragraph separators. A category name is
  /// one line of text; anything that would break it into two, or that no font
  /// renders, is refused rather than quietly stripped.
  ///
  /// Note what is *not* here: U+200D and the other formatting code points that
  /// hold a multi-part emoji together. Rejecting non-printing characters as a
  /// class would tear valid grapheme clusters apart, so the rule names the
  /// line-breaking and control ranges instead.
  static final RegExp _forbidden = RegExp(
    r'[\u0000-\u001F\u007F-\u009F\u2028\u2029]',
  );

  /// The exact value a name is stored as, or a typed refusal.
  ///
  /// Order matters. Outer whitespace goes first, so a field holding only
  /// spaces or a stray newline reads as blank — which it is — rather than as
  /// an exotic character failure the reader cannot act on. Interior controls
  /// are refused next, while they are still visible in the input; collapsing
  /// first would silently absorb an embedded tab into a space. Only then is
  /// the length counted, against the value that would actually be stored.
  ///
  /// Never truncates. A name over the limit is refused and the reader shortens
  /// it themselves; storing a cut-off version would put a name on screen that
  /// nobody chose.
  static String canonicalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.blankDisplayName,
        message: 'Meal Category displayName must not be blank.',
      );
    }
    if (_forbidden.hasMatch(trimmed)) {
      throw const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.invalidDisplayNameCharacters,
        message: 'Meal Category displayName must be a single line without '
            'control characters.',
      );
    }

    final canonical = _collapse(trimmed);
    if (canonical.characters.length > maxLength) {
      throw const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.displayNameTooLong,
        message: 'Meal Category displayName must be at most $maxLength '
            'characters.',
      );
    }
    return canonical;
  }

  /// How two display names are compared for equality.
  ///
  /// The canonical value lowercased: `Pre Workout` and `pre   workout` are the
  /// same name to a reader, and a list offering both is a list they cannot
  /// tell apart. Case is preserved in storage and dropped only here.
  ///
  /// Total on purpose, where [canonicalize] is not. It runs over names already
  /// stored as well as over half-typed input, and a comparison is not the
  /// place to decide a name is invalid.
  static String comparisonKey(String value) => _collapse(value).toLowerCase();

  /// The one whitespace algorithm. Both public entry points read through it,
  /// so the editor's comparison and the stored value can never drift apart.
  static String _collapse(String value) =>
      value.replaceAll(_whitespace, ' ').trim();
}
