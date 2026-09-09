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
  /// Order matters, and the first two steps are not interchangeable.
  ///
  /// Blankness is settled first, because a field holding nothing but spaces —
  /// or nothing but a stray newline — is blank to the reader, and telling them
  /// it contains an illegal character is advice they cannot act on.
  ///
  /// Everything else is then checked against the **raw** input rather than a
  /// trimmed copy. Trimming first would delete a leading or trailing newline,
  /// tab or control on its way past and hand back an accepted name: `Lunch\n`
  /// would quietly become `Lunch`. The contract says such input is refused,
  /// not converted, so the forbidden set is matched before anything has had a
  /// chance to remove it. Only ordinary space separators are trimmed and
  /// collapsed afterwards, and by then nothing forbidden is left to absorb.
  ///
  /// Length is counted last, against the value that would actually be stored.
  /// Never truncates: a name over the limit is refused and the reader shortens
  /// it themselves, because storing a cut-off version would put a name on
  /// screen that nobody chose.
  static String canonicalize(String raw) {
    if (raw.trim().isEmpty) {
      throw const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.blankDisplayName,
        message: 'Meal Category displayName must not be blank.',
      );
    }
    if (_forbidden.hasMatch(raw)) {
      throw const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.invalidDisplayNameCharacters,
        message: 'Meal Category displayName must be a single line without '
            'control characters.',
      );
    }

    final canonical = _collapse(raw);
    if (canonical.characters.length > maxLength) {
      throw const MealCategoriesValidationException(
        code: MealCategoriesValidationCode.displayNameTooLong,
        message: 'Meal Category displayName must be at most $maxLength '
            'characters.',
      );
    }
    return canonical;
  }

  /// How long [raw] counts as, measured the way [canonicalize] measures it.
  ///
  /// The editor shows this while the reader types, so it has to be the same
  /// number the domain will check. Counting the raw field text instead would
  /// put the two at odds: `Pre` and `Workout` separated by twenty spaces is
  /// thirty characters in the field and eleven in `Pre Workout`, and a limit
  /// applied to the first would refuse a name the domain accepts — or, worse,
  /// cut the paste down to `Pre` before the domain ever saw it.
  ///
  /// Total on purpose, like [comparisonKey] and unlike [canonicalize]. A count
  /// runs over half-typed text and is not the place to decide a name is
  /// invalid.
  static int canonicalLength(String raw) => _collapse(raw).characters.length;

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
