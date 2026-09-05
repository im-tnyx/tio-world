import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:tio_core/core.dart';

import 'meal_log_action_footer.dart';

/// Opens a brand-new Quick Add manual nutrition editor.
Future<void> showQuickAddEditorSheet(
  BuildContext context, {
  DateTime Function()? clock,
}) {
  return showTioEditorSheet<void>(
    context: context,
    // Same reason as the Add Food sheet: the diary sits inside a shell branch
    // navigator, and an editor holding a captured date must not leave the
    // Today action or the tabs reachable behind it.
    useRootNavigator: true,
    // And the same reason again for the top: without this the route strips the
    // top padding, so a keyboard-raised or split-screen viewport can push the
    // handle and title under the status bar.
    useSafeArea: true,
    builder: (_) => QuickAddEditorSheet(clock: clock),
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
/// Meal type ▼        🗓 Sep 6, 00:07
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
/// Every value, including the selected local DateTime, lives in this `State`
/// and dies with the route. There is no notifier, repository or store behind
/// it. Reopening a brand-new Quick Add takes a fresh current-local snapshot.
class QuickAddEditorSheet extends StatefulWidget {
  const QuickAddEditorSheet({super.key, this.clock});

  /// Optional local clock seam. Production uses `DateTime.now`.
  final DateTime Function()? clock;

  @override
  State<QuickAddEditorSheet> createState() => _QuickAddEditorSheetState();
}

class _QuickAddEditorSheetState extends State<QuickAddEditorSheet> {
  final _dateTimePickerKey = GlobalKey();
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
  late DateTime _draftDateTime;
  late DateTime _maximumCalendarDate;
  var _isDateTimePickerOpen = false;

  @override
  void initState() {
    super.initState();
    final openedAt = _currentLocalMinute();
    _draftDateTime = openedAt;
    _maximumCalendarDate = _dateOnly(openedAt);
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

  DateTime _currentLocalMinute() {
    final value = widget.clock?.call() ?? DateTime.now();
    return DateTime(value.year, value.month, value.day, value.hour, value.minute);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _resolveMealDateTime(DateTime candidate) {
    // The wheel has minute precision. Compare its zero-second candidate to the
    // real clock, then snap to the real minute floor. Hidden seconds can never
    // make the same visible minute inconsistently valid or invalid.
    final now = _currentLocalMinute();
    _maximumCalendarDate = _dateOnly(now);
    return candidate.isAfter(now) ? now : candidate;
  }

  void _refreshMaximumCalendarDate() {
    final maximum = _dateOnly(_currentLocalMinute());
    if (maximum == _maximumCalendarDate) return;
    setState(() => _maximumCalendarDate = maximum);
  }

  void _onDateTimeChanged(DateTime value) {
    setState(() => _draftDateTime = value);
  }

  void _toggleDateTimePicker() {
    FocusScope.of(context).unfocus();
    setState(() => _isDateTimePickerOpen = !_isDateTimePickerOpen);
    if (!_isDateTimePickerOpen) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pickerContext = _dateTimePickerKey.currentContext;
      if (!mounted || pickerContext == null) return;
      Scrollable.ensureVisible(
        pickerContext,
        alignment: 1,
        duration: const Duration(milliseconds: TioDuration.ms200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final selectedDateLabel =
        localizations.formatShortMonthDay(_draftDateTime);
    final selectedTimeLabel =
        '${_draftDateTime.hour.toString().padLeft(2, '0')}:'
        '${_draftDateTime.minute.toString().padLeft(2, '0')}';
    final dateTimeLabel = '$selectedDateLabel, $selectedTimeLabel';

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
          const SizedBox(height: TioSpacing.lg),
          if (_isDateTimePickerOpen)
            KeyedSubtree(
              key: _dateTimePickerKey,
              child: TioCard(
                key: const ValueKey('quick-add-date-time-picker-card'),
                variant: TioCardVariant.normal,
                padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
                child: Listener(
                  onPointerDown: (_) => _refreshMaximumCalendarDate(),
                  child: TioDateTimeWheelPicker(
                    value: _draftDateTime,
                    maximumDate: _maximumCalendarDate,
                    today: _maximumCalendarDate,
                    resolveDateTime: _resolveMealDateTime,
                    onChanged: _onDateTimeChanged,
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: MealLogActionFooter(
        // Neutral on purpose. TNYX-67 owns what a meal category is — the V1
        // defaults, renaming, custom ones, hiding, ordering and the eight-
        // category ceiling — so naming Breakfast here would be this screen
        // inventing a second, weaker version of that.
        mealCategoryLabel: 'Meal type',
        mealCategorySemanticLabel: 'Meal type. Not available yet.',
        dateTimeLabel: dateTimeLabel,
        dateTimeSemanticLabel:
            'Date and time. $dateTimeLabel. '
            'Picker ${_isDateTimePickerOpen ? 'expanded' : 'collapsed'}.',
        onDateTimeTap: _toggleDateTimePicker,
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
              // The line below is the visible half of the error; this is the
              // half a screen reader needs. Without it the field keeps
              // reporting itself valid while a separate `Text` somewhere else
              // says otherwise, so someone on TalkBack hears nothing wrong
              // about the field they are actually sitting in.
              child: Semantics(
                validationResult: error == null
                    ? SemanticsValidationResult.none
                    : SemanticsValidationResult.invalid,
                child: TioInput.numericEditor(
                  key: fieldKey,
                  controller: controller,
                  hint: '0',
                  // The keyboard suggests the shape of the answer; it does not
                  // enforce it. Enforcement is [_error]'s job, so a hardware
                  // keyboard or a paste can put anything here and still be
                  // told what is wrong with it.
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  // Shorter than the editor default: four of these stacked
                  // read as a list of numbers, and each one only ever holds a
                  // few characters.
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: TioSpacing.md,
                    vertical: TioSpacing.sm,
                  ),
                  onChanged: (_) {},
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: TioSpacing.xs),
          // A live region so the message is announced when it appears, rather
          // than only being found by someone who happens to move past it.
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              key: ValueKey('${fieldKey.value}-error'),
              style: TextStyle(
                color: colors.danger,
                fontSize: TioFontSize.size13,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
