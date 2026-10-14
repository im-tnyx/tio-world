import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_composition_repository.dart';
import 'routine_set_input_limits.dart';

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
    this.startWithBlankReps = false,
    this.showPrevious = false,
    this.exerciseType,
    this.showRangeDraft = false,
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
  /// New Create draft rows display no user-entered repetition target.
  /// Never use this for a persisted Edit row or a restored valid value.
  final bool startWithBlankReps;
  /// Previous workout history is a separate PerformedSet boundary.
  /// Its read-only placeholder is not derived from prescribed targets.
  final bool showPrevious;
  /// Canonical explicit measurement kind. Unclassified older catalog rows
  /// retain the existing weight/reps layout; never infer from category.
  final ExerciseType? exerciseType;
  final bool showRangeDraft;

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
  late final TextEditingController _distance;
  late final TextEditingController _duration;
  late String _originalDistanceText;
  late double? _originalMeters;
  late String _originalWeightText;
  late double? _originalKg;
  // Distinguish parent echoes of this row's own edits from external changes
  // (notably the advanced Set sheet) so typing drafts/caret are not reset.
  SetPrescription? _lastInlineEdit;
  bool _valid = true;
  bool get _rangeMode => widget.showRangeDraft || widget.set.prescription.isRepRange;
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
    _valid = true;
    _reps = TextEditingController(
      text: widget.startWithBlankReps
          ? ''
          : widget.set.prescription.reps?.toString() ?? '',
    );
    _repsMax = TextEditingController(
      text: widget.startWithBlankReps
          ? ''
          : widget.set.prescription.repsMax?.toString() ?? '',
    );
    _originalKg = widget.set.prescription.loadKg;
    _originalWeightText = _displayWeight(_originalKg);
    _weight = TextEditingController(text: _originalWeightText);
    _originalMeters = widget.set.prescription.distanceMeters;
    _originalDistanceText =
        RoutineSetInputLimits.displayDistanceKm(_originalMeters);
    _distance = TextEditingController(text: _originalDistanceText);
    _duration = TextEditingController(
      text: RoutineSetInputLimits.displayDurationSeconds(
        widget.set.prescription.durationSeconds,
      ),
    );
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
    final before = oldWidget.set.prescription;
    final after = widget.set.prescription;
    // One local edit has at most one parent echo. Consume its marker on that
    // matching rebuild; a later sheet edit may legitimately return to the
    // same value and must never be mistaken for an old inline echo.
    final inlineEcho = before != after && after == _lastInlineEdit;
    if (before != after) _lastInlineEdit = null;
    final changedExternally = before != after && !inlineEcho;
    final modeChanged = (oldWidget.showRangeDraft || before.isRepRange) != _rangeMode;
    final unitChanged = oldWidget.unit != widget.unit;

    // An inline text edit is echoed through the parent controller as a new
    // SetPrescription. Never normalize that same text back into the controller:
    // "08", partial kg/lb decimals, selection and invalid drafts must survive.
    // The advanced Set sheet is a DIFFERENT source and must refresh the edited
    // fields; otherwise a later inline change silently overwrites its values.
    if (changedExternally && before.reps != after.reps) {
      _reps.text = after.reps?.toString() ?? '';
    }
    if (modeChanged && _rangeMode) {
      // Fixed -> Range uses a canonical provisional Max in the domain model.
      // It is not user-entered: keep its field blank and block Save until the
      // user explicitly supplies a valid maximum.
      _repsMax.text = '';
    } else if (modeChanged ||
        (changedExternally && before.repsMax != after.repsMax)) {
      _repsMax.text = after.repsMax?.toString() ?? '';
    }
    if (unitChanged || (changedExternally && before.loadKg != after.loadKg)) {
      // Rebase untouched rounded lb text on exact canonical kg, including
      // when the advanced Set sheet supplied a new weight in this same unit.
      _originalKg = after.loadKg;
      _originalWeightText = _displayWeight(_originalKg);
      _weight.text = _originalWeightText;
    }
    if (changedExternally &&
        before.distanceMeters != after.distanceMeters) {
      _originalMeters = after.distanceMeters;
      _originalDistanceText =
          RoutineSetInputLimits.displayDistanceKm(_originalMeters);
      _distance.text = _originalDistanceText;
    }
    if (changedExternally &&
        before.durationSeconds != after.durationSeconds) {
      _duration.text = RoutineSetInputLimits.displayDurationSeconds(
        after.durationSeconds,
      );
    }
    if (modeChanged || changedExternally ||
        oldWidget.exerciseType != widget.exerciseType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.set.prescription == after) _update();
      });
    }
  }

  void _update() {
    final source = widget.set.prescription;
    final isDistanceTime = widget.exerciseType == ExerciseType.distanceDuration;
    final isTimeOnly = widget.exerciseType == ExerciseType.duration;
    final isWeightReps = !isDistanceTime && !isTimeOnly;

    int? reps = source.reps;
    int? max = source.repsMax;
    double? kg = source.loadKg;
    double? meters = source.distanceMeters;
    int? duration = source.durationSeconds;
    var valid = true;

    if (isWeightReps) {
      final repsText = _reps.text.trim();
      final parsedReps = int.tryParse(repsText);
      final inRange = _rangeMode;
      final maxText = _repsMax.text.trim();
      final parsedMax = int.tryParse(maxText);
      final rawWeight = _weight.text.trim();
      final weight = double.tryParse(rawWeight);
      // A completely empty template target is valid. Half-entered ranges,
      // zero/overflowing Reps and partial KG values must still block Save.
      valid = (repsText.isEmpty ||
               (parsedReps != null && parsedReps > 0 &&
                parsedReps <= RoutineSetInputLimits.maxReps)) &&
          (!inRange ||
           ((repsText.isEmpty && maxText.isEmpty) ||
            (parsedReps != null && parsedMax != null &&
             parsedMax >= parsedReps &&
             parsedMax <= RoutineSetInputLimits.maxReps))) &&
          (rawWeight.isEmpty ||
           (weight != null && weight.isFinite && weight >= 0));
      reps = repsText.isEmpty ? null : parsedReps;
      max = inRange && maxText.isNotEmpty ? parsedMax : null;
      if (rawWeight == _originalWeightText) {
        kg = _originalKg;
      } else if (rawWeight.isEmpty) {
        kg = null;
      } else if (weight != null) {
        kg = widget.unit == WeightUnit.kg
            ? weight
            : UnitConverters.lbToKg(weight);
      }
    }
    if (isDistanceTime) {
      final raw = _distance.text.trim();
      final parsed = double.tryParse(raw);
      valid = raw.isEmpty || (parsed != null &&
          parsed.isFinite && parsed >= 0);
      if (raw == _originalDistanceText) {
        meters = _originalMeters; // Preserve precise canonical stored value.
      } else {
        meters = raw.isEmpty ? null : (parsed == null ? null : parsed * 1000);
      }
    }
    if (isDistanceTime || isTimeOnly) {
      final raw = _duration.text.trim();
      final parsed = RoutineSetInputLimits.parseDurationSeconds(raw);
      valid = valid && (raw.isEmpty || parsed != null);
      duration = raw.isEmpty ? null : parsed;
    }
    if (_valid != valid) {
      _valid = valid;
      widget.onValidityChanged(valid);
    }
    if (!valid || !widget.enabled) return;

    try {
      final next = SetPrescription(
        reps: reps,
        repsMax: max,
        setType: source.setType,
        loadKg: kg,
        distanceMeters: meters,
        durationSeconds: duration,
        restSeconds: source.restSeconds,
      );
      if (next != source) {
        _lastInlineEdit = next;
        widget.onChanged(next);
      }
    } on ArgumentError {
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
    _distance.dispose();
    _duration.dispose();
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
                  : const Duration(milliseconds: TioDuration.ms180),
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
                key: ValueKey('routine-set-type-box-${widget.set.id}'),
                width: TioSize.dp44,
                constraints: const BoxConstraints(minHeight: TioSize.dp44),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // The near-black surface is indistinguishable from the
                  // OLED background. Use the governed filled-cell surface.
                  color: colors.surfaceVariant,
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
          if (widget.showPrevious) ...[
            const SizedBox(
              width: TioSize.dp64,
              child: Text('–', textAlign: TextAlign.center),
            ),
            const SizedBox(width: TioSpacing.sm),
          ],
          if (widget.exerciseType == ExerciseType.distanceDuration) ...[
            Expanded(
              child: Semantics(
                label: 'Set $setNumber Distance in kilometers',
                child: TioInput.boxedNumber(
                  key: ValueKey('routine-set-distance-${widget.set.id}'),
                  controller: _distance,
                  enabled: widget.enabled,
                  hint: '–',
                  textInputAction: TextInputAction.next,
                  inputFormatters: [RoutineSetInputLimits.weight],
                  onChanged: (_) => _update(),
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
          ],
          if (widget.exerciseType == ExerciseType.distanceDuration ||
              widget.exerciseType == ExerciseType.duration)
            Expanded(
              child: Semantics(
                label: 'Set $setNumber Time in minutes and seconds',
                child: TioInput.boxedNumber(
                  key: ValueKey('routine-set-duration-${widget.set.id}'),
                  controller: _duration,
                  enabled: widget.enabled,
                  hint: '–',
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [RoutineSetInputLimits.time],
                  onChanged: (_) => _update(),
                ),
              ),
            ),
          if (widget.exerciseType != ExerciseType.distanceDuration &&
              widget.exerciseType != ExerciseType.duration) ...[
          Expanded(
            flex: _rangeMode ? 2 : 1,
            child: Semantics(
              label: 'Set $setNumber Weight in ${widget.unit == WeightUnit.kg ? 'kg' : 'lb'}',
              child: TioInput.boxedNumber(
                key: ValueKey('routine-set-weight-${widget.set.id}'),
                controller: _weight,
                enabled: widget.enabled,
                hint: '–',
                textInputAction: TextInputAction.next,
                inputFormatters: [RoutineSetInputLimits.weight],
                onChanged: (_) => _update(),
              ),
            ),
          ),
          const SizedBox(width: TioSpacing.sm),
          Expanded(
            flex: _rangeMode ? 3 : 1,
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Set $setNumber ${_rangeMode ? 'minimum Reps' : 'Reps'}',
                    child: TioInput.boxedNumber(
                      key: ValueKey('routine-set-reps-${widget.set.id}'),
                      controller: _reps,
                      enabled: widget.enabled,
                      hint: '–',
                      keyboardType: TextInputType.number,
                      textInputAction: _rangeMode
                          ? TextInputAction.next : TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        RoutineSetInputLimits.reps,
                      ],
                      onChanged: (_) => _update(),
                    ),
                  ),
                ),
                if (_rangeMode) ...[
                  const SizedBox(width: TioSpacing.xs),
                  Text(
                    '–',
                    key: ValueKey(
                      'routine-set-range-separator-${widget.set.id}',
                    ),
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  const SizedBox(width: TioSpacing.xs),
                  Expanded(
                    child: Semantics(
                      label: 'Set $setNumber maximum Reps',
                      child: TioInput.boxedNumber(
                        key: ValueKey('routine-set-reps-max-${widget.set.id}'),
                        controller: _repsMax,
                        enabled: widget.enabled,
                        hint: '–',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          RoutineSetInputLimits.reps,
                        ],
                        onChanged: (_) => _update(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!widget.showPrevious && !_rangeMode)
            const SizedBox(width: TioSize.dp48),
          ],
        ],
      ),
    );
  }
}
