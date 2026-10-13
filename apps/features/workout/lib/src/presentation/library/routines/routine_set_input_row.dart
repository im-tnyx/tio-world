import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_composition_repository.dart';

/// Compact inline prescription editor for one identified Routine Set.
///
/// Reusable within the Workout feature's Create/Editor surfaces. It delegates
/// persistence and validation gates to the owning controller/page; it never
/// writes or opens a modal. The existing canonical Set UUID stays unchanged.
class RoutineSetInputRow extends StatefulWidget {
  const RoutineSetInputRow({
    required this.set,
    required this.index,
    required this.unit,
    required this.enabled,
    required this.onChanged,
    required this.onValidityChanged,
    required this.onRemove,
    super.key,
  });

  final RoutineCompositionSet set;
  final int index;
  final WeightUnit unit;
  final bool enabled;
  final ValueChanged<SetPrescription> onChanged;
  final ValueChanged<bool> onValidityChanged;
  final VoidCallback onRemove;

  @override
  State<RoutineSetInputRow> createState() => _RoutineSetInputRowState();
}

class _RoutineSetInputRowState extends State<RoutineSetInputRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late String _originalWeightText;
  late double? _originalKg;
  bool _valid = true;

  @override
  void initState() {
    super.initState();
    _reps = TextEditingController(
      text: widget.set.prescription.reps.toString(),
    );
    _originalKg = widget.set.prescription.loadKg;
    _originalWeightText = _displayWeight(_originalKg);
    _weight = TextEditingController(text: _originalWeightText);
  }

  String _displayWeight(double? kg) => kg == null
      ? ''
      : UnitFormatters.formatWeight(
          kg, widget.unit, decimals: 3,
        ).split(' ').first;

  @override
  void didUpdateWidget(covariant RoutineSetInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unit != widget.unit) {
      // A visible unit preference change uses the current canonical kg bytes,
      // rather than interpreting a previously formatted lb string as kg.
      _originalKg = widget.set.prescription.loadKg;
      _originalWeightText = _displayWeight(_originalKg);
      _weight.text = _originalWeightText;
      _update();
    }
  }

  void _update() {
    final reps = int.tryParse(_reps.text.trim());
    final rawWeight = _weight.text.trim();
    final weight = rawWeight.isEmpty ? null : double.tryParse(rawWeight);
    final valid = reps != null &&
        reps > 0 &&
        reps <= 2147483647 &&
        (rawWeight.isEmpty ||
            (weight != null && weight.isFinite && weight >= 0));
    if (_valid != valid) {
      _valid = valid;
      widget.onValidityChanged(valid);
    }
    if (!valid || !widget.enabled) return;

    // Keep exact previously stored kg when the rounded lb string is untouched,
    // matching the existing Routine Set editor's unit conversion contract.
    final double? kg;
    if (rawWeight == _originalWeightText) {
      kg = _originalKg;
    } else if (weight == null) {
      kg = null;
    } else {
      kg = widget.unit == WeightUnit.kg
          ? weight
          : UnitConverters.lbToKg(weight);
    }

    try {
      final next = SetPrescription(
        reps: reps,
        loadKg: kg,
        restSeconds: widget.set.prescription.restSeconds,
      );
      if (next != widget.set.prescription) widget.onChanged(next);
    } on ArgumentError {
      // Defensive parity with the canonical Set constructor. A rejected
      // draft must not leave Save enabled with stale persisted values.
      if (_valid) {
        _valid = false;
        widget.onValidityChanged(false);
      }
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final setNumber = widget.index + 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: TioSpacing.sm),
      child: Row(
        children: [
          Container(
            width: TioSize.dp44,
            constraints: const BoxConstraints(minHeight: TioSize.dp44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(TioRadius.md),
            ),
            child: Text(
              '$setNumber',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: TioSpacing.sm),
          Expanded(
            child: Semantics(
              label: 'Set $setNumber Weight in ${widget.unit == WeightUnit.kg ? 'kg' : 'lb'}',
              child: TioInput.compactNumber(
                key: ValueKey('routine-set-weight-${widget.set.id}'),
                controller: _weight,
                enabled: widget.enabled,
                hint: '–',
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (_) => _update(),
              ),
            ),
          ),
          const SizedBox(width: TioSpacing.sm),
          Expanded(
            child: Semantics(
              label: 'Set $setNumber Reps',
              child: TioInput.compactNumber(
                key: ValueKey('routine-set-reps-${widget.set.id}'),
                controller: _reps,
                enabled: widget.enabled,
                hint: 'Reps',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) => _update(),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('routine-set-remove-${widget.set.id}'),
            tooltip: 'Remove Set $setNumber',
            onPressed: widget.enabled ? widget.onRemove : null,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
