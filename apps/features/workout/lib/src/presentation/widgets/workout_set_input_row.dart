import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/routine_composition_repository.dart';
import '../library/routines/routine_set_input_limits.dart';
import '../library/routines/routine_set_type_badge.dart';

/// Unified inline set input row for both Routine editing and Workout Log execution.
///
/// Shares the exact same core field layout, swipe-to-delete gesture, and type
/// handlers across both surfaces. When [isExecution] is true, it layers the
/// logged state background, optional RPE, and completion checkmark toggle.
class WorkoutSetInputRow extends StatefulWidget {
  const WorkoutSetInputRow({
    required this.set,
    required this.index,
    required this.normalNumber,
    required this.unit,
    required this.enabled,
    this.onTypePressed,
    this.onChanged,
    this.onValidityChanged,
    this.onRemove,
    this.isOpen = false,
    this.onOpenChanged,
    this.startWithBlankReps = false,
    this.showPrevious = false,
    this.useEditSetNumberColor = false,
    this.exerciseType,
    this.showRangeDraft = false,
    this.isExecution = false,
    this.isLogged = false,
    this.onToggleLogged,
    this.performedLoadKg,
    this.performedReps,
    this.performedDurationSeconds,
    this.performedDistanceMeters,
    this.performedRpe,
    this.showRpe = false,
    this.onRpePressed,
    this.rowKey,
    this.setNumberKey,
    this.loadKey,
    this.repsKey,
    this.toggleKey,
    this.rpeKey,
    super.key,
  });

  final RoutineCompositionSet set;
  final int index;
  final int normalNumber;
  final VoidCallback? onTypePressed;
  final WeightUnit unit;
  final bool enabled;
  final ValueChanged<SetPrescription>? onChanged;
  final ValueChanged<bool>? onValidityChanged;
  final VoidCallback? onRemove;
  final bool isOpen;
  final ValueChanged<bool>? onOpenChanged;
  final bool startWithBlankReps;
  final bool showPrevious;
  final bool useEditSetNumberColor;
  final ExerciseType? exerciseType;
  final bool showRangeDraft;
  final bool isExecution;
  final bool isLogged;
  final Future<void> Function({
    int? reps,
    double? loadKg,
    int? durationSeconds,
    double? distanceMeters,
  })? onToggleLogged;
  final double? performedLoadKg;
  final int? performedReps;
  final int? performedDurationSeconds;
  final double? performedDistanceMeters;
  final double? performedRpe;
  final bool showRpe;
  final VoidCallback? onRpePressed;
  final Key? rowKey;
  final Key? setNumberKey;
  final Key? loadKey;
  final Key? repsKey;
  final Key? toggleKey;
  final Key? rpeKey;

  @override
  State<WorkoutSetInputRow> createState() => _WorkoutSetInputRowState();
}

