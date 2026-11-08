import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../controllers/active_workout_controller.dart';
import '../controllers/active_workout_state.dart';

/// Focused Active Workout surface for resuming and recovering a persisted
/// session. App composition supplies the auth-bound controller; the feature
/// never reaches into Auth, Supabase or routing composition.
class ActiveWorkoutPage extends StatelessWidget {
  const ActiveWorkoutPage({
    required this.controller,
    super.key,
    this.onBack,
  });

  final ActiveWorkoutController? controller;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return _ActiveWorkoutBody(
      controller: controller,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
    );
  }
}

class _ActiveWorkoutBody extends StatefulWidget {
  const _ActiveWorkoutBody({
    required this.controller,
    required this.onBack,
  });

  final ActiveWorkoutController? controller;
  final VoidCallback onBack;

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
      appBar: const TioAppBar(title: Text('Active Workout')),
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
          onPauseOrResume:
              state.isActionPending ? null : () => _pauseOrResume(state),
          onComplete: state.isActionPending || state.isTerminal
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
    required this.onPauseOrResume,
    required this.onComplete,
    required this.onBack,
  });

  final ActiveWorkoutState state;
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
                Text(
                  snapshot.routineName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: TioSpacing.sm),
                Text(statusLabel),
                const SizedBox(height: TioSpacing.xs),
                Text(_formatDuration(state.activeElapsedDuration)),
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.lg),
          if (snapshot.exercises.isEmpty)
            const TioCard(
              child: Text('No exercises were captured for this session.'),
            )
          else
            ...snapshot.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: TioSpacing.sm),
                child: TioCard(
                  key: ValueKey(
                    'active-workout-exercise-${exercise.occurrenceIndex}',
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: TioSpacing.sm),
                      Text('${exercise.prescribedSets.length} sets'),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: TioSpacing.sm),
          if (!state.isTerminal) ...[
            TioButton.secondary(
              key: const ValueKey('active-workout-pause-resume'),
              label: state.status == ActiveWorkoutStatus.active
                  ? 'Pause workout'
                  : 'Resume workout',
              onPressed: onPauseOrResume,
              loading: state.isActionPending,
              expand: true,
            ),
            const SizedBox(height: TioSpacing.sm),
            TioButton.primary(
              key: const ValueKey('active-workout-complete'),
              label: 'Finish workout',
              onPressed: onComplete,
              loading: state.isActionPending,
              expand: true,
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

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
