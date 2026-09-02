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
        blockers: AdditionalNutrientRecommendationPolicy.blockersFor(
          nutrientId: nutrientId,
          caloriesKcal: caloriesKcal,
          dateOfBirth: dateOfBirth,
          now: now ?? DateTime.now(),
        ),
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
            // A payload written by a newer schema is decoded as read-only. It
            // must not be rendered as four unconfigured goals: that would
            // invite edits this build cannot express, and the first the user
            // would hear of the incompatibility is a generic save failure.
            if (!goals.isWritable) ...[
              const _UnsupportedSchemaNotice(
                key: ValueKey('additional-nutrient-unsupported-schema'),
              ),
              const SizedBox(height: TioSpacing.lg),
            ] else ...[
              const NutritionSettingsSectionHeader(title: 'DAILY GOALS'),
              TioGroupCard(
                children: [
                  for (final (nutrientId, label, icon) in _nutrients)
                    _row(context, nutrientId, label, icon),
                ],
              ),
              const SizedBox(height: TioSpacing.lg),
              Text(
                'Recommendations use your Calories target and date of birth, '
                'and are shown for ages 19 and over. Your own value always '
                'takes priority when you set one.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: TioFontSize.size13,
                  height: TioLineHeight.height140,
                ),
              ),
            ],
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
            value: _summaryFor(nutrientId, goal, effective, recommendation),
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
    NutrientRecommendation recommendation,
  ) {
    if (goal == null) return 'Not set';
    if (effective == null) return 'Unavailable';
    return formatNutrientGoalAmount(
      nutrientId,
      effective,
      recommendation.comparison,
    );
  }
}

/// Shows a stored custom value that currently has no derivable recommendation
/// behind it.
///
/// The value stays visible and stays stored: losing a number the user chose,
/// just because a date of birth went missing, would be the worse failure. It
/// is not editable here, because editing would require a recommendation to
/// override.
class _PreservedCustomValue extends StatelessWidget {
  const _PreservedCustomValue({
    required this.nutrientId,
    required this.value,
    required this.comparison,
    super.key,
  });

  final NutrientId nutrientId;
  final double value;
  final NutrientGoalComparison comparison;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      padding: const EdgeInsets.all(TioSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(TioRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Your saved goal',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size13,
              fontWeight: TioFontWeight.w600,
            ),
          ),
          Text(
            formatNutrientGoalAmount(nutrientId, value, comparison),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: TioFontSize.size16,
              fontWeight: TioFontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the goal rows when the stored payload comes from a newer
/// schema. Read-only by construction: there is nothing to tap, so no edit can
/// be started and the payload is never rewritten.
class _UnsupportedSchemaNotice extends StatelessWidget {
  const _UnsupportedSchemaNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      padding: const EdgeInsets.all(TioSpacing.lg),
      decoration: BoxDecoration(
        color: colors.info.withAlpha(TioAlpha.alpha12),
        borderRadius: BorderRadius.circular(TioRadius.lg),
        border: Border.all(color: colors.info.withAlpha(TioAlpha.alpha40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved on a newer version',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w700,
              fontSize: TioFontSize.size15,
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          Text(
            'Your Additional Nutrient Goals were saved by a newer version of '
            'Tio, so they cannot be shown or edited here. Nothing has been '
            'changed. Update the app to manage them again.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size13,
              height: TioLineHeight.height140,
            ),
          ),
        ],
      ),
    );
  }
}

/// A goal amount with its comparator, for a summary line.
///
/// Sodium's contract is strictly *below* 2000 mg, so rendering a bare
/// "2,000 mg" would present the forbidden boundary as the goal itself. The
/// comparator belongs to the nutrient's policy rather than to the value's
/// source, so it is carried whether the amount is recommended or custom.
String formatNutrientGoalAmount(
  NutrientId nutrientId,
  double value,
  NutrientGoalComparison comparison,
) {
  final amount = formatNutrientAmount(nutrientId, value);
  return comparison == NutrientGoalComparison.lessThan ? '< $amount' : amount;
}

