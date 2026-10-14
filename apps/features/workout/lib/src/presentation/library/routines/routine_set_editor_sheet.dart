import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import 'routine_set_input_limits.dart';

/// Modal input for exactly one existing fixed-repetition prescription.
/// No Routine mutation happens until the caller accepts its return value.
class RoutineSetEditorSheet extends StatefulWidget {
  const RoutineSetEditorSheet({
    required this.unit,
    this.initial,
    this.exerciseType,
    super.key,
  });

  final WeightUnit unit;
  final SetPrescription? initial;
  final ExerciseType? exerciseType;

  @override
  State<RoutineSetEditorSheet> createState() => _RoutineSetEditorSheetState();
}

class _RoutineSetEditorSheetState extends State<RoutineSetEditorSheet> {
  late final TextEditingController _reps;
  late final TextEditingController _repsMax;
  late final TextEditingController _load;
  late final TextEditingController _rest;
  late final String _originalLoad;
  String? _error;

  bool get _isWeightReps =>
      widget.exerciseType != ExerciseType.distanceDuration &&
      widget.exerciseType != ExerciseType.duration;

  @override
  void initState() {
    super.initState();
    _reps = TextEditingController(text: widget.initial?.reps?.toString() ?? '');
    _repsMax = TextEditingController(
      text: widget.initial?.repsMax?.toString() ?? '',
    );
    _originalLoad = widget.initial?.loadKg == null
        ? ''
        : UnitFormatters.formatWeight(
            widget.initial!.loadKg!,
            widget.unit,
            decimals: 3,
          ).split(' ').first;
    _load = TextEditingController(text: _originalLoad);
    _rest = TextEditingController(
      text: widget.initial?.restSeconds?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _reps.dispose();
    _repsMax.dispose();
    _load.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _inputChanged(String _) {
    if (_error != null) setState(() => _error = null);
  }

  void _confirm() {
    final repsText = _reps.text.trim();
    final int? reps = _isWeightReps
        ? (repsText.isEmpty ? null : int.tryParse(repsText))
        : widget.initial?.reps;
    final range = _isWeightReps && (widget.initial?.isRepRange ?? false);
    final maxText = _repsMax.text.trim();
    final int? repsMax = range
        ? (maxText.isEmpty ? null : int.tryParse(maxText))
        : widget.initial?.repsMax;
    final restText = _rest.text.trim();
    final rest = restText.isEmpty ? null : int.tryParse(restText);
    final weightText = _load.text.trim();
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    final invalidReps = _isWeightReps &&
        ((repsText.isNotEmpty &&
          (reps == null || reps <= 0 ||
           reps > RoutineSetInputLimits.maxReps)) ||
         (range && !((repsText.isEmpty && maxText.isEmpty) ||
           (reps != null && repsMax != null &&
            repsMax >= reps && repsMax <= RoutineSetInputLimits.maxReps))));
    if (invalidReps ||
        (restText.isNotEmpty && rest == null) ||
        (rest != null && (rest < 0 || rest > 2147483647)) ||
        (_isWeightReps && weightText.isNotEmpty && weight == null) ||
        (_isWeightReps && weight != null &&
         (!weight.isFinite || weight < 0))) {
      setState(() {
        _error = 'Invalid Set targets. Reps must be 1–999 when entered.';
      });
      return;
    }

    final double? kilograms;
    if (!_isWeightReps ||
        (widget.initial != null && weightText == _originalLoad)) {
      kilograms = widget.initial?.loadKg;
    } else if (weight == null) {
      kilograms = null;
    } else {
      kilograms = widget.unit == WeightUnit.kg
          ? weight
          : UnitConverters.lbToKg(weight);
    }
    try {
      final prescription = SetPrescription(
        reps: reps,
        repsMax: repsMax,
        setType: widget.initial?.setType ?? RoutineSetType.normal,
        loadKg: kilograms,
        distanceMeters: widget.initial?.distanceMeters,
        durationSeconds: widget.initial?.durationSeconds,
        restSeconds: rest,
      );
      Navigator.of(context).pop<SetPrescription>(prescription);
    } on ArgumentError {
      setState(() => _error = 'Invalid Set values.');
    }
  }

  @override
  Widget build(BuildContext context) => TioEditorSheet(
        title: widget.initial == null ? 'Add Set' : 'Edit Set',
        supportingText: !_isWeightReps
            ? 'Optional Rest after this Set.'
            : widget.initial?.isRepRange ?? false
                ? 'Optional Rep Range, Weight and Rest.'
                : 'Optional Reps, Weight and Rest.',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isWeightReps) ...[
            Semantics(
              label: 'Reps',
              child: TioInput.numericEditor(
                key: const ValueKey('routine-set-reps'),
                controller: _reps,
                hint: 'Reps',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  RoutineSetInputLimits.reps,
                ],
                onChanged: _inputChanged,
              ),
            ),
            if (widget.initial?.isRepRange ?? false) ...[
              const SizedBox(height: TioSpacing.md),
              Semantics(
                label: 'Maximum Reps',
                child: TioInput.numericEditor(
                  key: const ValueKey('routine-set-reps-max'),
                  controller: _repsMax,
                  hint: 'Maximum Reps',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    RoutineSetInputLimits.reps,
                  ],
                  onChanged: _inputChanged,
                ),
              ),
            ],
            const SizedBox(height: TioSpacing.md),
            Semantics(
              label: 'Weight',
              child: TioInput.numericEditor(
                key: const ValueKey('routine-set-weight'),
                controller: _load,
                hint: 'Weight',
                suffixText: widget.unit == WeightUnit.kg ? 'kg' : 'lb',
                inputFormatters: [
                  RoutineSetInputLimits.weight,
                ],
                onChanged: _inputChanged,
              ),
            ),
            ],
            if (_isWeightReps) const SizedBox(height: TioSpacing.md),
            Semantics(
              label: 'Rest seconds',
              child: TioInput.numericEditor(
                key: const ValueKey('routine-set-rest'),
                controller: _rest,
                hint: 'Rest seconds',
                keyboardType: TextInputType.number,
                suffixText: 'sec',
                inputFormatters: [
                  RoutineSetInputLimits.int32,
                ],
                onChanged: _inputChanged,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: TioSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  key: const ValueKey('routine-set-validation-error'),
                  style: TextStyle(color: context.tioColors.danger),
                ),
              ),
            ],
          ],
        ),
        actions: Row(
          children: [
            Expanded(
              child: TioButton.secondary(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Expanded(
              child: TioButton.primary(
                key: const ValueKey('routine-set-confirm'),
                label: 'Save Set',
                onPressed: _confirm,
              ),
            ),
          ],
        ),
      );
}
