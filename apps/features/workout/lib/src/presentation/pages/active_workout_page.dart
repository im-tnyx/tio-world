import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../controllers/active_workout_controller.dart';
import '../controllers/active_workout_state.dart';
import '../library/routines/routine_set_input_limits.dart';

/// Focused Active Workout surface for resuming and recovering a persisted
/// session. App composition supplies the auth-bound controller; the feature
/// never reaches into Auth, Supabase or routing composition.
class ActiveWorkoutPage extends StatelessWidget {
  const ActiveWorkoutPage({
    required this.controller,
    super.key,
    this.onBack,
    this.showStartPreview = false,
  });

  final ActiveWorkoutController? controller;
  final VoidCallback? onBack;
  /// Entry-only UI: never creates a session, exercise, or fake identity.
  final bool showStartPreview;

  @override
  Widget build(BuildContext context) {
    return _ActiveWorkoutBody(
      controller: controller,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
      showStartPreview: showStartPreview,
    );
  }
}

class _ActiveWorkoutBody extends StatefulWidget {
  const _ActiveWorkoutBody({
    required this.controller,
    required this.onBack,
    required this.showStartPreview,
  });

  final ActiveWorkoutController? controller;
  final VoidCallback onBack;
  final bool showStartPreview;

  @override
  State<_ActiveWorkoutBody> createState() => _ActiveWorkoutBodyState();
}

