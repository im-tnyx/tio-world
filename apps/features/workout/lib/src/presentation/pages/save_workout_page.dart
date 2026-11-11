import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/workout_save_metadata_limits.dart';
import '../../domain/models/workout_title_resolver.dart';
import '../widgets/workout_activity_type_sheet.dart';
import '../widgets/workout_duration_picker_sheet.dart';
import '../widgets/workout_rpe_sheet.dart';
import 'gym_selection_page.dart';

DateTime _minuteOnly(DateTime value) {
  return DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
  );
}

/// Shows the bottom sheet to select date and time using canonical [TioDateTimeWheelPicker].
///
/// Prevents selecting dates or times in the future (matching Nutrition meal log and
/// Progress weight log behavior).
Future<DateTime?> showWorkoutDateTimePickerSheet({
  required BuildContext context,
  required DateTime initialDateTime,
  DateTime Function()? clock,
}) {
  final now = _minuteOnly((clock?.call() ?? DateTime.now()).toLocal());
  final localCandidate = _minuteOnly(initialDateTime.toLocal());
  final localInitial = localCandidate.isAfter(now) ? now : localCandidate;

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) {
      DateTime selected = localInitial;
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final colors = context.tioColors;
          final currentCeiling =
              _minuteOnly((clock?.call() ?? DateTime.now()).toLocal());
          return SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(TioRadius.xl),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.lg,
                TioSpacing.md,
                TioSpacing.lg,
                TioSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: TioSize.dp40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary
                            .withValues(alpha: TioOpacity.opacity40),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: TioSpacing.md),
                  Text(
                    'Workout Date & Time',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: TioFontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TioSpacing.lg),
                  SizedBox(
                    height: TioWheelPickerTokens.viewportHeight,
                    child: TioDateTimeWheelPicker(
                      value: selected,
                      minimumDate: DateTime(2020),
                      maximumDate: currentCeiling,
                      resolveDateTime: (candidate) {
                        final ceiling = _minuteOnly(
                            (clock?.call() ?? DateTime.now()).toLocal());
                        return candidate.isAfter(ceiling) ? ceiling : candidate;
                      },
                      onChanged: (val) {
                        setSheetState(() => selected = val);
                      },
                    ),
                  ),
                  const SizedBox(height: TioSpacing.lg),
                  TioButton.primary(
                    key: const ValueKey('workout-date-picker-done'),
                    label: 'Done',
                    expand: true,
                    onPressed: () => Navigator.of(sheetContext).pop(selected),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Screen presented when user taps "Finish" on Active Workout to review and save the workout.
class SaveWorkoutPage extends StatefulWidget {
  const SaveWorkoutPage({
    required this.duration,
    required this.volumeKg,
    required this.completedSets,
    this.initialTitle,
    this.initialDescription,
    this.startedAt,
    this.initialWorkoutDateTime,
    this.initialWorkoutUtcOffsetMinutes,
    this.initialRpe,
    this.initialActivityType,
    this.initialGym,
    this.onSave,
    this.onLeaveDraft,
    this.onDiscard,
    this.clock,
    this.gymLocationRepository,
    this.notesOnly = false,
    this.sessionMetadataOnly = false,
    super.key,
  });

  final String? initialTitle;
  final String? initialDescription;
  final Duration duration;
  final double volumeKg;
  final int completedSets;
  final DateTime? startedAt;

  /// Wall-clock fields restored from the saved instant and UTC offset.
  final DateTime? initialWorkoutDateTime;
  final int? initialWorkoutUtcOffsetMinutes;
  final double? initialRpe;
  final String? initialActivityType;
  final String? initialGym;
  final DateTime Function()? clock;
  final GymLocationRepository? gymLocationRepository;
  final bool notesOnly;

  /// Enables title/date editing while keeping unsupported Save fields read-only.
  final bool sessionMetadataOnly;

  final FutureOr<bool> Function({
    required String title,
    required String? description,
    required DateTime date,
    required int utcOffsetMinutes,
    required double? rpe,
    required String activityType,
    required String? gym,
    Duration? duration,
  })? onSave;

  /// Persists unsaved Save-screen edits into the local workout draft on Back.
  /// Unlike [onSave], [title] is the raw input and must not be auto-generated.
  final FutureOr<bool> Function({
    required String title,
    required String? description,
    required DateTime date,
    required int utcOffsetMinutes,
    required double? rpe,
    required String activityType,
    required String? gym,
    required Duration duration,
  })? onLeaveDraft;

  final FutureOr<bool> Function()? onDiscard;

  @override
  State<SaveWorkoutPage> createState() => _SaveWorkoutPageState();
}

class _SaveWorkoutPageState extends State<SaveWorkoutPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _workoutDate;
  late int _workoutUtcOffsetMinutes;
  late Duration _workoutDuration;
  double? _workoutRpe;
  String _activityType = 'Weight Training';
  String? _selectedGym;
  bool _isSaving = false;
  bool _isDiscarding = false;
  bool _isLeaving = false;
  bool _allowPop = false;
  bool get _isBusy => _isSaving || _isDiscarding || _isLeaving;

  void _popWithResult([bool? result]) {
    setState(() => _allowPop = true);
    Navigator.of(context).pop(result);
  }

  Future<void> _leaveDraft() async {
    if (_isBusy) return;
    final onLeaveDraft = widget.onLeaveDraft;
    if (onLeaveDraft == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isLeaving = true);
    try {
      final saved = await onLeaveDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        date: _workoutDate,
        utcOffsetMinutes: _workoutUtcOffsetMinutes,
        rpe: _workoutRpe,
        activityType: _activityType,
        gym: _selectedGym,
        duration: _workoutDuration,
      );
      if (!mounted) return;
      if (saved) {
        _popWithResult();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout draft could not be saved.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  DateTime _currentNow() => (widget.clock?.call() ?? DateTime.now()).toLocal();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialTitle ?? '',
    );
    _titleController.addListener(() {
      if (mounted) setState(() {});
    });
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _workoutDuration = widget.duration;
    _workoutRpe = widget.initialRpe;
    _activityType = widget.initialActivityType ?? _activityType;
    _selectedGym = widget.initialGym;
    final now = _currentNow();
    final restored = widget.initialWorkoutDateTime;
    if (restored != null) {
      _workoutDate = DateTime(
        restored.year,
        restored.month,
        restored.day,
        restored.hour,
        restored.minute,
      );
      _workoutUtcOffsetMinutes = widget.initialWorkoutUtcOffsetMinutes ??
          restored.timeZoneOffset.inMinutes;
    } else {
      final initial = widget.startedAt?.toLocal() ?? now;
      _workoutDate = initial.isAfter(now) ? now : initial;
      _workoutUtcOffsetMinutes = _workoutDate.timeZoneOffset.inMinutes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDuration() async {
    if (_isBusy) return;
    final picked = await showWorkoutDurationPickerSheet(
      context: context,
      initialDuration: _workoutDuration,
    );
    if (picked != null && mounted) {
      setState(() {
        _workoutDuration = picked;
      });
    }
  }

  Future<void> _pickDateTime() async {
    if (_isBusy) return;
    final picked = await showWorkoutDateTimePickerSheet(
      context: context,
      initialDateTime: _workoutDate,
      clock: widget.clock,
    );
    if (picked != null && mounted) {
      setState(() {
        _workoutDate = picked;
        _workoutUtcOffsetMinutes = picked.timeZoneOffset.inMinutes;
      });
    }
  }

  Future<void> _pickGym() async {
    if (_isBusy) return;
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (routeContext) => GymSelectionPage(
          currentGymName: _selectedGym,
          repository: widget.gymLocationRepository,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedGym = picked;
      });
    }
  }

  Future<void> _pickActivityType() async {
    if (_isBusy) return;
    final picked = await showWorkoutActivityTypeSheet(
      context: context,
      currentActivityType: _activityType,
    );
    if (picked != null && mounted) {
      setState(() {
        _activityType = picked;
      });
    }
  }

  Future<void> _pickWorkoutRpe() async {
    if (_isBusy) return;
    final picked = await showWorkoutRpeSheet(
      context: context,
      title: 'Workout RPE',
      subtitle: 'How hard was this workout?',
      initialRpe: _workoutRpe,
    );
    if (picked != null && mounted) {
      setState(() {
        _workoutRpe = picked > 0 ? picked : null;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isBusy) return;
    setState(() => _isSaving = true);
    try {
      final title = resolveWorkoutTitle(
        customTitle: _titleController.text,
        selectedLocalDateTime: _workoutDate,
      );
      final description = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null;

      // Preserve raw title and Save edits for a retry. A generated fallback is
      // only a submission value, never a replacement for the user's input.
      if (widget.onLeaveDraft != null) {
        final stored = await widget.onLeaveDraft!(
          title: _titleController.text,
          description: _descriptionController.text,
          date: _workoutDate,
          utcOffsetMinutes: _workoutUtcOffsetMinutes,
          rpe: _workoutRpe,
          activityType: _activityType,
          gym: _selectedGym,
          duration: _workoutDuration,
        );
        if (!stored || !mounted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Workout draft could not be saved.')),
            );
          }
          return;
        }
      }

      if (widget.onSave != null) {
        final saved = await widget.onSave!(
          title: title,
          description: description,
          date: _workoutDate,
          utcOffsetMinutes: _workoutUtcOffsetMinutes,
          rpe: _workoutRpe,
          activityType: _activityType,
          gym: _selectedGym,
          duration: _workoutDuration,
        );
        if (saved == true && mounted) {
          _popWithResult(true);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Workout could not be saved.')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout could not be saved.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDiscard() async {
    if (_isBusy) return;
    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      title: 'Discard workout?',
      message: 'This workout and all logged sets will be discarded.',
      confirmLabel: 'Discard workout',
      cancelLabel: 'Keep working out',
      intent: TioConfirmationIntent.destructive,
    );
    if (confirmed != true || !mounted) return;

    final onDiscard = widget.onDiscard;
    if (onDiscard == null) {
      _popWithResult(false);
      return;
    }

    setState(() => _isDiscarding = true);
    try {
      final discarded = await onDiscard();
      if (!mounted) return;
      if (discarded) {
        _popWithResult(false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout could not be discarded.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDiscarding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: TioAppBar(
        automaticallyImplyLeading: false,
        leading: PopScope(
          canPop: widget.onLeaveDraft == null || _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) unawaited(_leaveDraft());
          },
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _leaveDraft,
          ),
        ),
        title: const Text('Save Workout'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: TioSpacing.md),
            child: SizedBox(
              height: TioSize.dp34,
              child: TioButton.primary(
                key: const ValueKey('save-workout-submit-button'),
                label: 'Save',
                enabled: !_isBusy,
                onPressed: _handleSave,
                loading: _isSaving,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Workout Title row without box / outline (pure text as in screenshot)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('save-workout-title-input'),
                    controller: _titleController,
                    readOnly: widget.notesOnly || _isBusy,
                    maxLength: WorkoutSaveMetadataLimits.maxTitleLength,
                    buildCounter: (
                      context, {
                      required currentLength,
                      required isFocused,
                      required maxLength,
                    }) =>
                        null,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: TioFontWeight.w700,
                      color: colors.textPrimary,
                    ),
                    cursorColor: colors.primary,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      fillColor: TioPalette.transparent,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Workout name',
                      hintStyle: textTheme.headlineSmall?.copyWith(
                        color: colors.textSecondary
                            .withValues(alpha: TioOpacity.opacity50),
                        fontWeight: TioFontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (!widget.notesOnly && _titleController.text.isNotEmpty)
                  GestureDetector(
                    key: const ValueKey('save-workout-title-clear'),
                    onTap: _isBusy
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            _titleController.clear();
                          },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceVariant,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: TioSize.dp16,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: TioSpacing.md),

            // Stats Strip: Duration, Volume, Sets
            Row(
              children: [
                Expanded(
                  child: _SaveStatItem(
                    key: const ValueKey('save-workout-duration-stat'),
                    label: 'Duration',
                    value: _formatDuration(_workoutDuration),
                    valueColor: colors.primary,
                    onTap: (widget.notesOnly ||
                            widget.sessionMetadataOnly ||
                            _isBusy)
                        ? null
                        : _pickDuration,
                  ),
                ),
                Expanded(
                  child: _SaveStatItem(
                    label: 'Volume',
                    value: '${_formatNumber(widget.volumeKg)} kg',
                  ),
                ),
                Expanded(
                  child: _SaveStatItem(
                    label: 'Sets',
                    value: '${widget.completedSets}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            Divider(
                height: 1,
                color: colors.surfaceVariant
                    .withValues(alpha: TioOpacity.opacity50)),
            const SizedBox(height: TioSpacing.lg),

            // Add a photo / video dashed box
            _DashedBorderCard(
              key: const ValueKey('save-workout-photo-card'),
              onTap: () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Photo / Video upload coming soon')),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: TioSize.dp24,
                    color: colors.textPrimary,
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Text(
                    'Add a photo / video',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: TioFontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TioSpacing.lg),

            // Description without box (pure text field as in reference screenshot)
            Text(
              'Description',
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: TioFontWeight.w500,
              ),
            ),
            const SizedBox(height: TioSpacing.xs),
            TextField(
              key: const ValueKey('save-workout-description-input'),
              controller: _descriptionController,
              readOnly: _isBusy,
              maxLength: WorkoutSaveMetadataLimits.maxDescriptionUtf8Bytes,
              buildCounter: (
                context, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) =>
                  null,
              maxLines: 4,
              minLines: 1,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
              ),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                fillColor: TioPalette.transparent,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: TioSpacing.xs),
                hintText: 'How did your workout go? Leave some notes here...',
                hintStyle: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary
                      .withValues(alpha: TioOpacity.opacity50),
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.md),
            Divider(
                height: 1,
                color: colors.surfaceVariant
                    .withValues(alpha: TioOpacity.opacity50)),

            // Options List
            _SaveOptionTile(
              key: const ValueKey('save-workout-date-tile'),
              icon: Icons.calendar_month_outlined,
              title: 'Date',
              value: _formatDateTile(_workoutDate),
              onTap: widget.notesOnly || _isBusy ? null : _pickDateTime,
            ),
            _SaveOptionTile(
              key: const ValueKey('save-workout-gym-tile'),
              icon: Icons.location_on_outlined,
              title: 'Gym',
              value: _selectedGym ?? 'Select',
              valueColor: _selectedGym != null
                  ? colors.textPrimary
                  : colors.textSecondary,
              trailingWidget: !widget.notesOnly && _selectedGym != null
                  ? GestureDetector(
                      key: const ValueKey('save-workout-gym-clear'),
                      onTap: _isBusy
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedGym = null);
                            },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: TioSize.dp18,
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : null,
              onTap: (widget.notesOnly || widget.sessionMetadataOnly || _isBusy)
                  ? null
                  : _pickGym,
            ),
            _SaveOptionTile(
              key: const ValueKey('save-workout-activity-type-tile'),
              icon: Icons.fitness_center_rounded,
              title: 'Activity Type',
              value: _activityType,
              onTap: (widget.notesOnly || widget.sessionMetadataOnly || _isBusy)
                  ? null
                  : _pickActivityType,
            ),
            _SaveOptionTile(
              key: const ValueKey('save-workout-rpe-tile'),
              icon: Icons.speed_rounded,
              title: 'Workout RPE',
              value: _workoutRpe != null
                  ? '${RpeMetadata.format(_workoutRpe!)} • ${RpeMetadata.scale[_workoutRpe!]?.title ?? ''}'
                  : 'Rate workout',
              valueColor:
                  _workoutRpe != null ? colors.primary : colors.textSecondary,
              onTap: (widget.notesOnly || widget.sessionMetadataOnly || _isBusy)
                  ? null
                  : _pickWorkoutRpe,
            ),
            const _SaveOptionTile(
              key: ValueKey('save-workout-routine-settings-tile'),
              icon: Icons.assignment_outlined,
              title: 'Routine Settings',
              enabled: false,
              onTap: null,
            ),
            const _SaveOptionTile(
              key: ValueKey('save-workout-sync-tile'),
              icon: Icons.sync_rounded,
              title: 'Sync With',
              value: 'Health Connect',
              enabled: false,
              onTap: null,
            ),

            const SizedBox(height: TioSpacing.xl),

            // Discard Workout
            Center(
              child: TextButton(
                key: const ValueKey('save-workout-discard-button'),
                onPressed: _isBusy ? null : _confirmDiscard,
                child: Text(
                  'Discard Workout',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.danger,
                    fontWeight: TioFontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: TioSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SaveStatItem extends StatelessWidget {
  const _SaveStatItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: TioSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: TioFontWeight.w600,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(TioRadius.sm),
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

class _SaveOptionTile extends StatelessWidget {
  const _SaveOptionTile({
    required this.icon,
    required this.title,
    super.key,
    this.value,
    this.valueColor,
    this.trailingWidget,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Color? valueColor;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TioSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  colors.surfaceVariant.withValues(alpha: TioOpacity.opacity50),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: TioSize.dp22,
              color: enabled ? colors.textPrimary : colors.textSecondary,
            ),
            const SizedBox(width: TioSpacing.md),
            Text(
              title,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: TioFontWeight.w500,
                color: enabled ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value != null) ...[
                    Flexible(
                      child: Text(
                        value!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: textTheme.bodyMedium?.copyWith(
                          color: valueColor ??
                              (enabled
                                  ? colors.textSecondary
                                  : colors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: TioSpacing.xs),
                  ],
                  trailingWidget ??
                      Icon(
                        Icons.chevron_right_rounded,
                        size: TioSize.dp20,
                        color: colors.textSecondary
                            .withValues(alpha: TioOpacity.opacity70),
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

/// Dashed border container matching reference photo card
class _DashedBorderCard extends StatelessWidget {
  const _DashedBorderCard({
    required this.child,
    super.key,
    this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return InkWell(
      borderRadius: BorderRadius.circular(TioRadius.lg),
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: colors.textSecondary.withValues(alpha: TioOpacity.opacity35),
          radius: TioRadius.lg,
          strokeWidth: 1.5,
          dashWidth: 6,
          dashSpace: 4,
        ),
        child: Container(
          height: 100,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(TioSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        canvas.drawPath(metric.extractPath(distance, distance + length), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  if (totalSeconds < 0) return '0s';
  if (totalSeconds < 60) {
    return '${totalSeconds}s';
  }
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = totalSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes}min';
  }
  if (seconds > 0) {
    return '${minutes}min ${seconds}s';
  }
  return '${minutes}min';
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    final intVal = value.toInt();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
  return value.toStringAsFixed(1);
}

String _formatDateTile(DateTime date) {
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  final hour =
      date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
  final ampm = date.hour >= 12 ? 'PM' : 'AM';
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $ampm';
}
