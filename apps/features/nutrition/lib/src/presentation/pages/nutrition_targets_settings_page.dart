import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../domain/domain.dart';
import '../widgets/nutrition_settings_widgets.dart';
import 'nutrition_macros_editor_sheet.dart';
import 'nutrition_profile_settings_page.dart'
    show NutritionEditorSheet, showNutritionEditorSheet;

/// Nutrition-owned editor for the canonical core five daily targets.
///
/// V1 is grams-first: no percentage mode, and no recommendation is ever
/// re-derived here. The screen edits the same canonical row Product Onboarding
/// wrote, through the same owner.
class NutritionTargetsSettingsPage extends StatelessWidget {
  const NutritionTargetsSettingsPage({
    required this.targets,
    required this.onSave,
    super.key,
  });

  /// Current canonical targets. A missing row is an all-null object rather
  /// than a separate empty state, so first-time editing needs no setup flow.
  final NutritionTargetsData targets;

  /// Persists a fully merged target row through the canonical owner.
  final Future<void> Function(NutritionTargetsData targets) onSave;

  /// Carbohydrates first, matching how the three macro shares are read.
  static const _macros = <(NutritionTargetField, String, IconData)>[
    (
      NutritionTargetField.carbohydrate,
      'Carbohydrates',
      Icons.bakery_dining_rounded
    ),
    (NutritionTargetField.protein, 'Protein', Icons.egg_alt_rounded),
    (NutritionTargetField.fat, 'Fat', Icons.water_drop_rounded),
  ];

  static String unitFor(NutritionTargetField field) =>
      field == NutritionTargetField.calories ? 'kcal' : 'g';

  String _summaryFor(NutritionTargetField field, String unit) {
    final value = NutritionTargetEditor.valueOf(targets, field);
    if (value == null) return 'Not set';
    return '${_formatNumber(value)} $unit';
  }

  Future<void> _edit(
    BuildContext context,
    NutritionTargetField field,
    String label,
    String unit,
  ) async {
    await showNutritionEditorSheet<void>(
      context: context,
      builder: (context) => _TargetEditorSheet(
        field: field,
        label: label,
        unit: unit,
        current: targets,
        onSave: onSave,
      ),
    );
  }

  Future<void> _editMacros(BuildContext context) async {
    await showNutritionEditorSheet<void>(
      context: context,
      builder: (context) => NutritionMacrosEditorSheet(
        current: targets,
        onSave: onSave,
      ),
    );
  }

