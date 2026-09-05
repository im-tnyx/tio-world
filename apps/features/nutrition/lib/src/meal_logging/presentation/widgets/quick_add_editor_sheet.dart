import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import 'meal_log_action_footer.dart';

/// Opens the Quick Add manual nutrition editor for [selectedDate].
///
/// [selectedDate] is the Meal Diary's own selected day, passed by value. The
/// editor is given the date, not the diary's controller, so there is no path
/// by which opening, editing or closing this sheet can move the reader's
/// selection.
Future<void> showQuickAddEditorSheet(
  BuildContext context, {
  required DateTime selectedDate,
}) {
  return showTioEditorSheet<void>(
    context: context,
    // Same reason as the Add Food sheet: the diary sits inside a shell branch
    // navigator, and an editor holding a captured date must not leave the
    // Today action or the tabs reachable behind it.
    useRootNavigator: true,
    builder: (_) => QuickAddEditorSheet(selectedDate: selectedDate),
  );
}

/// The manual/coarse nutrition editor.
///
/// ```text
/// Quick Add
/// ┌────────────────────────────────┐
/// │ Meal name (optional)           │   large, and the only free text
/// └────────────────────────────────┘
/// Calories (kcal)         [      ]
/// Carbs (g)               [      ]
/// Protein (g)             [      ]
/// Fat (g)                 [      ]
/// ─────────────────────────────────   body scrolls, footer does not
/// Meal type ▼        🗓 Sep 5 · Time
/// [           Log Meal            ]
/// ```
///
/// ## Why this is not the Meal Editor
///
/// Quick Add is for the reader who already knows the numbers and does not want
/// to name a single ingredient. AI, voice, photo, search, repeat and saved
/// meals will all converge on the full Meal Editor through a draft; this screen
/// deliberately does not, because routing it there would make the fastest path
/// wear the slowest screen's chrome. They may share components. They are not
/// the same surface.
///
/// ## Why so few fields
///
/// Fiber and micronutrients were dropped from this shell on owner review. They
/// are not cancelled — TNYX-115 and TNYX-58 can add supported nutrients later
/// through the shared nutrition-value contract — but a coarse entry that asks
/// for seven numbers is not a coarse entry.
///
/// ## Why `Log Meal` does nothing
///
/// Actual meal history is owned by TNYX-113 (the canonical entry), TNYX-114
/// (consumed time and local-date semantics) and TNYX-115 (the Quick Add
/// lifecycle). None of them exists yet. A button that stored the meal
/// somewhere improvised — in memory, in preferences, in a table invented here
/// — would be a second, wrong owner of the user's history, and the user would
/// find out it was wrong by losing meals. So the button is present, disabled,
/// and says why.
///
/// Every value lives in this `State`'s own text controllers and dies with the
/// route. There is no notifier, no repository, no store and no draft, which is
/// why backing out leaves nothing behind — not because a teardown path clears
/// something, but because there was never anything to clear.
class QuickAddEditorSheet extends StatefulWidget {
  const QuickAddEditorSheet({required this.selectedDate, super.key});

  /// The Meal Diary's selected day, carried in and only displayed.
  final DateTime selectedDate;

  @override
  State<QuickAddEditorSheet> createState() => _QuickAddEditorSheetState();
}

class _QuickAddEditorSheetState extends State<QuickAddEditorSheet> {
  final _mealName = TextEditingController();
  final _calories = TextEditingController();
  final _carbs = TextEditingController();
  final _protein = TextEditingController();
  final _fat = TextEditingController();

  late final List<TextEditingController> _fields = [
    _mealName,
    _calories,
    _carbs,
    _protein,
    _fat,
  ];