class _ActiveWorkoutBodyState extends State<_ActiveWorkoutBody> {
  ActiveWorkoutController? _controller;
  final ValueNotifier<bool> _sessionActive = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _bindController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant _ActiveWorkoutBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _bindController(widget.controller);
    }
  }

  void _bindController(ActiveWorkoutController? next) {
    _sessionActive.value = false;
    _controller?.removeListener(_onControllerChanged);
    _controller?.stopDurationTicker();
    _controller = next;
    next?.addListener(_onControllerChanged);
    _sessionActive.value = next != null;
    if (next != null) {
      Future<void>.microtask(next.restoreActiveSession);
    }
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    _sessionActive.value =
        controller.state.status != ActiveWorkoutStatus.authInvalidated;
    _syncTicker(controller.state);
    setState(() {});
  }

  void _syncTicker(ActiveWorkoutState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state.status == ActiveWorkoutStatus.active) {
      controller.startDurationTicker();
    } else {
      controller.stopDurationTicker();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _controller?.stopDurationTicker();
    _sessionActive.dispose();
    super.dispose();
  }

  Future<void> _pauseOrResume(ActiveWorkoutState state) async {
    final controller = _controller;
    if (controller == null || state.isActionPending) return;
    if (state.status == ActiveWorkoutStatus.active) {
      await controller.pauseSession();
    } else if (state.status == ActiveWorkoutStatus.paused) {
      await controller.resumeSession();
    }
  }

  Future<void> _showPauseDetails(ActiveWorkoutState state) async {
    final controller = _controller;
    final session = state.session;
    if (controller == null || session == null || state.isTerminal) return;

    final shouldToggle = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.sm,
            TioSpacing.lg,
            TioSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Duration',
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: TioSpacing.lg),
              _PauseDetailRow(
                label: 'Duration',
                value: _formatDuration(state.activeElapsedDuration),
              ),
              const SizedBox(height: TioSpacing.sm),
              _PauseDetailRow(
                label: 'Start time',
                value: _formatStartTime(context, session.time.startedAtUtc),
              ),
              const SizedBox(height: TioSpacing.lg),
              TioButton.primary(
                key: const ValueKey('active-workout-pause-sheet-action'),
                label: state.status == ActiveWorkoutStatus.active
                    ? 'Pause Workout Timer'
                    : 'Resume Workout Timer',
                leading: Icon(
                  state.status == ActiveWorkoutStatus.active
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                onPressed: state.isActionPending
                    ? null
                    : () => Navigator.of(sheetContext).pop(true),
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted ||
        shouldToggle != true ||
        !identical(controller, _controller)) {
      return;
    }
    await _pauseOrResume(state);
  }

  Future<void> _complete(ActiveWorkoutState state) async {
    final controller = _controller;
    if (controller == null || state.isActionPending || !state.isRunning) return;

    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      title: 'Finish workout?',
      message: 'Your completed sets will be saved to this workout session.',
      confirmLabel: 'Finish workout',
      cancelLabel: 'Keep working out',
      intent: TioConfirmationIntent.standard,
      activeWhileOpen: _sessionActive,
    );
    if (!mounted ||
        confirmed != true ||
        !identical(controller, _controller) ||
        !_sessionActive.value) {
      return;
    }
    await controller.completeSession();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final state = controller?.state;

    return Scaffold(
      appBar: const TioAppBar(title: Text('Log Workout')),
      body: SafeArea(
        child: controller == null || state == null
            ? _UnavailableState(onBack: widget.onBack)
            : _buildState(context, controller, state),
      ),
    );
  }

  Widget _buildState(
    BuildContext context,
    ActiveWorkoutController controller,
    ActiveWorkoutState state,
  ) {
    switch (state.status) {
      case ActiveWorkoutStatus.initial:
      case ActiveWorkoutStatus.restoring:
        return const _LoadingState();
      case ActiveWorkoutStatus.noSession:
        if (widget.showStartPreview) {
          return _StartWorkoutPreview(onBack: widget.onBack);
        }
        return _MessageState(
          key: const ValueKey('active-workout-no-session'),
          title: 'No active workout',
          message: 'There is no workout session to resume right now.',
          actionLabel: 'Back to Workout',
          onAction: widget.onBack,
        );
      case ActiveWorkoutStatus.authInvalidated:
        return _MessageState(
          key: const ValueKey('active-workout-auth-invalidated'),
          title: 'Session expired',
          message: 'Sign in again to access this workout session.',
          actionLabel: 'Back',
          onAction: widget.onBack,
        );
      case ActiveWorkoutStatus.reconciliationRequired:
        return _MessageState(
          key: const ValueKey('active-workout-reconciliation'),
          title: 'Workout needs to reconnect',
          message: state.errorMessage ??
              'We could not confirm the latest workout state.',
          actionLabel: 'Retry',
          loading: state.isActionPending,
          onAction:
              state.isActionPending ? null : () => controller.reconcileState(),
          secondaryLabel: 'Back',
          onSecondary: widget.onBack,
        );
      case ActiveWorkoutStatus.completed:
      case ActiveWorkoutStatus.discarded:
      case ActiveWorkoutStatus.active:
      case ActiveWorkoutStatus.paused:
        final session = state.session;
        if (session == null) {
          return _UnavailableState(onBack: widget.onBack);
        }
        return _SessionState(
          state: state,
          controller: controller,
          onDurationPressed:
              state.isActionPending ? null : () => _showPauseDetails(state),
          onPauseOrResume:
              state.isActionPending ? null : () => _pauseOrResume(state),
          onComplete: state.isActionPending ||
                  state.isTerminal ||
                  state.performedSets.isEmpty
              ? null
              : () => _complete(state),
          onBack: widget.onBack,
        );
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Restoring active workout',
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

/// The Play FAB is a UI-only entry, not an empty-first workout mutation.
/// Snapshot-based execution appears here automatically when a real session
/// exists. No made-up Routine, Exercise, timer or completion is persisted.
class _StartWorkoutPreview extends StatelessWidget {
  const _StartWorkoutPreview({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('active-workout-start-preview'),
      padding: const EdgeInsets.all(TioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TioCard(
            variant: TioCardVariant.elevated,
            child: _WorkoutStats(
              duration: Duration.zero,
              volumeKg: 0,
              completedSets: 0,
              onDurationPressed: null,
            ),
          ),
          const SizedBox(height: TioSpacing.lg),
          TioCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'No exercises yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TioSpacing.sm),
                Text(
                  'This is the Active Workout UI preview. No workout has '
                  'started or been saved. Exercise selection and starting '
                  'a session will be connected in a later approved slice.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: TioSpacing.lg),
                _SetHeader(),
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.lg),
          TioButton.supporting(
            key: const ValueKey('active-workout-preview-add-set'),
            label: 'Add Set',
            enabled: false,
            onPressed: null,
            expand: true,
          ),
          const SizedBox(height: TioSpacing.sm),
          TioButton.primary(
            key: const ValueKey('active-workout-preview-add-exercise'),
            label: 'Add Exercise',
            enabled: false,
            onPressed: null,
            expand: true,
          ),
          const SizedBox(height: TioSpacing.sm),
          TioButton.primary(
            key: const ValueKey('active-workout-preview-finish'),
            label: 'Finish workout',
            enabled: false,
            onPressed: null,
            expand: true,
          ),
          const SizedBox(height: TioSpacing.sm),
          TioButton.secondary(
            label: 'Back to Workout',
            onPressed: onBack,
            expand: true,
          ),
        ],
      ),
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _MessageState(
      key: const ValueKey('active-workout-unavailable'),
      title: 'Active Workout unavailable',
      message: 'This workout is not available for the current account.',
      actionLabel: 'Back',
      onAction: onBack,
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.loading = false,
    super.key,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TioSpacing.lg),
        child: TioCard(
          variant: TioCardVariant.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TioSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: TioSpacing.lg),
              TioButton.primary(
                key: ValueKey('active-workout-$actionLabel'),
                label: actionLabel,
                onPressed: onAction,
                expand: true,
                loading: loading,
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: TioSpacing.sm),
                TioButton.secondary(
                  label: secondaryLabel!,
                  onPressed: onSecondary,
                  expand: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionState extends StatelessWidget {
  const _SessionState({
    required this.state,
    required this.controller,
    required this.onDurationPressed,
    required this.onPauseOrResume,
    required this.onComplete,
    required this.onBack,
  });

  final ActiveWorkoutState state;
  final ActiveWorkoutController controller;
  final VoidCallback? onDurationPressed;
  final VoidCallback? onPauseOrResume;
  final VoidCallback? onComplete;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final session = state.session!;
    final snapshot = session.snapshot;
    final statusLabel = switch (state.status) {
      ActiveWorkoutStatus.active => 'In progress',
      ActiveWorkoutStatus.paused => 'Paused',
      ActiveWorkoutStatus.completed => 'Completed',
      ActiveWorkoutStatus.discarded => 'Discarded',
      _ => 'Unavailable',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TioCard(
            key: const ValueKey('active-workout-session-summary'),
            variant: TioCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        snapshot.routineName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(statusLabel),
                  ],
                ),
                const SizedBox(height: TioSpacing.md),
                _WorkoutStats(
                  duration: state.activeElapsedDuration,
                  volumeKg: _volumeKg(state.performedSets),
                  completedSets: state.performedSets.length,
                  onDurationPressed: onDurationPressed,
                ),
              ],
            ),
          ),
          if (state.errorMessage case final message?) ...[
            const SizedBox(height: TioSpacing.sm),
            Semantics(
              liveRegion: true,
              child: TioCard(
                key: const ValueKey('active-workout-action-error'),
                child: Text(
                  message,
                  style: TextStyle(color: context.tioColors.danger),
                ),
              ),
            ),
          ],
          const SizedBox(height: TioSpacing.lg),
          if (snapshot.exercises.isEmpty)
            const TioCard(
              child: Text('No exercises were captured for this session.'),
            )
          else
            ...snapshot.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: TioSpacing.md),
                child: _ExerciseExecutionCard(
                  key: ValueKey(
                    'active-workout-exercise-${exercise.occurrenceIndex}',
                  ),
                  exercise: exercise,
                  performedSets: state.performedSets,
                  actionPending: state.isActionPending,
                  onLogSet: (setIndex, reps, loadKg) => controller.logSet(
                    sessionExerciseIndex: exercise.occurrenceIndex,
                    setIndex: setIndex,
                    reps: reps,
                    loadKg: loadKg,
                  ),
                  onRemoveSet: controller.removeSet,
                ),
              ),
            ),
          const SizedBox(height: TioSpacing.sm),
          TioButton.supporting(
            key: const ValueKey('active-workout-add-set'),
            label: 'Add Set',
            leading: const Icon(Icons.add_rounded),
            enabled: !state.isTerminal && !state.isActionPending,
            onPressed: state.isTerminal || state.isActionPending
                ? null
                : () => _showDeferredAction(context, 'Add Set'),
            expand: true,
          ),
          const SizedBox(height: TioSpacing.sm),
          TioButton.primary(
            key: const ValueKey('active-workout-add-exercise'),
            label: 'Add Exercise',
            leading: const Icon(Icons.add_rounded),
            enabled: !state.isTerminal && !state.isActionPending,
            onPressed: state.isTerminal || state.isActionPending
                ? null
                : () => _showDeferredAction(context, 'Add Exercise'),
            expand: true,
          ),
          const SizedBox(height: TioSpacing.sm),
          if (!state.isTerminal) ...[
            TioButton.secondary(
              key: const ValueKey('active-workout-pause-resume'),
              label: state.status == ActiveWorkoutStatus.active
                  ? 'Pause workout'
                  : 'Resume workout',
              enabled: onPauseOrResume != null,
              onPressed: onPauseOrResume,
              loading: state.isActionPending,
              expand: true,
            ),
            const SizedBox(height: TioSpacing.sm),
            TioButton.primary(
              key: const ValueKey('active-workout-complete'),
              label: 'Finish workout',
              enabled: onComplete != null,
              onPressed: onComplete,
              loading: state.isActionPending,
              expand: true,
            ),
            if (state.performedSets.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: TioSpacing.xs),
                child: Text(
                  'Log at least one set before finishing this workout.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.tioColors.textSecondary,
                      ),
                ),
              ),
          ] else ...[
            TioButton.secondary(
              label: 'Back to Workout',
              onPressed: onBack,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkoutStats extends StatelessWidget {
  const _WorkoutStats({
    required this.duration,
    required this.volumeKg,
    required this.completedSets,
    required this.onDurationPressed,
  });

  final Duration duration;
  final double volumeKg;
  final int completedSets;
  final VoidCallback? onDurationPressed;

  @override
  Widget build(BuildContext context) {
    final durationContent = _WorkoutStat(
      label: 'Duration',
      value: _formatDuration(duration),
      valueColor: context.tioColors.primary,
    );
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: onDurationPressed != null,
            label: 'Workout duration and pause controls',
            child: InkWell(
              key: const ValueKey('active-workout-duration-stat'),
              borderRadius: BorderRadius.circular(TioRadius.md),
              onTap: onDurationPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: TioSpacing.xs),
                child: durationContent,
              ),
            ),
          ),
        ),
        Expanded(
          child: _WorkoutStat(
            label: 'Volume',
            value: '${_formatNumber(volumeKg)} kg',
          ),
        ),
        Expanded(
          child: _WorkoutStat(
            label: 'Sets',
            value: '$completedSets',
          ),
        ),
      ],
    );
  }
}

