import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../domain/domain.dart';
import '../widgets/nutrition_settings_widgets.dart';
import 'nutrition_profile_settings_page.dart' show NutritionEditorSheet;

/// Combined editor for the three energy macros.
///
/// The three are edited together because they are not independent: each one's
/// share and the calorie coherence check are defined by the other two, so
/// editing them one at a time would show a user numbers that are true only
/// until they open the next field.
///
/// Grams are the single authoritative value. Percentages are derived for
/// display, recalculated live, and never persisted.
class NutritionMacrosEditorSheet extends StatefulWidget {
  const NutritionMacrosEditorSheet({
    required this.current,
    required this.onSave,
    super.key,
  });

  final NutritionTargetsData current;
  final Future<void> Function(NutritionTargetsData targets) onSave;

  @override
  State<NutritionMacrosEditorSheet> createState() =>
      _NutritionMacrosEditorSheetState();
}

class _NutritionMacrosEditorSheetState
    extends State<NutritionMacrosEditorSheet> {
  static const _macros = <(NutritionTargetField, String)>[
    (NutritionTargetField.protein, 'Protein'),
    (NutritionTargetField.carbohydrate, 'Carbohydrates'),
    (NutritionTargetField.fat, 'Fat'),
  ];

  late final Map<NutritionTargetField, double?> _grams;
  late final Map<NutritionTargetField, TextEditingController> _controllers;
  final _manualFields = <NutritionTargetField>{};
  var _isSaving = false;
  String? _errorText;
  double _lastHapticGrams = -1;

  @override
  void initState() {
    super.initState();
    _grams = {
      for (final (field, _) in _macros)
        field: NutritionTargetEditor.valueOf(widget.current, field)?.toDouble(),
    };
    _controllers = {
      for (final entry in _grams.entries)
        entry.key: TextEditingController(
          text: entry.value == null ? '' : _formatGrams(entry.value!),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The row as it would be saved right now, so every derived readout below
  /// reflects the draft rather than what is stored.
  NutritionTargetsData get _draft => NutritionTargetEditor.applyMacroEdits(
        widget.current,
        proteinGrams: _grams[NutritionTargetField.protein],
        carbohydrateGrams: _grams[NutritionTargetField.carbohydrate],
        fatGrams: _grams[NutritionTargetField.fat],
      );

  bool get _isDirty => _macros.any((entry) =>
      _grams[entry.$1] !=
      NutritionTargetEditor.valueOf(widget.current, entry.$1)?.toDouble());

  bool get _canSave =>
      _isDirty &&
      !_isSaving &&
      !NutritionTargetEditor.coherenceOf(_draft).blocksSave;

  void _setGrams(NutritionTargetField field, double? value,
      {bool sync = true}) {
    setState(() {
      _grams[field] = value;
      _errorText = null;
      if (sync) {
        final text = value == null ? '' : _formatGrams(value);
        final controller = _controllers[field]!;
        if (controller.text != text) controller.text = text;
      }
    });
  }

  void _handleSlider(NutritionTargetField field, double value) {
    final rounded = value.roundToDouble();
    _setGrams(field, rounded);
    if ((rounded - _lastHapticGrams).abs() >= 1) {
      HapticFeedback.selectionClick();
      _lastHapticGrams = rounded;
    }
  }

  void _handleText(NutritionTargetField field, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      // Blank means unset, which stays distinct from zero.
      _setGrams(field, null, sync: false);
      return;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      setState(() => _errorText = 'Enter a number of 0 or more.');
      return;
    }
    _setGrams(field, parsed, sync: false);
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await widget.onSave(_draft);
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
    final draft = _draft;
    final percentages = NutritionTargetEditor.macroPercentages(draft);
    final coherence = NutritionTargetEditor.coherenceOf(draft);

    return NutritionEditorSheet(
      title: 'Macronutrients',
      supportingText: 'Percentages are calculated from your grams.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (field, label) in _macros) ...[
            _MacroRow(
              field: field,
              label: label,
              grams: _grams[field],
              percent: percentages?[field],
              controller: _controllers[field]!,
              isManual: _manualFields.contains(field),
              enabled: !_isSaving,
              sliderMax: NutritionTargetEditor.sliderMaxGrams(
                field,
                caloriesKcal: widget.current.caloriesKcal,
                current: _grams[field] ?? 0,
              ),
              onToggleManual: () => setState(() {
                _manualFields.contains(field)
                    ? _manualFields.remove(field)
                    : _manualFields.add(field);
              }),
              onSlider: (value) => _handleSlider(field, value),
              onText: (text) => _handleText(field, text),
            ),
            if (field != _macros.last.$1) const SizedBox(height: TioSpacing.md),
          ],
          const SizedBox(height: TioSpacing.lg),
          _CoherenceReadout(coherence: coherence),
          if (_errorText != null) ...[
            const SizedBox(height: TioSpacing.sm),
            Text(
              _errorText!,
              key: const ValueKey('nutrition-macros-editor-error'),
              style:
                  TextStyle(color: colors.danger, fontSize: TioFontSize.size13),
            ),
          ],
        ],
      ),
      actions: TioButton.primary(
        key: const ValueKey('nutrition-macros-save'),
        label: 'Save',
        loading: _isSaving,
        onPressed: _canSave ? _handleSave : null,
        expand: true,
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.field,
    required this.label,
    required this.grams,
    required this.percent,
    required this.controller,
    required this.isManual,
    required this.enabled,
    required this.sliderMax,
    required this.onToggleManual,
    required this.onSlider,
    required this.onText,
  });

  final NutritionTargetField field;
  final String label;
  final double? grams;
  final int? percent;
  final TextEditingController controller;
  final bool isManual;
  final bool enabled;
  final double sliderMax;
  final VoidCallback onToggleManual;
  final ValueChanged<double> onSlider;
  final ValueChanged<String> onText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final id = field.storageValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w700,
                  fontSize: TioFontSize.size15,
                ),
              ),
            ),
            Text(
              // An unavailable share shows an em dash rather than a made-up 0%.
              percent == null ? '—' : '$percent%',
              key: ValueKey('nutrition-macros-$id-percent'),
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: TioFontWeight.w600,
                fontSize: TioFontSize.size13,
              ),
            ),
            const SizedBox(width: TioSpacing.lg),
            if (!isManual)
              Text(
                grams == null ? 'Not set' : '${_formatGrams(grams!)} g',
                key: ValueKey('nutrition-macros-$id-grams'),
                style: TextStyle(
                  color: grams == null ? colors.textMuted : colors.textPrimary,
                  fontWeight: TioFontWeight.w700,
                  fontSize: TioFontSize.size15,
                ),
              ),
            const SizedBox(width: TioSpacing.sm),
            NutritionEditPencil(
              key: ValueKey('nutrition-macros-$id-pencil'),
              onPressed: enabled ? onToggleManual : () {},
            ),
          ],
        ),
        if (isManual) ...[
          const SizedBox(height: TioSpacing.xs),
          TextField(
            key: ValueKey('nutrition-macros-$id-input'),
            controller: controller,
            enabled: enabled,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textInputAction: TextInputAction.done,
            onChanged: onText,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: TioFontSize.size18,
              fontWeight: TioFontWeight.w700,
            ),
            decoration: InputDecoration(
              isDense: true,
              suffixText: 'g',
              hintText: 'Not set',
              hintStyle: TextStyle(color: colors.textMuted),
            ),
          ),
        ],
        Slider(
          key: ValueKey('nutrition-macros-$id-slider'),
          value: (grams ?? 0).clamp(0, sliderMax),
          max: sliderMax,
          onChanged: enabled ? onSlider : null,
        ),
      ],
    );
  }
}

