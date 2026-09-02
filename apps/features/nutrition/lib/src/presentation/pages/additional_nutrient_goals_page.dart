import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/domain.dart';
import '../widgets/nutrition_settings_widgets.dart';

/// Nutrition-owned editor for the four authorized Additional Nutrient Goals.
///
/// Recommendations are runtime derivations of canonical Calories and Profile
/// date of birth, so this screen never stores one. It stores only whether a
/// nutrient is configured and, when the user overrides it, the explicit custom
/// value. Routing and canonical inputs are supplied by app composition.
class AdditionalNutrientGoalsPage extends StatelessWidget {
  const AdditionalNutrientGoalsPage({
    required this.goals,
    required this.caloriesKcal,
    required this.dateOfBirth,
    required this.onSave,
    super.key,
    this.now,
  });

  /// Currently configured goals. An empty set is the normal first-run state,
  /// not an error.
  final AdditionalNutrientGoalSet goals;

  /// Canonical Calories target. Null makes the percentage-derived
  /// recommendations underivable rather than defaulted.
  final int? caloriesKcal;

  /// Canonical Profile date of birth, used only to derive eligibility and the
  /// Vitamin D band. It is never copied into goal storage.
  final DateTime? dateOfBirth;

  /// Persists the merged goal set through the canonical owner.
  final Future<void> Function(AdditionalNutrientGoalSet goals) onSave;

  /// Injectable clock so age boundaries are testable.
  final DateTime? now;

  /// Fixed display order: the two calorie-derived maxima, then sodium, then
  /// the one target-type nutrient.
  static const _nutrients = <(NutrientId, String, IconData)>[
    (NutrientId.saturatedFat, 'Saturated Fat', Icons.opacity_rounded),
    (NutrientId.transFat, 'Trans Fat', Icons.block_rounded),
    (NutrientId.sodium, 'Sodium', Icons.grain_rounded),
    (NutrientId.vitaminD, 'Vitamin D', Icons.wb_sunny_rounded),
  ];

  NutrientRecommendation _recommendationFor(NutrientId nutrientId) =>
      AdditionalNutrientRecommendationPolicy.derive(
        nutrientId: nutrientId,
        caloriesKcal: caloriesKcal,
        dateOfBirth: dateOfBirth,
        now: now ?? DateTime.now(),
      );