class _WorkoutStat extends StatelessWidget {
  const _WorkoutStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.tioColors.textSecondary,
              ),
        ),
        const SizedBox(height: TioSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor ?? context.tioColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _PauseDetailRow extends StatelessWidget {
  const _PauseDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.tioColors.primary,
              ),
        ),
      ],
    );
  }
}

class _ExerciseExecutionCard extends StatelessWidget {
  const _ExerciseExecutionCard({
    required this.exercise,
    required this.performedSets,
    required this.actionPending,
    required this.onLogSet,
    required this.onRemoveSet,
    super.key,
  });

  final SessionExerciseSnapshot exercise;
  final List<PerformedSet> performedSets;
  final bool actionPending;
  final Future<bool> Function(int setIndex, int? reps, double? loadKg)
      onLogSet;
  final Future<bool> Function(String setId) onRemoveSet;

  PerformedSet? _performedFor(int setIndex) {
    for (final item in performedSets) {
      if (item.sessionExerciseIndex == exercise.occurrenceIndex &&
          item.setIndex == setIndex) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('${exercise.prescribedSets.length} sets'),
            ],
          ),
          const SizedBox(height: TioSpacing.md),
          _SetHeader(),
          const SizedBox(height: TioSpacing.xs),
          ...exercise.prescribedSets.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: TioSpacing.xs),
                  child: _ActiveSetRow(
                    setIndex: entry.key,
                    prescription: entry.value,
                    performed: _performedFor(entry.key),
                    disabled: actionPending,
                    onLog: (reps, loadKg) => onLogSet(entry.key, reps, loadKg),
                    onRemove: (id) => onRemoveSet(id),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SetHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.tioColors.textSecondary,
        );
    return Row(
      children: [
        SizedBox(width: TioSize.dp40, child: Text('SET', style: style)),
        Expanded(child: Text('PREVIOUS', style: style)),
        SizedBox(width: TioSize.dp64, child: Text('KG', style: style)),
        SizedBox(width: TioSize.dp64, child: Text('REPS', style: style)),
        SizedBox(width: TioSize.dp48, child: Text('✓', style: style)),
      ],
    );
  }
}