class _WorkoutSetInputRowState extends State<WorkoutSetInputRow>
    with AutomaticKeepAliveClientMixin<WorkoutSetInputRow> {
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

  SetPrescription? _lastInlineEdit;
  bool _valid = true;
  bool get _rangeMode =>
      !widget.isExecution &&
      (widget.showRangeDraft || widget.set.prescription.isRepRange);
  bool get _showRepRangeReference =>
      widget.isExecution &&
      !widget.isLogged &&
      widget.set.prescription.reps != null &&
      widget.set.prescription.repsMax != null;
  String? get _repRangeReference => _showRepRangeReference
      ? '${widget.set.prescription.reps} - ${widget.set.prescription.repsMax}'
      : null;

  static const double _revealWidth = TioSize.dp48 + TioSize.dp48;
  static const double _threshold = _revealWidth / 2;
  static const double _flickVelocity = 200;

  double _reveal = 0;
  bool _dragging = false;
  bool _pastRevealThreshold = false;

  int? _swipePointer;
  Offset? _swipeStart;
  Offset? _swipeLast;
  Duration? _swipeLastTime;
  bool _swipeActive = false;
  double _swipeVelocity = 0;

  double get _fullSwipeThreshold =>
      (context.size?.width ?? _revealWidth * 4) * 0.65;

  void _delete() {
    if (!widget.enabled) return;
    HapticFeedback.mediumImpact();
    widget.onRemove?.call();
  }

  @override
  void initState() {
    super.initState();
    _reveal = widget.isOpen ? _revealWidth : 0;
    _pastRevealThreshold = widget.isOpen;
    _valid = true;

    final initialReps = widget.performedReps ??
        (_showRepRangeReference ? null : widget.set.prescription.reps);
    _reps = TextEditingController(
      text: widget.startWithBlankReps ? '' : initialReps?.toString() ?? '',
    );
    _repsMax = TextEditingController(
      text: widget.startWithBlankReps
          ? ''
          : widget.set.prescription.repsMax?.toString() ?? '',
    );

    _originalKg = widget.performedLoadKg ?? widget.set.prescription.loadKg;
    _originalWeightText = _displayWeight(_originalKg);
    _weight = TextEditingController(text: _originalWeightText);

    _originalMeters = widget.performedDistanceMeters ??
        widget.set.prescription.distanceMeters;
    _originalDistanceText =
        RoutineSetInputLimits.displayDistanceKm(_originalMeters);
    _distance = TextEditingController(text: _originalDistanceText);

    _duration = TextEditingController(
      text: RoutineSetInputLimits.displayDurationSeconds(
        widget.performedDurationSeconds ??
            widget.set.prescription.durationSeconds,
      ),
    );
  }

  String _displayWeight(double? kg) => kg == null
      ? ''
      : UnitFormatters.formatWeight(
          kg,
          widget.unit,
          decimals: 3,
        ).split(' ').first;

  @override
  void didUpdateWidget(covariant WorkoutSetInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen || !widget.enabled) {
      _dragging = false;
      _reveal = widget.isOpen && widget.enabled ? _revealWidth : 0;
      _pastRevealThreshold = widget.isOpen && widget.enabled;
    }

    final before = oldWidget.set.prescription;
    final after = widget.set.prescription;
    final inlineEcho = before != after && after == _lastInlineEdit;
    if (before != after) _lastInlineEdit = null;
    final changedExternally = before != after && !inlineEcho;
    final modeChanged =
        (oldWidget.showRangeDraft || before.isRepRange) != _rangeMode;
    final unitChanged = oldWidget.unit != widget.unit;

    if (changedExternally && before.reps != after.reps) {
      _reps.text = _showRepRangeReference ? '' : after.reps?.toString() ?? '';
    }
    if (modeChanged && _rangeMode) {
      _repsMax.text = '';
    } else if (modeChanged ||
        (changedExternally && before.repsMax != after.repsMax)) {
      _repsMax.text = after.repsMax?.toString() ?? '';
    }
    if (unitChanged || (changedExternally && before.loadKg != after.loadKg)) {
      _originalKg = after.loadKg;
      _originalWeightText = _displayWeight(_originalKg);
      _weight.text = _originalWeightText;
    }
    if (changedExternally && before.distanceMeters != after.distanceMeters) {
      _originalMeters = after.distanceMeters;
      _originalDistanceText =
          RoutineSetInputLimits.displayDistanceKm(_originalMeters);
      _distance.text = _originalDistanceText;
    }
    if (changedExternally && before.durationSeconds != after.durationSeconds) {
      _duration.text = RoutineSetInputLimits.displayDurationSeconds(
        after.durationSeconds,
      );
    }
    final performedChanged = oldWidget.performedLoadKg !=
            widget.performedLoadKg ||
        oldWidget.performedReps != widget.performedReps ||
        oldWidget.performedDistanceMeters != widget.performedDistanceMeters ||
        oldWidget.performedDurationSeconds != widget.performedDurationSeconds;
    if (widget.isExecution &&
        (oldWidget.isLogged != widget.isLogged || performedChanged)) {
      final source = widget.isLogged
          ? widget
          : oldWidget.isLogged
              ? oldWidget
              : widget;
      _reps.text = source.performedReps?.toString() ?? '';
      _weight.text = _displayWeight(source.performedLoadKg);
      _originalKg = source.performedLoadKg;
      _originalWeightText = _displayWeight(_originalKg);
      _distance.text = source.performedDistanceMeters == null
          ? ''
          : RoutineSetInputLimits.displayDistanceKm(
              source.performedDistanceMeters,
            );
      _originalMeters = source.performedDistanceMeters;
      _originalDistanceText = RoutineSetInputLimits.displayDistanceKm(
        _originalMeters,
      );
      _duration.text = source.performedDurationSeconds == null
          ? ''
          : RoutineSetInputLimits.displayDurationSeconds(
              source.performedDurationSeconds,
            );
    }
    if (modeChanged ||
        changedExternally ||
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

      valid = (repsText.isEmpty ||
              (parsedReps != null &&
                  parsedReps > 0 &&
                  parsedReps <= RoutineSetInputLimits.maxReps)) &&
          (!inRange ||
              ((repsText.isEmpty && maxText.isEmpty) ||
                  (parsedReps != null &&
                      parsedMax != null &&
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
      valid = raw.isEmpty || (parsed != null && parsed.isFinite && parsed >= 0);
      if (raw == _originalDistanceText) {
        meters = _originalMeters;
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
      widget.onValidityChanged?.call(valid);
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
        widget.onChanged?.call(next);
      }
    } on ArgumentError {
      if (_valid) {
        _valid = false;
        widget.onValidityChanged?.call(false);
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

  void _pointerDown(PointerDownEvent event) {
    if (!widget.enabled || _swipePointer != null) return;
    _swipePointer = event.pointer;
    _swipeStart = event.position;
    _swipeLast = event.position;
    _swipeLastTime = event.timeStamp;
    _swipeActive = false;
    _swipeVelocity = 0;
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!widget.enabled ||
        event.pointer != _swipePointer ||
        _swipeStart == null ||
        _swipeLast == null) {
      return;
    }
    final total = event.position - _swipeStart!;
    if (!_swipeActive) {
      if (total.dx.abs() < kTouchSlop ||
          total.dx.abs() <= total.dy.abs() * 1.3) {
        return;
      }
      _swipeActive = true;
    }
    final dx = event.position.dx - _swipeLast!.dx;
    final elapsed = event.timeStamp - (_swipeLastTime ?? event.timeStamp);
    if (elapsed.inMicroseconds > 0) {
      _swipeVelocity =
          dx * Duration.microsecondsPerSecond / elapsed.inMicroseconds;
    }
    _swipeLast = event.position;
    _swipeLastTime = event.timeStamp;
    _dragUpdate(DragUpdateDetails(
      delta: Offset(dx, 0),
      globalPosition: event.position,
    ));
  }

  void _pointerUp(PointerUpEvent event) {
    if (event.pointer != _swipePointer) return;
    final wasActive = _swipeActive;
    final velocity = _swipeVelocity;
    _clearSwipePointer();
    if (wasActive && mounted) {
      _dragEnd(DragEndDetails(
        velocity: Velocity(pixelsPerSecond: Offset(velocity, 0)),
        primaryVelocity: velocity,
      ));
    }
  }

  void _pointerCancel(PointerCancelEvent event) {
    if (event.pointer != _swipePointer) return;
    _clearSwipePointer();
    if (mounted) {
      setState(() {
        _dragging = false;
        _reveal = widget.isOpen ? _revealWidth : 0;
        _pastRevealThreshold = widget.isOpen;
      });
    }
  }

  void _clearSwipePointer() {
    _swipePointer = null;
    _swipeStart = null;
    _swipeLast = null;
    _swipeLastTime = null;
    _swipeActive = false;
    _swipeVelocity = 0;
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;
    final width = context.size?.width ?? _revealWidth * 4;
    setState(() {
      _dragging = true;
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

    if (open && !_pastRevealThreshold) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _dragging = false;
      _reveal = open ? _revealWidth : 0;
      _pastRevealThreshold = open;
    });
    widget.onOpenChanged?.call(open);
  }

  Future<void> _toggleExecutionLog() async {
    if (widget.onToggleLogged == null) return;
    if (widget.isLogged) {
      await widget.onToggleLogged!();
      return;
    }
    final loadDraft = _weight.text.trim();
    final repsDraft = _reps.text.trim();
    final distanceDraft = _distance.text.trim();
    final durationDraft = _duration.text.trim();
    final loadKg = loadDraft.isEmpty ? null : double.tryParse(loadDraft);
    final reps = repsDraft.isEmpty ? null : int.tryParse(repsDraft);
    final distanceKm =
        distanceDraft.isEmpty ? null : double.tryParse(distanceDraft);
    final distanceMeters = distanceKm == null ? null : distanceKm * 1000;
    final durationSeconds =
        RoutineSetInputLimits.parseDurationSeconds(durationDraft);

    final isDistanceDuration =
        widget.exerciseType == ExerciseType.distanceDuration;
    final isDurationOnly = widget.exerciseType == ExerciseType.duration;
    final isValid = isDistanceDuration
        ? distanceKm != null &&
            distanceKm.isFinite &&
            distanceKm >= 0 &&
            durationSeconds != null
        : isDurationOnly
            ? durationSeconds != null
            : (loadDraft.isEmpty ||
                    (loadKg != null && loadKg.isFinite && loadKg >= 0)) &&
                (repsDraft.isEmpty ||
                    (reps != null &&
                        reps >= 0 &&
                        reps <= RoutineSetInputLimits.maxReps)) &&
                (loadKg != null || reps != null);

    if (!isValid) {
      if (mounted) setState(() {});
      return;
    }

    await widget.onToggleLogged!(
      reps: reps,
      loadKg: loadKg,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = context.tioColors;
    final setNumber = widget.index + 1;
    final canRemove = widget.enabled && widget.onRemove != null;

    final isLoggedState = widget.isExecution && widget.isLogged;
    final rowBgColor = isLoggedState
        ? colors.success.withAlpha(TioAlpha.alpha120)
        : colors.background;

    final foreground = Container(
      key: widget.rowKey,
      color: rowBgColor,
      child: Material(
        type: MaterialType.transparency,
        child: Listener(
          key: ValueKey('routine-set-swipe-${widget.set.id}'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: canRemove ? _pointerDown : null,
          onPointerMove: canRemove ? _pointerMove : null,
          onPointerUp: canRemove ? _pointerUp : null,
          onPointerCancel: canRemove ? _pointerCancel : null,
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.isExecution ? TioSpacing.lg : TioSpacing.none,
              right: widget.isExecution ? TioSpacing.lg : TioSpacing.none,
              top: widget.isExecution ? TioSpacing.xs : 0,
              bottom: widget.isExecution ? TioSpacing.xs : TioSpacing.sm,
            ),
            child: _fields(context),
          ),
        ),
      ),
    );

    return Semantics(
      customSemanticsActions: canRemove
          ? {
              CustomSemanticsAction(label: 'Delete Set $setNumber'): _delete,
            }
          : const {},
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _reveal),
          duration: _dragging
              ? Duration.zero
              : const Duration(milliseconds: TioDuration.ms180),
          curve: Curves.easeOutCubic,
          child: foreground,
          builder: (context, revealed, child) {
            final actionWidth =
                revealed > TioSpacing.sm ? revealed - TioSpacing.sm : 0.0;
            return Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right:
                          widget.isExecution ? TioSpacing.lg : TioSpacing.none,
                      top: widget.isExecution ? TioSpacing.xs : 0,
                      bottom:
                          widget.isExecution ? TioSpacing.xs : TioSpacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        width: actionWidth,
                        child: actionWidth <= 0
                            ? const SizedBox.shrink()
                            : TextButton(
                                key: ValueKey(
                                  'routine-set-remove-${widget.set.id}',
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: colors.danger,
                                  disabledBackgroundColor: colors.danger,
                                  foregroundColor: TioPalette.white,
                                  disabledForegroundColor: TioPalette.white,
                                  minimumSize: const Size(0, TioSize.dp38),
                                  fixedSize: MediaQuery.textScalerOf(context)
                                              .scale(TioSize.dp16) <=
                                          TioSize.dp24
                                      ? const Size.fromHeight(TioSize.dp38)
                                      : null,
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      TioInputTokens.radius,
                                    ),
                                  ),
                                ),
                                onPressed: widget.enabled && widget.isOpen
                                    ? _delete
                                    : null,
                                child: actionWidth >= _threshold
                                    ? const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: TioPalette.white,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(-revealed, 0),
                  child: child,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _fields(BuildContext context) {
    final colors = context.tioColors;
    final setNumber = widget.index + 1;
    final isComplete = widget.isExecution && widget.isLogged;

    final performedKg =
        isComplete ? widget.performedLoadKg : widget.set.prescription.loadKg;
    final performedLoadText = _displayWeight(performedKg);
    final performedReps =
        isComplete ? widget.performedReps : widget.set.prescription.reps;
    final performedRepsText = performedReps?.toString() ?? '–';

    return Row(
      children: [
        // 1. SET TYPE / NUMBER
        Semantics(
          label: 'Set $setNumber type, tap to select Set Type',
          button: true,
          child: InkWell(
            key: widget.setNumberKey ??
                ValueKey('routine-set-type-${widget.set.id}'),
            onTap: widget.enabled ? widget.onTypePressed : null,
            borderRadius: BorderRadius.circular(TioInputTokens.radius),
            child: Align(
              heightFactor: 1,
              child: UnconstrainedBox(
                constrainedAxis: Axis.horizontal,
                child: RoutineSetTypeBadge(
                  containerKey:
                      ValueKey('routine-set-type-box-${widget.set.id}'),
                  setType: widget.set.prescription.setType,
                  normalNumber: widget.normalNumber,
                  useEditSetNumberColor: widget.useEditSetNumberColor,
                  backgroundColor: isComplete ? TioPalette.transparent : null,
                  textColor: isComplete ? TioPalette.white : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: TioSpacing.sm),

        // 2. PREVIOUS
        if (widget.showPrevious) ...[
          SizedBox(
            width: TioSize.dp64,
            child: Semantics(
              label: 'Previous performed Set unavailable',
              child: Text(
                '–',
                key: ValueKey('routine-set-previous-${widget.set.id}'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isComplete
                      ? TioPalette.white.withAlpha(TioAlpha.alpha179)
                      : colors.textSecondary,
                  fontSize: TioFontSize.size14,
                ),
              ),
            ),
          ),
          const SizedBox(width: TioSpacing.sm),
        ],

        // 3. DISTANCE / DURATION
        if (widget.exerciseType == ExerciseType.distanceDuration) ...[
          Expanded(
            child: isComplete
                ? SizedBox(
                    height: TioSize.dp38,
                    child: Center(
                      child: Text(
                        widget.performedDistanceMeters != null
                            ? RoutineSetInputLimits.displayDistanceKm(
                                widget.performedDistanceMeters,
                              )
                            : '–',
                        style: const TextStyle(
                          color: TioPalette.white,
                          fontWeight: TioFontWeight.w600,
                          fontSize: TioFontSize.size14,
                        ),
                      ),
                    ),
                  )
                : Semantics(
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
            child: isComplete
                ? SizedBox(
                    height: TioSize.dp38,
                    child: Center(
                      child: Text(
                        widget.performedDurationSeconds != null
                            ? RoutineSetInputLimits.displayDurationSeconds(
                                widget.performedDurationSeconds,
                              )
                            : '–',
                        style: const TextStyle(
                          color: TioPalette.white,
                          fontWeight: TioFontWeight.w600,
                          fontSize: TioFontSize.size14,
                        ),
                      ),
                    ),
                  )
                : Semantics(
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

        // 4. WEIGHT & REPS
        if (widget.exerciseType != ExerciseType.distanceDuration &&
            widget.exerciseType != ExerciseType.duration) ...[
          Expanded(
            flex: _rangeMode ? 2 : 1,
            child: isComplete
                ? SizedBox(
                    height: TioSize.dp38,
                    child: Center(
                      child: Text(
                        performedLoadText.isEmpty ? '–' : performedLoadText,
                        style: const TextStyle(
                          color: TioPalette.white,
                          fontWeight: TioFontWeight.w600,
                          fontSize: TioFontSize.size14,
                        ),
                      ),
                    ),
                  )
                : Semantics(
                    label:
                        'Set $setNumber Weight in ${widget.unit == WeightUnit.kg ? 'kg' : 'lb'}',
                    child: TioInput.boxedNumber(
                      key: widget.loadKey ??
                          ValueKey('routine-set-weight-${widget.set.id}'),
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
            child: isComplete
                ? SizedBox(
                    height: TioSize.dp38,
                    child: Center(
                      child: Text(
                        performedRepsText,
                        style: const TextStyle(
                          color: TioPalette.white,
                          fontWeight: TioFontWeight.w600,
                          fontSize: TioFontSize.size14,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: _repRangeReference == null
                              ? 'Set $setNumber ${_rangeMode ? 'minimum Reps' : 'Reps'}'
                              : 'Set $setNumber Reps, planned range '
                                  '$_repRangeReference',
                          child: TioInput.boxedNumber(
                            key: widget.repsKey ??
                                ValueKey('routine-set-reps-${widget.set.id}'),
                            controller: _reps,
                            enabled: widget.enabled,
                            hint: _repRangeReference ?? '–',
                            keyboardType: TextInputType.number,
                            textInputAction: _rangeMode
                                ? TextInputAction.next
                                : TextInputAction.done,
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
                              key: ValueKey(
                                'routine-set-reps-max-${widget.set.id}',
                              ),
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
        ],

        // 5. RPE (Workout Execution Only)
        if (widget.isExecution && widget.showRpe) ...[
          const SizedBox(width: TioSpacing.sm),
          InkWell(
            key: widget.rpeKey,
            onTap: widget.enabled ? widget.onRpePressed : null,
            borderRadius: BorderRadius.circular(TioInputTokens.radius),
            child: widget.performedRpe != null
                ? SizedBox(
                    width: TioSize.dp44,
                    height: TioSize.dp38,
                    child: Center(
                      child: Text(
                        _formatNumber(widget.performedRpe!),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isComplete
                                      ? TioPalette.white
                                      : colors.textPrimary,
                                  fontWeight: TioFontWeight.w600,
                                ),
                      ),
                    ),
                  )
                : Container(
                    width: TioSize.dp44,
                    height: TioSize.dp38,
                    decoration: BoxDecoration(
                      color: isComplete
                          ? TioPalette.transparent
                          : colors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(TioInputTokens.radius),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.speed_rounded,
                      size: TioSize.dp20,
                      color:
                          isComplete ? TioPalette.white : colors.textSecondary,
                    ),
                  ),
          ),
        ],

        // 6. TOGGLE CHECKMARK (Workout Execution Only)
        if (widget.isExecution) ...[
          const SizedBox(width: TioSpacing.sm),
          SizedBox(
            width: TioSize.dp40,
            height: TioSize.dp38,
            child: IconButton(
              key: widget.toggleKey,
              tooltip: isComplete
                  ? 'Unlog set ${widget.normalNumber}'
                  : 'Log set ${widget.normalNumber}',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: TioSize.dp40,
                minHeight: TioSize.dp38,
                maxWidth: TioSize.dp40,
                maxHeight: TioSize.dp38,
              ),
              style: IconButton.styleFrom(
                backgroundColor:
                    isComplete ? colors.success : colors.surfaceVariant,
                foregroundColor:
                    isComplete ? TioPalette.white : colors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TioInputTokens.radius),
                ),
                minimumSize: const Size(TioSize.dp40, TioSize.dp38),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: widget.enabled ? _toggleExecutionLog : null,
              icon: Icon(
                Icons.check_rounded,
                color: isComplete ? TioPalette.white : colors.textSecondary,
                size: TioSize.dp20,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Backwards-compatible alias for [WorkoutSetInputRow].
typedef RoutineSetInputRow = WorkoutSetInputRow;
