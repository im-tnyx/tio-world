import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../domain/domain.dart';
import '../widgets/nutrition_settings_widgets.dart';

/// Full-screen editor for the three energy macros.
///
/// This is a screen rather than a sheet because the three rows, their sliders
/// and the live calorie reconciliation already fill the height, and an exact
/// value still needs a keyboard. A sheet would have had to compete with the
/// keyboard for the same space; a screen does not.
///
/// Exact entry opens one small sheet holding a single number, which sits above
/// the keyboard and returns its value to this screen's draft rather than
/// saving on its own.
///
/// Grams are the single authoritative value. Percentages are derived for
/// display, recalculated live, and never persisted.
class NutritionMacrosSettingsPage extends StatefulWidget {
  const NutritionMacrosSettingsPage({
    required this.targets,
    required this.onSave,
    super.key,
  });

  final NutritionTargetsData targets;
  final Future<void> Function(NutritionTargetsData targets) onSave;

  @override
  State<NutritionMacrosSettingsPage> createState() =>
      _NutritionMacrosSettingsPageState();
}

class _NutritionMacrosSettingsPageState
    extends State<NutritionMacrosSettingsPage> {
  static const _macros = <(NutritionTargetField, String)>[
    (NutritionTargetField.protein, 'Protein'),
    (NutritionTargetField.carbohydrate, 'Carbohydrates'),
    (NutritionTargetField.fat, 'Fat'),
  ];

  late final Map<NutritionTargetField, double?> _grams;
  var _isSaving = false;
  String? _errorText;
  double _lastHapticGrams = -1;

  @override
  void initState() {
    super.initState();
    _grams = {
      for (final (field, _) in _macros)
        field: NutritionTargetEditor.valueOf(widget.targets, field)?.toDouble(),
    };
  }

  /// The row as it would be saved right now, so every readout below reflects
  /// the draft rather than what is stored.
  NutritionTargetsData get _draft => NutritionTargetEditor.applyMacroEdits(
        widget.targets,
        proteinGrams: _grams[NutritionTargetField.protein],
        carbohydrateGrams: _grams[NutritionTargetField.carbohydrate],
        fatGrams: _grams[NutritionTargetField.fat],
      );

  bool get _isDirty => _macros.any((entry) =>
      _grams[entry.$1] !=
      NutritionTargetEditor.valueOf(widget.targets, entry.$1)?.toDouble());

  bool get _canSave =>
      _isDirty &&
      !_isSaving &&
      !NutritionTargetEditor.coherenceOf(_draft).blocksSave;

  /// Restores the stored values, discarding this session's edits.
  ///
  /// This is not "reset to recommended" -- it returns to what is saved, which
  /// is the escape a user needs when an incoherent draft has blocked Save.
  void _resetDraft() {
    setState(() {
      for (final (field, _) in _macros) {
        _grams[field] =
            NutritionTargetEditor.valueOf(widget.targets, field)?.toDouble();
      }
      _errorText = null;
    });
  }

  void _handleSlider(NutritionTargetField field, double value) {
    final rounded = value.roundToDouble();
    setState(() {
      _grams[field] = rounded;
      _errorText = null;
    });
    if ((rounded - _lastHapticGrams).abs() >= 1) {
      HapticFeedback.selectionClick();
      _lastHapticGrams = rounded;
    }
  }

  Future<void> _editExact(NutritionTargetField field, String label) async {
    final result = await showTioEditorSheet<_ExactValue>(
      context: context,
      builder: (context) => _ExactMacroValueSheet(
        field: field,
        label: label,
        initial: _grams[field],
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _grams[field] = result.grams;
      _errorText = null;
    });
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Macronutrients',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  TioSpacing.lg,
                  TioSpacing.md,
                  TioSpacing.lg,
                  TioSpacing.lg,
                ),
                children: [
                  Text(
                    'Percentages are calculated from your grams.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size13,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.lg),
                  for (final (field, label) in _macros) ...[
                    _MacroSliderRow(
                      field: field,
                      label: label,
                      grams: _grams[field],
                      percent: percentages?[field],
                      enabled: !_isSaving,
                      sliderMax: NutritionTargetEditor.sliderMaxGrams(
                        field,
                        caloriesKcal: widget.targets.caloriesKcal,
                        current: _grams[field] ?? 0,
                      ),
                      onEditExact: () => _editExact(field, label),
                      onSlider: (value) => _handleSlider(field, value),
                    ),
                    if (field != _macros.last.$1)
                      const SizedBox(height: TioSpacing.lg),
                  ],
                  const SizedBox(height: TioSpacing.lg),
                  _CoherenceReadout(coherence: coherence),
                  if (_errorText != null) ...[
                    const SizedBox(height: TioSpacing.sm),
                    Text(
                      _errorText!,
                      key: const ValueKey('nutrition-macros-error'),
                      style: TextStyle(
                        color: colors.danger,
                        fontSize: TioFontSize.size13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Pinned so Save is never pushed off-screen by content length.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.lg,
                TioSpacing.sm,
                TioSpacing.lg,
                TioSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TioButton.secondary(
                      key: const ValueKey('nutrition-macros-reset'),
                      label: 'Reset',
                      onPressed: (_isDirty && !_isSaving) ? _resetDraft : null,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.md),
                  Expanded(
                    child: TioButton.primary(
                      key: const ValueKey('nutrition-macros-save'),
                      label: 'Save',
                      loading: _isSaving,
                      onPressed: _canSave ? _handleSave : null,
                      expand: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroSliderRow extends StatelessWidget {
  const _MacroSliderRow({
    required this.field,
    required this.label,
    required this.grams,
    required this.percent,
    required this.enabled,
    required this.sliderMax,
    required this.onEditExact,
    required this.onSlider,
  });

  final NutritionTargetField field;
  final String label;
  final double? grams;
  final int? percent;
  final bool enabled;
  final double sliderMax;
  final VoidCallback onEditExact;
  final ValueChanged<double> onSlider;

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
            Text(
              grams == null ? 'Not set' : '${_formatNumber(grams!)} g',
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
              onPressed: enabled ? onEditExact : () {},
            ),
          ],
        ),
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

/// Result of the exact-entry sheet. A null [grams] is an explicit "unset",
/// which a bare `null` return could not distinguish from cancelling.
class _ExactValue {
  const _ExactValue(this.grams);
  final double? grams;
}

/// One number, one keyboard.
///
/// Returns its value to the macros screen instead of saving, so the user can
/// adjust all three and review coherence before a single Save.
class _ExactMacroValueSheet extends StatefulWidget {
  const _ExactMacroValueSheet({
    required this.field,
    required this.label,
    required this.initial,
  });

  final NutritionTargetField field;
  final String label;
  final double? initial;

  @override
  State<_ExactMacroValueSheet> createState() => _ExactMacroValueSheetState();
}

class _ExactMacroValueSheetState extends State<_ExactMacroValueSheet> {
  late final TextEditingController _controller;
  late final String _initialText;

  @override
  void initState() {
    super.initState();
    _initialText = widget.initial == null ? '' : _formatNumber(widget.initial!);
    _controller = TextEditingController(text: _initialText);
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _validation {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return 'Enter a number.';
    if (value < 0) return '${widget.label} cannot be negative.';
    return null;
  }

  bool get _canApply =>
      _controller.text.trim() != _initialText && _validation == null;

  void _apply() {
    if (!_canApply) return;
    final text = _controller.text.trim();
    Navigator.of(context).pop(
      _ExactValue(text.isEmpty ? null : double.parse(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final validation = _validation;

    return TioEditorSheet(
      title: widget.label,
      supportingText: 'Leave blank to keep this macro unset.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: ValueKey(
              'nutrition-macros-${widget.field.storageValue}-input',
            ),
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _apply(),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: TioFontSize.size18,
              fontWeight: TioFontWeight.w700,
            ),
            decoration: InputDecoration(
              isDense: true,
              suffixText: 'g',
              suffixStyle: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size15,
              ),
              hintText: 'Not set',
              hintStyle: TextStyle(
                color: colors.textMuted,
                fontSize: TioFontSize.size18,
                fontWeight: TioFontWeight.w400,
              ),
            ),
          ),
          if (validation != null) ...[
            const SizedBox(height: TioSpacing.sm),
            Text(
              validation,
              key: const ValueKey('nutrition-macros-exact-error'),
              style:
                  TextStyle(color: colors.danger, fontSize: TioFontSize.size13),
            ),
          ],
        ],
      ),
      actions: TioButton.primary(
        key: ValueKey('nutrition-macros-${widget.field.storageValue}-apply'),
        label: 'Done',
        onPressed: _canApply ? _apply : null,
        expand: true,
      ),
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
          color: colors.textSecondary,
          fontSize: TioFontSize.size13,
        ),
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
            value: '${_formatNumber(coherence.macroCalories!)} kcal',
            valueKey: const ValueKey('nutrition-macros-derived-calories'),
          ),
          _Line(
            label: 'Target calories',
            value: '${coherence.targetCalories} kcal',
          ),
          _Line(
            label: 'Difference',
            // Signed, so the user can tell whether to add or remove. The
            // magnitude alone leaves the one useful fact out.
            value: _formatSignedKcal(coherence.signedDifferenceKcal!),
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

String _formatNumber(num value) {
  if (value == value.roundToDouble()) return '${value.round()}';
  return value.toStringAsFixed(1);
}

/// Renders a signed kcal delta, so direction is never lost.
String _formatSignedKcal(double value) {
  final magnitude = _formatNumber(value.abs());
  if (value > 0) return '+$magnitude kcal';
  if (value < 0) return '-$magnitude kcal';
  return '0 kcal';
}