  @override
  void initState() {
    super.initState();
    // Validation is per-keystroke because the errors are about the characters
    // themselves, not about a submission that cannot happen here.
    for (final controller in _fields) {
      controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _fields) {
      controller
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    // Month and day only. The year is noise in a chip this size, and the
    // diary the reader came from already says which one they are on.
    final selectedDateLabel =
        localizations.formatShortMonthDay(widget.selectedDate);

    return TioEditorSheet(
      key: const ValueKey('quick-add-editor'),
      title: 'Quick Add',
      // The footer draws its own rule across the sheet, so the standard gap
      // above the actions would only put dead space above that line.
      flushActions: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The one free-text field. It uses the governed larger rounded
          // surface so it reads as the thing you name the meal with, but it
          // starts at one line: a fixed two-line box was more room than a
          // title needs and made the screen top-heavy. It still grows to a
          // second line for a longer name, and stops there — this is a title,
          // not a notes field.
          TioInput.multiline(
            key: const ValueKey('quick-add-meal-name'),
            controller: _mealName,
            hint: 'Meal name (optional)',
            minLines: 1,
            maxLines: 2,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            onChanged: (_) {},
          ),
          const SizedBox(height: TioSpacing.lg),
          _NutritionRow(
            fieldKey: const ValueKey('quick-add-calories'),
            controller: _calories,
            label: 'Calories',
            unit: 'kcal',
          ),
          const SizedBox(height: TioSpacing.md),
          _NutritionRow(
            fieldKey: const ValueKey('quick-add-carbs'),
            controller: _carbs,
            label: 'Carbs',
            unit: 'g',
          ),
          const SizedBox(height: TioSpacing.md),
          _NutritionRow(
            fieldKey: const ValueKey('quick-add-protein'),
            controller: _protein,
            label: 'Protein',
            unit: 'g',
          ),
          const SizedBox(height: TioSpacing.md),
          _NutritionRow(
            fieldKey: const ValueKey('quick-add-fat'),
            controller: _fat,
            label: 'Fat',
            unit: 'g',
          ),
          // Breathing room at the end of the body. The footer's rule now sits
          // flush against the scroll view, so without this the last field
          // touches the line.
          const SizedBox(height: TioSpacing.lg),
        ],
      ),
      actions: MealLogActionFooter(
        // Neutral on purpose. TNYX-67 owns what a meal category is — the V1
        // defaults, renaming, custom ones, hiding, ordering and the eight-
        // category ceiling — so naming Breakfast here would be this screen
        // inventing a second, weaker version of that.
        mealCategoryLabel: 'Meal type',
        mealCategorySemanticLabel: 'Meal type. Not available yet.',
        // The real selected day, and a time that is honestly unresolved:
        // TNYX-114 owns consumed time, so there is no correct value to show
        // and inventing one would be the screenshot talking, not the app.
        dateTimeLabel: '$selectedDateLabel · Time',
        dateTimeSemanticLabel:
            'Date and time. $selectedDateLabel, time not set. '
            'Not available yet.',
        primaryLabel: 'Log Meal',
        primarySemanticLabel: 'Log Meal. Not available yet.',
        note: 'Saving is not available yet.',
      ),
    );
  }
}

/// One coarse nutrition value: label on the left, a compact number on the
/// right.
///
/// Blank means absent, not zero: the reader who skips Carbs has not told the
/// app they ate none, and this slice must not turn silence into a number. That
/// distinction is the reason the field carries no default text.
///
/// ## Why there is no input formatter
///
/// A character allow-list looks like the safe option and is the opposite of
/// one. Filtering does not reject the input — it edits it, and the edit lands
/// on a value that is still a number:
///
/// ```text
/// 1,5       → 1 5     → 15
/// 1e400abc  → 1 400   → 1400
/// ```
///
/// The reader typed one number and the field kept a different one, with no
/// error to notice. Per-keystroke rejection has the same ending: refuse the
/// comma in `1,5` and the following `5` still lands on the `1`.
///
/// So nothing is filtered. Whatever is typed stays visible, and [_error]
/// decides whether it is a number. The reader either sees their own value or
/// sees why it is not accepted; the field never quietly holds a third thing.
class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.unit,
  });

  /// Width of the value box. Wide enough for any calorie count anyone eats,
  /// narrow enough that the label keeps the row.
  static const _valueWidth = TioSize.dp100;

  final ValueKey<String> fieldKey;
  final TextEditingController controller;
  final String label;
  final String unit;

  /// Whether the current text is a usable coarse nutrition value, and if not,
  /// why.
  ///
  /// Parsing is deliberately not locale-aware. A comma is the decimal point in
  /// one locale and the thousands separator in another, so reading `1,5` as
  /// `1.5` in one place means reading `1,500` as `1.5` in another — which is
  /// the same silent wrong number the formatter used to produce, arrived at
  /// more politely. Until a repo-wide numeric-input slice can carry a real
  /// locale contract, an unsupported separator is refused out loud rather than
  /// guessed at.
  String? get _error {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    // `1e400` parses to infinity rather than failing, so finiteness is a
    // separate question from parseability.
    if (value == null || !value.isFinite) return 'Enter a number.';
    if (value < 0) return '$label cannot be negative.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final error = _error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$label ($unit)',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: TioFontSize.size15,
                  fontWeight: TioFontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.md),
            SizedBox(
              width: _valueWidth,
              child: TioInput.numericEditor(
                key: fieldKey,
                controller: controller,
                hint: '0',
                // The keyboard suggests the shape of the answer; it does not
                // enforce it. Enforcement is [_error]'s job, so a hardware
                // keyboard or a paste can put anything here and still be told
                // what is wrong with it.
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                // Shorter than the editor default: four of these stacked read
                // as a list of numbers, and each one only ever holds a few
                // characters.
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.md,
                  vertical: TioSpacing.sm,
                ),
                onChanged: (_) {},
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: TioSpacing.xs),
          Text(
            error,
            key: ValueKey('${fieldKey.value}-error'),
            style: TextStyle(
              color: colors.danger,
              fontSize: TioFontSize.size13,
            ),
          ),
        ],
      ],
    );
  }
}