/// Display precision for a goal amount.
///
/// Grams normally keep one decimal because the derived maxima land on values
/// like 22.2 g, and milligrams and micrograms are whole numbers at these
/// magnitudes. A custom override may be far smaller than that default, so the
/// precision is widened as needed rather than rendering a real value as "0" —
/// showing "0 g" for a stored 0.04 g would misreport the user's own goal, and
/// an explicit zero has its own distinct meaning here.
String formatNutrientAmount(NutrientId nutrientId, double value) {
  final unit = nutrientId.canonicalUnit;
  final defaultDecimals = unit == NutrientUnit.g ? 1 : 0;

  var text = _trimTrailingZero(value.toStringAsFixed(defaultDecimals));
  if (value != 0 && double.tryParse(text) == 0) {
    for (var decimals = defaultDecimals + 1; decimals <= 6; decimals++) {
      text = _trimTrailingZero(value.toStringAsFixed(decimals));
      if (double.tryParse(text) != 0) break;
    }
  }
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
    required this.blockers,
    required this.onApply,
  });

  final NutrientId nutrientId;
  final String label;
  final AdditionalNutrientGoal? goal;
  final NutrientRecommendation recommendation;

  /// Unmet prerequisites for this nutrient, so the copy can name the input
  /// that would actually unblock it rather than every input V1 knows about.
  final Set<NutrientRecommendationBlocker> blockers;

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

  /// Already enabled and following the recommendation, so there is nothing for
  /// "Use Recommended" to change.
  bool get _isOnRecommendation =>
      widget.goal != null && widget.goal!.usesRecommendation;

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
      // Zero is a valid, meaningful goal here (a trans-fat target of 0), so
      // the copy must not imply it is rejected.
      setState(() => _error = 'Enter zero or a higher number of '
          '${widget.nutrientId.canonicalUnit.storageValue}.');
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
            hint: recommended == null ? '' : _readableNumber(recommended),
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
        // Owner decision: an unconfigured nutrient whose recommendation cannot
        // be derived is not enableable. Turning it on would create a goal with
        // nothing to show and no permitted way to set it, and letting the user
        // type a value instead would use Custom to bypass the eligibility rule
        // the policy exists to enforce. An already-configured goal keeps its
        // stored value and can still be turned off, below.
        if (_canOverride)
          TioButton.primary(
            key: const ValueKey('additional-nutrient-goal-save'),
            label: 'Save',
            loading: _isSaving,
            expand: true,
            onPressed: _saveCustom,
          )
        else if (_isConfigured && widget.goal!.customValue != null)
          _PreservedCustomValue(
            key: const ValueKey('additional-nutrient-goal-preserved-custom'),
            nutrientId: widget.nutrientId,
            value: widget.goal!.customValue!,
            comparison: widget.recommendation.comparison,
          ),
        // Offered whenever the goal is not already sitting on the
        // recommendation, which covers two paths to the same state: an
        // unconfigured nutrient opting in (Not set -> Recommended, without
        // being forced to invent a Custom value first), and a custom goal
        // reverting. Both persist `custom_value: null`, which is the stored
        // Recommended state. Gated on `_canOverride`, so an unavailable
        // recommendation still offers no way to enable anything.
        if (_canOverride && !_isOnRecommendation) ...[
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
    if (recommended == null) return _unavailableGuidance();
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

  /// Names only the prerequisites this nutrient actually uses.
  ///
  /// Sodium and Vitamin D are fixed amounts gated on age alone, so pointing
  /// those users at a Calories target would send them to fix something
  /// unrelated. Age below the minimum is stated as an eligibility fact rather
  /// than as something to correct — the date of birth is not wrong.
  String _unavailableGuidance() {
    const eligibility = 'Recommendations are available for ages '
        '${AdditionalNutrientRecommendationPolicy.minimumAge} and over.';
    final needsCalories =
        widget.blockers.contains(NutrientRecommendationBlocker.caloriesMissing);

    if (widget.blockers
        .contains(NutrientRecommendationBlocker.dateOfBirthMissing)) {
      final calories =
          needsCalories ? ' You will also need a Calories target.' : '';
      return 'Add your date of birth to check eligibility. $eligibility'
          '$calories';
    }

    if (widget.blockers
        .contains(NutrientRecommendationBlocker.ageBelowMinimum)) {
      return 'This recommendation is available for ages '
          '${AdditionalNutrientRecommendationPolicy.minimumAge} and over.';
    }

    if (needsCalories) {
      return 'Set your Calories target to see this recommendation.';
    }

    return 'This recommendation is not available right now.';
  }
}

/// Guidance copy reads as prose, so four-digit amounts are grouped: "less than
/// 2,000 mg/day" rather than "2000". Prose is also rounded for readability —
/// a recommendation of 22.222... reads as 22.2 here. This is display only and
/// never reaches storage or the editable field.
String _plainNumber(double value) => _groupThousands(_readableNumber(value));

String _readableNumber(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return _trimTrailingZero(text);
}

/// The same number without grouping, for anything that will be parsed back.
/// A grouped "1,500" would fail `double.tryParse` on save.
///
/// Non-integers use `toString()`, which is the shortest representation that
/// round-trips exactly. Rounding here would be a silent data change: the
/// domain accepts any finite nonnegative value, so a stored 0.04 must reopen
/// as 0.04 and not as 0, or merely reopening and saving the editor would
/// overwrite the user's number.
String _editableNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

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
