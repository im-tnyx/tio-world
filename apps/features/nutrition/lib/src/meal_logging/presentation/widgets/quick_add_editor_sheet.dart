import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

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
    builder: (_) => QuickAddEditorSheet(selectedDate: selectedDate),
  );
}

/// The manual/coarse nutrition editor shell.
///
/// This is the surface TNYX-115 will eventually give a durable `MealLogEntry`
/// to. Today it has no owner behind it at all: every value lives in this
/// `State`'s own text controllers and dies with the route. There is no
/// notifier, no repository, no store and no draft, which is why backing out
/// leaves nothing behind — not because a teardown path clears something, but
/// because there was never anything to clear.
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
/// ## What is deliberately absent
///
/// Meal category, because no canonical `MealCategory` exists in runtime source
/// and N13 owns it; and consumed time, because TNYX-114 owns it and nothing
/// here would consume a draft time. The selected date is shown read-only for
/// the same reason: displaying the day the reader picked is honest, while
/// editing it would imply a date/time contract this slice does not own.
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
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();

  late final List<TextEditingController> _all = [
    _mealName,
    _calories,
    _protein,
    _carbs,
    _fat,
    _fiber,
  ];

  @override
  void initState() {
    super.initState();
    // Validation is per-keystroke because the errors are about the characters
    // themselves, not about a submission that cannot happen here.
    for (final controller in _all) {
      controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _all) {
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
    final colors = context.tioColors;

    return TioEditorSheet(
      key: const ValueKey('quick-add-editor'),
      title: 'Quick Add',
      supportingText: 'Calories are the one value a coarse entry needs. '
          'Everything else is optional — a blank field stays unrecorded '
          'rather than becoming zero.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TioInput(
            key: const ValueKey('quick-add-meal-name'),
            controller: _mealName,
            label: 'Meal name',
            hint: 'Optional',
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {},
          ),
          const SizedBox(height: TioSpacing.lg),
          _NutritionField(
            fieldKey: const ValueKey('quick-add-calories'),
            controller: _calories,
            label: 'Calories',
            unit: 'kcal',
          ),
          const SizedBox(height: TioSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NutritionField(
                  fieldKey: const ValueKey('quick-add-protein'),
                  controller: _protein,
                  label: 'Protein',
                  unit: 'g',
                ),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(
                child: _NutritionField(
                  fieldKey: const ValueKey('quick-add-carbs'),
                  controller: _carbs,
                  label: 'Carbs',
                  unit: 'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _NutritionField(
                  fieldKey: const ValueKey('quick-add-fat'),
                  controller: _fat,
                  label: 'Fat',
                  unit: 'g',
                ),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(
                child: _NutritionField(
                  fieldKey: const ValueKey('quick-add-fiber'),
                  controller: _fiber,
                  label: 'Fiber',
                  unit: 'g',
                ),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.lg),
          TioGroupCard(
            children: [
              TioSettingsReadOnlyRow(
                key: const ValueKey('quick-add-selected-date'),
                label: 'Date',
                value: MaterialLocalizations.of(context)
                    .formatFullDate(widget.selectedDate),
                isUnset: false,
              ),
            ],
          ),
        ],
      ),
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Saving a meal is not available yet, so nothing typed here is '
            'recorded.',
            key: const ValueKey('quick-add-unavailable-note'),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size13,
            ),
          ),
          const SizedBox(height: TioSpacing.md),
          const TioButton.primary(
            key: ValueKey('quick-add-log-meal'),
            label: 'Log Meal',
            semanticLabel: 'Log Meal. Not available yet.',
            expand: true,
            onPressed: null,
          ),
        ],
      ),
    );
  }
}

/// One coarse nutrition value.
///
/// Blank means absent, not zero: the reader who skips Fiber has not told the
/// app they ate no fiber, and this slice must not turn silence into a number.
/// That distinction is the reason the field carries no default text.
class _NutritionField extends StatelessWidget {
  const _NutritionField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.unit,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String unit;

  /// The characters a nutrition value can be made of.
  ///
  /// The minus sign is allowed through deliberately, so a reader who types one
  /// is told why it is wrong instead of watching a keystroke vanish. The
  /// rejection below is what makes the value safe, not the keyboard.
  static final _allowed = FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'));

  String? get _error {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return 'Enter a number.';
    if (value < 0) return '$label cannot be negative.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TioInput(
      key: fieldKey,
      controller: controller,
      label: label,
      hint: '0',
      suffixText: unit,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_allowed],
      errorText: _error,
      onChanged: (_) {},
    );
  }
}