  Future<void> _edit(
    BuildContext context,
    NutrientId nutrientId,
    String label,
  ) async {
    await showTioEditorSheet<void>(
      context: context,
      builder: (context) => _GoalEditorSheet(
        nutrientId: nutrientId,
        label: label,
        goal: goals[nutrientId],
        recommendation: _recommendationFor(nutrientId),
        onApply: (updated) => onSave(updated == null
            ? goals.without(nutrientId)
            : goals.withGoal(updated)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Additional Nutrient Goals',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.md,
            TioSpacing.lg,
            TioSpacing.xl,
          ),
          children: [
            const NutritionSettingsSectionHeader(title: 'DAILY GOALS'),
            TioGroupCard(
              children: [
                for (final (nutrientId, label, icon) in _nutrients)
                  _row(context, nutrientId, label, icon),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            Text(
              'Recommendations use your Calories target and date of birth, and '
              'are shown for ages 19 and over. Your own value always takes '
              'priority when you set one.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size13,
                height: TioLineHeight.height140,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    NutrientId nutrientId,
    String label,
    IconData icon,
  ) {
    final goal = goals[nutrientId];
    final recommendation = _recommendationFor(nutrientId);
    final effective = recommendation.effectiveValueFor(goal);

    return TioSettingsValueRow(
      key: ValueKey('additional-nutrient-${nutrientId.storageValue}-field'),
      leading: Icon(
        icon,
        size: TioSize.dp24,
        color: context.tioColors.textPrimary,
      ),
      label: label,
      labelSingleLine: true,
      // The state caption sits under the amount rather than in `annotation`:
      // beside a label like "Saturated Fat", the word "Recommended" is far
      // wider than the macro screen's "30%" and overflows the row on a narrow
      // phone. The value column has the room, and keeping both states visible
      // is what makes Recommended and Custom distinguishable at a glance.
      value: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          TioSettingsValueText(
            value: _summaryFor(nutrientId, goal, effective),
            isUnset: effective == null,
          ),
          if (_stateCaptionFor(goal, recommendation) case final caption?)
            Text(
              caption,
              style: TextStyle(
                color: context.tioColors.textSecondary,
                fontSize: TioFontSize.size12,
                fontWeight: TioFontWeight.w600,
              ),
            ),
        ],
      ),
      onTap: () => _edit(context, nutrientId, label),
    );
  }

  /// Distinguishes the configured states. An unconfigured nutrient needs no
  /// caption: "Not set" already says it.
  static String? _stateCaptionFor(
    AdditionalNutrientGoal? goal,
    NutrientRecommendation recommendation,
  ) {
    if (goal == null) return null;
    if (!goal.usesRecommendation) return 'Custom';
    return recommendation.isAvailable ? 'Recommended' : null;
  }

  static String _summaryFor(
    NutrientId nutrientId,
    AdditionalNutrientGoal? goal,
    double? effective,
  ) {
    if (goal == null) return 'Not set';
    if (effective == null) return 'Unavailable';
    return formatNutrientAmount(nutrientId, effective);
  }
}

/// Display precision for a goal amount.
///
/// Grams keep one decimal because the derived maxima land on values like
/// 22.2 g; milligrams and micrograms are whole numbers at these magnitudes.
/// Rounding happens only here, never before effective-value resolution.
String formatNutrientAmount(NutrientId nutrientId, double value) {
  final unit = nutrientId.canonicalUnit;
  final text = unit == NutrientUnit.g
      ? _trimTrailingZero(value.toStringAsFixed(1))
      : _trimTrailingZero(value.toStringAsFixed(0));
  return '$text ${unit.storageValue}';
}

String _trimTrailingZero(String value) =>
    value.contains('.') ? value.replaceFirst(RegExp(r'\.?0+$'), '') : value;

/// Editor for one goal: enable, override, revert to the recommendation, or
/// disable. It never invents a value the policy could not derive.
class _GoalEditorSheet extends StatefulWidget {
  const _GoalEditorSheet({
    required this.nutrientId,
    required this.label,
    required this.goal,
    required this.recommendation,
    required this.onApply,
  });

  final NutrientId nutrientId;
  final String label;
  final AdditionalNutrientGoal? goal;
  final NutrientRecommendation recommendation;

  /// Null removes the goal; a value enables or updates it.
  final Future<void> Function(AdditionalNutrientGoal? goal) onApply;

  @override
  State<_GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends State<_GoalEditorSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  String? _error;

  bool get _isConfigured => widget.goal != null;
  bool get _canOverride => widget.recommendation.isAvailable;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.goal?.customValue == null
          ? ''
          : _editableNumber(widget.goal!.customValue!),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply(AdditionalNutrientGoal? goal) async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onApply(goal);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveCustom() async {
    final raw = _controller.text.trim();
    final parsed = double.tryParse(raw);
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      setState(() => _error = 'Enter a number of '
          '${widget.nutrientId.canonicalUnit.storageValue} or more than zero.');
      return;
    }
    await _apply(AdditionalNutrientGoal(
      nutrientId: widget.nutrientId,
      customValue: parsed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final unit = widget.nutrientId.canonicalUnit.storageValue;
    final recommended = widget.recommendation.recommendedValue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size18,
          ),
        ),
        const SizedBox(height: TioSpacing.sm),
        Text(
          _guidance(recommended, unit),
          key: const ValueKey('additional-nutrient-goal-guidance'),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: TioFontSize.size13,
            height: TioLineHeight.height140,
          ),
        ),
        const SizedBox(height: TioSpacing.lg),
        if (_canOverride) ...[
          TioInput(
            key: const ValueKey('additional-nutrient-goal-input'),
            controller: _controller,
            label: 'Your value',
            hint: recommended == null ? '' : _editableNumber(recommended),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            trailing: Text(
              unit,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: TioFontWeight.w600,
              ),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: TioSpacing.md),
        ],
        if (_error case final error?) ...[
          Text(
            error,
            key: const ValueKey('additional-nutrient-goal-error'),
            style: TextStyle(
              color: colors.danger,
              fontSize: TioFontSize.size13,
              fontWeight: TioFontWeight.w600,
            ),
          ),
          const SizedBox(height: TioSpacing.md),
        ],
        if (_canOverride)
          TioButton.primary(
            key: const ValueKey('additional-nutrient-goal-save'),
            label: 'Save',
            loading: _isSaving,
            expand: true,
            onPressed: _saveCustom,
          )
        else if (!_isConfigured)
          TioButton.primary(
            key: const ValueKey('additional-nutrient-goal-enable'),
            label: 'Turn on',
            loading: _isSaving,
            expand: true,
            onPressed: () => _apply(
              AdditionalNutrientGoal(nutrientId: widget.nutrientId),
            ),
          ),
        if (_canOverride &&
            _isConfigured &&
            !widget.goal!.usesRecommendation) ...[
          const SizedBox(height: TioSpacing.sm),
          TioButton.secondary(
            key: const ValueKey('additional-nutrient-goal-use-recommended'),
            label: 'Use Recommended',
            expand: true,
            onPressed: _isSaving
                ? null
                : () => _apply(
                      AdditionalNutrientGoal(nutrientId: widget.nutrientId),
                    ),
          ),
        ],
        if (_isConfigured) ...[
          const SizedBox(height: TioSpacing.sm),
          TextButton(
            key: const ValueKey('additional-nutrient-goal-remove'),
            onPressed: _isSaving ? null : () => _apply(null),
            child: Text(
              'Turn off',
              style: TextStyle(
                color: colors.danger,
                fontWeight: TioFontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _guidance(double? recommended, String unit) {
    if (recommended == null) {
      return 'A recommendation needs your Calories target and a date of birth '
          'of 19 years or older. You can still turn this goal on and set it '
          'once that information is available.';
    }
    return switch (widget.recommendation.comparison) {
      // Sodium is a strict boundary, and the wording has to say so.
      NutrientGoalComparison.lessThan =>
        'Recommended: less than ${_plainNumber(recommended)} $unit/day.',
      NutrientGoalComparison.atMost =>
        'Recommended: at most ${_plainNumber(recommended)} $unit/day.',
      NutrientGoalComparison.target =>
        'Recommended: ${_plainNumber(recommended)} $unit/day.',
    };
  }
}

/// Guidance copy reads as prose, so four-digit amounts are grouped: "less than
/// 2,000 mg/day" rather than "2000".
String _plainNumber(double value) => _groupThousands(_editableNumber(value));

/// The same number without grouping, for anything that will be parsed back.
/// A grouped "1,500" would fail `double.tryParse` on save.
String _editableNumber(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return _trimTrailingZero(text);
}

String _groupThousands(String value) {
  final parts = value.split('.');
  final digits = parts.first;
  if (digits.length < 4) return value;

  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) grouped.write(',');
    grouped.write(digits[index]);
  }
  return parts.length > 1 ? '$grouped.${parts[1]}' : grouped.toString();
}