/// Actual performed-set editor. Prescription values are hints to confirm,
/// never a hidden automatic write. Only the explicit check calls logSet().
class _ActiveSetRow extends StatefulWidget {
  const _ActiveSetRow({
    required this.setIndex,
    required this.prescription,
    required this.performed,
    required this.disabled,
    required this.onLog,
    required this.onRemove,
  });

  final int setIndex;
  final SetPrescription prescription;
  final PerformedSet? performed;
  final bool disabled;
  final Future<bool> Function(int? reps, double? loadKg) onLog;
  final Future<bool> Function(String setId) onRemove;

  @override
  State<_ActiveSetRow> createState() => _ActiveSetRowState();
}

class _ActiveSetRowState extends State<_ActiveSetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;

  String _weightText() {
    final load = widget.performed?.loadKg ?? widget.prescription.loadKg;
    return load == null ? '' : _formatNumber(load);
  }

  String _repsText() =>
      (widget.performed?.reps ?? widget.prescription.reps)?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(text: _weightText());
    _reps = TextEditingController(text: _repsText());
  }

  @override
  void didUpdateWidget(covariant _ActiveSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.performed?.id != widget.performed?.id ||
        oldWidget.prescription != widget.prescription) {
      _weight.text = _weightText();
      _reps.text = _repsText();
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
    final performed = widget.performed;
    final isComplete = performed != null;
    final loadDraft = _weight.text.trim();
    final repsDraft = _reps.text.trim();
    final loadKg = loadDraft.isEmpty ? null : double.tryParse(loadDraft);
    final reps = repsDraft.isEmpty ? null : int.tryParse(repsDraft);
    final valid = (loadDraft.isEmpty ||
            (loadKg != null && loadKg.isFinite && loadKg >= 0)) &&
        (repsDraft.isEmpty ||
            (reps != null && reps >= 0 &&
                reps <= RoutineSetInputLimits.maxReps)) &&
        (loadKg != null || reps != null);
    final rowColor = isComplete
        ? context.tioColors.success.withAlpha(TioAlpha.alpha20)
        : context.tioColors.surfaceVariant;
    return Container(
      key: ValueKey('active-workout-set-${widget.setIndex}'),
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.sm,
        vertical: TioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(TioRadius.sm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: TioSize.dp40,
            child: Text('${widget.setIndex + 1}',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: Text(
              _prescriptionSummary(widget.prescription),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.tioColors.textSecondary,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: TioSize.dp64,
            child: isComplete
                ? Text(_formatNullableNumber(performed.loadKg))
                : Semantics(
                    label: 'Set ${widget.setIndex + 1} actual weight in kg',
                    child: TioInput.boxedNumber(
                      key: ValueKey('active-workout-load-${widget.setIndex}'),
                      controller: _weight,
                      hint: '-',
                      enabled: !widget.disabled,
                      inputFormatters: [RoutineSetInputLimits.weight],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
          ),
          SizedBox(
            width: TioSize.dp64,
            child: isComplete
                ? Text('${performed.reps ?? '-'}')
                : Semantics(
                    label: 'Set ${widget.setIndex + 1} actual reps',
                    child: TioInput.boxedNumber(
                      key: ValueKey('active-workout-reps-${widget.setIndex}'),
                      controller: _reps,
                      hint: '-',
                      enabled: !widget.disabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        RoutineSetInputLimits.reps,
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
          ),
          SizedBox(
            width: TioSize.dp48,
            child: IconButton(
              key: ValueKey('active-workout-set-toggle-${widget.setIndex}'),
              tooltip: isComplete
                  ? 'Unlog set ${widget.setIndex + 1}'
                  : 'Log set ${widget.setIndex + 1}',
              onPressed: widget.disabled || (!isComplete && !valid)
                  ? null
                  : () async {
                      if (performed case final item?) {
                        await widget.onRemove(item.id);
                      } else {
                        await widget.onLog(reps, loadKg);
                      }
                    },
              icon: Icon(
                isComplete ? Icons.check_circle_rounded : Icons.check_rounded,
                color: isComplete
                    ? context.tioColors.success
                    : context.tioColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showDeferredAction(BuildContext context, String action) {
  return showTioInformationBottomSheet(
    context: context,
    title: '$action coming next',
    message:
        'This Active Workout screen is connected to the existing persisted session contract. $action persistence will be enabled after the approved workout-composition contract is added.',
    actionLabel: 'Got it',
    icon: Icons.info_outline_rounded,
  );
}

double _volumeKg(List<PerformedSet> sets) {
  var total = 0.0;
  for (final set in sets) {
    final load = set.loadKg;
    final reps = set.reps;
    if (load != null && reps != null) total += load * reps;
  }
  return total;
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _formatNullableNumber(double? value) =>
    value == null ? '-' : _formatNumber(value);

String _prescriptionSummary(SetPrescription prescription) {
  final reps = prescription.reps == null
      ? '-'
      : prescription.repsMax == null
          ? '${prescription.reps}'
          : '${prescription.reps}-${prescription.repsMax}';
  final load = prescription.loadKg == null
      ? '-'
      : '${_formatNumber(prescription.loadKg!)}kg';
  return '$load × $reps';
}

String _formatStartTime(BuildContext context, DateTime startedAtUtc) {
  final local = startedAtUtc.toLocal();
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
  );
  return '$date, $time';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
