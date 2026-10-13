import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    required this.normalNumber,
    required this.onTypePressed,
    required this.unit,
    required this.enabled,
    required this.onChanged,
    required this.onValidityChanged,
    required this.onRemove,
    required this.isOpen,
    required this.onOpenChanged,
    super.key,
  });

  final RoutineCompositionSet set;
  final int index;
  final int normalNumber;
  final VoidCallback onTypePressed;
  final WeightUnit unit;
  final bool enabled;
  final ValueChanged<SetPrescription> onChanged;
  final ValueChanged<bool> onValidityChanged;
  final VoidCallback onRemove;
  /// Owned by the page so only one row's Delete action can be revealed.
  final bool isOpen;
  final ValueChanged<bool> onOpenChanged;

  @override
  State<RoutineSetInputRow> createState() => _RoutineSetInputRowState();
}

class _RoutineSetInputRowState extends State<RoutineSetInputRow>
    with AutomaticKeepAliveClientMixin<RoutineSetInputRow> {
  // Keep uncommitted invalid input visible while scrolling. Otherwise a
  // recycled numeric TextField could reappear with the last valid persisted
  // value while the owning page still correctly blocks Save.
  @override
  bool get wantKeepAlive => true;
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late final TextEditingController _repsMax;
  late String _originalWeightText;
  late double? _originalKg;
  bool _valid = true;
  static const double _revealWidth = TioSize.dp48 + TioSize.dp48;
  static const double _threshold = _revealWidth / 2;
  static const double _flickVelocity = 200;
  double _reveal = 0;
  bool _dragging = false;
  bool _pastRevealThreshold = false;

  // The full gesture is proportional to the actual row width, not the
  // much shorter width needed to expose the Delete button.
  double get _fullSwipeThreshold =>
      (context.size?.width ?? _revealWidth * 4) * 0.65;

  void _delete() {
    if (!widget.enabled) return;
    HapticFeedback.mediumImpact();
    widget.onRemove();
  }

  @override
  void initState() {
    super.initState();
    _reveal = widget.isOpen ? _revealWidth : 0;
    _pastRevealThreshold = widget.isOpen;
    _reps = TextEditingController(
      text: widget.set.prescription.reps.toString(),
    );
    _repsMax = TextEditingController(
      text: widget.set.prescription.repsMax?.toString() ?? '',
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
    if (widget.isOpen != oldWidget.isOpen || !widget.enabled) {
      _dragging = false;
      _reveal = widget.isOpen && widget.enabled ? _revealWidth : 0;
      _pastRevealThreshold = widget.isOpen && widget.enabled;
    }
    if (oldWidget.set.prescription.isRepRange !=
        widget.set.prescription.isRepRange) {
      _repsMax.text = widget.set.prescription.repsMax?.toString() ?? '';
    }
    if (oldWidget.unit != widget.unit) {
      // A visible unit preference change uses the current canonical kg bytes,
      // rather than interpreting a previously formatted lb string as kg.
      _originalKg = widget.set.prescription.loadKg;
      _originalWeightText = _displayWeight(_originalKg);
      _weight.text = _originalWeightText;
    }
  }

  void _update() {
    final reps = int.tryParse(_reps.text.trim());
    final inRange = widget.set.prescription.isRepRange;
    final max = inRange ? int.tryParse(_repsMax.text.trim()) : null;
    final rawWeight = _weight.text.trim();
    final weight = rawWeight.isEmpty ? null : double.tryParse(rawWeight);
    final valid = reps != null &&
        reps > 0 &&
        reps <= 2147483647 &&
        (!inRange || (max != null && max >= reps && max <= 2147483647)) &&
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
        repsMax: max,
        setType: widget.set.prescription.setType,
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
    _repsMax.dispose();
    super.dispose();
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    final width = context.size?.width ?? _revealWidth * 4;
    setState(() {
      _dragging = true;
      // Allow the foreground to follow the finger past the short reveal:
      // a full-length swipe exposes the destructive background completely.
      _reveal = (_reveal - details.delta.dx).clamp(0.0, width);
    });
    final above = _reveal >= _threshold;
    if (above && !_pastRevealThreshold) {
      HapticFeedback.selectionClick();
    }
    _pastRevealThreshold = above;
  }

  void _dragEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    // A fast short flick only reveals Delete. Auto-delete requires deliberate
    // DISTANCE at pointer release, even if the flick velocity is very high.
    if (_reveal >= _fullSwipeThreshold) {
      _dragging = false;
      _delete();
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    final open = velocity < -_flickVelocity
        ? true
        : velocity > _flickVelocity
            ? false
            : _reveal >= _threshold;
    setState(() {
      _dragging = false;
      _reveal = open ? _revealWidth : 0;
      _pastRevealThreshold = open;
    });
    widget.onOpenChanged(open);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final setNumber = widget.index + 1;
    final colors = context.tioColors;
    final foreground = Material(
      color: colors.background,
      child: GestureDetector(
        key: ValueKey('routine-set-swipe-${widget.set.id}'),
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: widget.enabled ? _dragUpdate : null,
        onHorizontalDragEnd: widget.enabled ? _dragEnd : null,
        child: _fields(context),
      ),
    );
    return Semantics(
      customSemanticsActions: widget.enabled
          ? {
              CustomSemanticsAction(label: 'Delete Set $setNumber'):
                  _delete,
            }
          : const {},
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              // As the finger travels beyond the short action reveal,
              // the full exposed area stays visibly destructive.
              child: ColoredBox(
                color: colors.danger,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _revealWidth,
                    child: TextButton(
                      key: ValueKey('routine-set-remove-${widget.set.id}'),
                      onPressed: widget.enabled && widget.isOpen
                          ? _delete
                          : null,
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _reveal),
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (_, revealed, child) => Transform.translate(
                offset: Offset(-revealed, 0),
                child: child,
              ),
              child: foreground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fields(BuildContext context) {
    final colors = context.tioColors;
    final setNumber = widget.index + 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: TioSpacing.sm),
      child: Row(
        children: [
          Semantics(
            label: 'Set $setNumber type, tap to select Set Type',
            button: true,
            child: InkWell(
              key: ValueKey('routine-set-type-${widget.set.id}'),
              onTap: widget.enabled ? widget.onTypePressed : null,
              borderRadius: BorderRadius.circular(TioRadius.md),
              child: Container(
                width: TioSize.dp44,
                constraints: const BoxConstraints(minHeight: TioSize.dp44),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(TioRadius.md),
                ),
                child: Text(
                  switch (widget.set.prescription.setType) {
                    RoutineSetType.normal => '${widget.normalNumber}',
                    RoutineSetType.warmUp => 'W',
                    RoutineSetType.failure => 'F',
                    RoutineSetType.drop => 'D',
                  },
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: switch (widget.set.prescription.setType) {
                      RoutineSetType.normal => colors.textPrimary,
                      RoutineSetType.warmUp => colors.warning,
                      RoutineSetType.failure => colors.danger,
                      RoutineSetType.drop => colors.info,
                    },
                  ),
                ),
              ),
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
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Set $setNumber ${widget.set.prescription.isRepRange ? 'minimum Reps' : 'Reps'}',
                    child: TioInput.compactNumber(
                      key: ValueKey('routine-set-reps-${widget.set.id}'),
                      controller: _reps,
                      enabled: widget.enabled,
                      hint: '–',
                      keyboardType: TextInputType.number,
                      textInputAction: widget.set.prescription.isRepRange
                          ? TextInputAction.next : TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (_) => _update(),
                    ),
                  ),
                ),
                if (widget.set.prescription.isRepRange) ...[
                  const SizedBox(width: TioSpacing.xs),
                  const Text('to'),
                  const SizedBox(width: TioSpacing.xs),
                  Expanded(
                    child: Semantics(
                      label: 'Set $setNumber maximum Reps',
                      child: TioInput.compactNumber(
                        key: ValueKey('routine-set-reps-max-${widget.set.id}'),
                        controller: _repsMax,
                        enabled: widget.enabled,
                        hint: '–',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => _update(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: TioSize.dp48),
        ],
      ),
    );
  }
}