/// Live calorie reconciliation for the draft macros.
class _CoherenceReadout extends StatelessWidget {
  const _CoherenceReadout({required this.coherence});

  final NutritionTargetCoherence coherence;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    if (!coherence.isEvaluable) {
      return Text(
        'Set Calories and all three macros to compare them.',
        key: const ValueKey('nutrition-macros-coherence-unavailable'),
        style: TextStyle(
            color: colors.textSecondary, fontSize: TioFontSize.size13),
      );
    }

    final blocked = coherence.blocksSave;

    return Container(
      key: const ValueKey('nutrition-macros-coherence'),
      padding: const EdgeInsets.all(TioSpacing.md),
      decoration: BoxDecoration(
        color: blocked
            ? colors.danger.withAlpha(TioAlpha.alpha12)
            : colors.surfaceVariant,
        borderRadius: BorderRadius.circular(TioRadius.md),
        border: blocked
            ? Border.all(color: colors.danger.withAlpha(TioAlpha.alpha40))
            : null,
      ),
      child: Column(
        children: [
          _Line(
            label: 'Calories from macros',
            value: '${_formatGrams(coherence.macroCalories!)} kcal',
            valueKey: const ValueKey('nutrition-macros-derived-calories'),
          ),
          _Line(
            label: 'Target calories',
            value: '${coherence.targetCalories} kcal',
          ),
          _Line(
            label: 'Difference',
            value: '${_formatGrams(coherence.differenceKcal!)} kcal',
            valueKey: const ValueKey('nutrition-macros-difference'),
            emphasised: blocked,
          ),
          if (blocked) ...[
            const SizedBox(height: TioSpacing.sm),
            Text(
              'Adjust a macro or your Calories so they agree within '
              '${NutritionTargetEditor.coherenceToleranceKcal} kcal.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.valueKey,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final Key? valueKey;
  final bool emphasised;

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
            key: valueKey,
            style: TextStyle(
              color: emphasised ? colors.danger : colors.textPrimary,
              fontWeight: TioFontWeight.w700,
              fontSize: TioFontSize.size13,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatGrams(num value) {
  if (value == value.roundToDouble()) return '${value.round()}';
  return value.toStringAsFixed(1);
}