  Widget _row(
    BuildContext context,
    NutritionTargetField field,
    String label,
    IconData icon, {
    String? annotation,
    VoidCallback? onTap,
    bool showEditAffordance = true,
  }) {
    final unit = unitFor(field);
    return NutritionValueRow(
      key: ValueKey('nutrition-target-${field.storageValue}-field'),
      icon: icon,
      label: label,
      annotation: annotation,
      value: _summaryFor(field, unit),
      isUnset: NutritionTargetEditor.valueOf(targets, field) == null,
      showEditAffordance: showEditAffordance,
      onTap: onTap ?? () => _edit(context, field, label, unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final coherence = NutritionTargetEditor.coherenceOf(targets);
    final percentages = NutritionTargetEditor.macroPercentages(targets);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Nutrition Targets',
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
            const NutritionSettingsSectionHeader(title: 'DAILY CALORIE GOAL'),
            NutritionSettingsGroupCard(
              children: [
                _row(context, NutritionTargetField.calories, 'Calories',
                    Icons.local_fire_department_rounded)
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            NutritionSettingsSectionHeader(
              title: 'MACRONUTRIENTS',
              // One pencil for the whole card: the three macros define each
              // other's share and the calorie check, so they are edited
              // together rather than one at a time.
              trailing: NutritionEditPencil(
                key: const ValueKey('nutrition-target-macros-pencil'),
                onPressed: () => _editMacros(context),
              ),
            ),
            NutritionSettingsGroupCard(
              children: [
                for (final (field, label, icon) in _macros)
                  _row(context, field, label, icon,
                      annotation:
                          percentages == null ? null : '${percentages[field]}%',
                      showEditAffordance: false,
                      onTap: () => _editMacros(context)),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            // Fiber is deliberately its own card: it is an independent target
            // and is excluded from the C/P/F energy relationship.
            const NutritionSettingsSectionHeader(title: 'FIBER'),
            NutritionSettingsGroupCard(
              children: [
                _row(context, NutritionTargetField.fiber, 'Fiber',
                    Icons.grass_rounded),
              ],
            ),
            if (coherence.isEvaluable && !coherence.blocksSave) ...[
              const SizedBox(height: TioSpacing.lg),
              _MacroCaloriesFooter(coherence: coherence),
            ],
            if (coherence.blocksSave) ...[
              const SizedBox(height: TioSpacing.lg),
              _CoherenceWarning(coherence: coherence),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quiet confirmation that the macros and the calorie target agree.
///
/// Informational only: within tolerance there is nothing for the user to fix,
/// so this deliberately carries no warning treatment.
class _MacroCaloriesFooter extends StatelessWidget {
  const _MacroCaloriesFooter({required this.coherence});

  final NutritionTargetCoherence coherence;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Padding(
      key: const ValueKey('nutrition-targets-macro-calories'),
      padding: const EdgeInsets.symmetric(horizontal: TioSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Calories from macros',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size13,
              ),
            ),
          ),
          Text(
            '${_formatNumber(coherence.macroCalories!)} kcal',
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: TioFontWeight.w600,
              fontSize: TioFontSize.size13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Surfaces a material mismatch on the page itself, so the user is not first
/// told about it only after opening an unrelated editor.
class _CoherenceWarning extends StatelessWidget {
  const _CoherenceWarning({required this.coherence});

  final NutritionTargetCoherence coherence;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      key: const ValueKey('nutrition-targets-coherence-warning'),
      padding: const EdgeInsets.all(TioSpacing.lg),
      decoration: BoxDecoration(
        color: colors.danger.withAlpha(TioAlpha.alpha12),
        borderRadius: BorderRadius.circular(TioRadius.lg),
        border: Border.all(color: colors.danger.withAlpha(TioAlpha.alpha40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macros do not match Calories',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w700,
              fontSize: TioFontSize.size15,
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          _CoherenceLine(
            label: 'Target Calories',
            value: '${coherence.targetCalories} kcal',
          ),
          _CoherenceLine(
            label: 'From macros',
            value: '${_formatNumber(coherence.macroCalories!)} kcal',
          ),
          _CoherenceLine(
            label: 'Difference',
            value: '${_formatNumber(coherence.differenceKcal!)} kcal',
          ),
          const SizedBox(height: TioSpacing.sm),
          Text(
            'Adjust Calories or a macro so they agree within '
            '${NutritionTargetEditor.coherenceToleranceKcal} kcal.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: TioFontSize.size13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoherenceLine extends StatelessWidget {
  const _CoherenceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.only(top: TioSpacing.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w700,
              fontSize: TioFontSize.size13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetEditorSheet extends StatefulWidget {
  const _TargetEditorSheet({
    required this.field,
    required this.label,
    required this.unit,
    required this.current,
    required this.onSave,
  });

  final NutritionTargetField field;
  final String label;
  final String unit;
  final NutritionTargetsData current;
  final Future<void> Function(NutritionTargetsData targets) onSave;

  @override
  State<_TargetEditorSheet> createState() => _TargetEditorSheetState();
}

class _TargetEditorSheetState extends State<_TargetEditorSheet> {
  late final TextEditingController _controller;
  late final String _initialText;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final value = NutritionTargetEditor.valueOf(widget.current, widget.field);
    _initialText = value == null ? '' : _formatNumber(value);
    _controller = TextEditingController(text: _initialText);
    _controller.addListener(_handleChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (_errorText != null) setState(() => _errorText = null);
    setState(() {});
  }

  bool get _isDirty => _controller.text.trim() != _initialText;

  /// Blank means "unset", which is a legitimate saved state distinct from zero.
  num? get _parsed {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    return num.tryParse(text);
  }

  String? _validate() {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;

    final value = num.tryParse(text);
    if (value == null || !value.isFinite) {
      return 'Enter a number.';
    }
    if (widget.field == NutritionTargetField.calories) {
      if (value <= 0) return 'Calories must be greater than zero.';
      // A storage limit, not a health judgement: `calories_kcal` is a Postgres
      // integer, so a larger value would fail at the database rather than here.
      if (value > NutritionTargetEditor.maxStorableCalories) {
        return 'That value is too large to store.';
      }
    } else if (value < 0) {
      return '${widget.label} cannot be negative.';
    }
    return null;
  }

  bool get _canSave => _isDirty && !_isSaving && _validate() == null;

  Future<void> _handleSave() async {
    if (!_canSave) return;

    final merged = NutritionTargetEditor.applyEdit(
      widget.current,
      field: widget.field,
      value: _parsed,
    );

    final coherence = NutritionTargetEditor.coherenceOf(merged);
    if (coherence.blocksSave) {
      setState(() {
        _errorText = 'Calories ${coherence.targetCalories} kcal vs '
            '${_formatNumber(coherence.macroCalories!)} kcal from macros — '
            'off by ${_formatNumber(coherence.differenceKcal!)} kcal.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await widget.onSave(merged);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = "Couldn't save. Check your connection and try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final validation = _validate();
    final message = _errorText ?? validation;

    return NutritionEditorSheet(
      title: widget.label,
      supportingText: 'Leave blank to keep this target unset.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: ValueKey(
              'nutrition-target-${widget.field.storageValue}-input',
            ),
            controller: _controller,
            enabled: !_isSaving,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSave(),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: TioFontSize.size24,
              fontWeight: TioFontWeight.w700,
            ),
            decoration: InputDecoration(
              suffixText: widget.unit,
              suffixStyle: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size15,
              ),
              hintText: 'Not set',
              hintStyle: TextStyle(
                color: colors.textMuted,
                fontSize: TioFontSize.size24,
                fontWeight: TioFontWeight.w400,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: TioSpacing.sm),
            Text(
              message,
              key: const ValueKey('nutrition-target-editor-error'),
              style:
                  TextStyle(color: colors.danger, fontSize: TioFontSize.size13),
            ),
          ],
        ],
      ),
      actions: TioButton.primary(
        key: ValueKey('nutrition-target-${widget.field.storageValue}-save'),
        label: 'Save',
        loading: _isSaving,
        onPressed: _canSave ? _handleSave : null,
        expand: true,
      ),
    );
  }
}

/// Renders whole values without a trailing `.0`, so a target reads as typed.
String _formatNumber(num value) {
  if (value is int) return '$value';
  if (value == value.roundToDouble()) return '${value.round()}';
  return value.toStringAsFixed(1);
}
