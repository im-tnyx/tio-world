import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../domain/exercises/exercise_catalog_repository.dart';
import '../../domain/exercises/user_exercise_repository.dart';
import '../../domain/models/routine_composition_limits.dart';
import '../../domain/models/active_workout_draft.dart';
import '../../domain/models/routine_rest_timer_preset.dart';
import '../../domain/repositories/gym_location_repository.dart';
import '../../domain/repositories/routine_composition_repository.dart';
import '../../domain/exercises/exercise_catalog.dart';
import '../controllers/active_workout_controller.dart';
import '../controllers/active_workout_draft_controller.dart';
import '../controllers/workout_runtime_settings_controller.dart';
import '../controllers/rest_timer_completion_gate.dart';
import '../controllers/active_workout_state.dart';
import '../library/exercises/exercises_controller.dart';
import '../library/exercises/exercises_page.dart';
import '../library/routines/routine_exercise_options_sheet.dart';
import '../library/routines/routine_notes_save_bridge.dart';
import '../library/routines/routine_rest_timer_sheet.dart';
import '../widgets/workout_exercise_card.dart';
import '../widgets/workout_rpe_sheet.dart';
import '../widgets/workout_set_input_row.dart';
import '../widgets/workout_set_type_sheet.dart';
import 'save_workout_page.dart';

Future<void> _vibrateAtRestCompletion() async {
  try {
    await HapticFeedback.vibrate();
  } catch (_) {
    // Haptics are optional; platform failures must never interrupt logging.
  }
}

/// Tracks temporary Workout-owned sheets without treating another full-screen
/// destination as the current Workout screen.
final class _WorkoutModalCounter {
  int depth = 0;
}

Future<T> _withWorkoutModal<T>(
  _WorkoutModalCounter counter,
  Future<T> Function() show,
) async {
  counter.depth++;
  try {
    return await show();
  } finally {
    counter.depth--;
  }
}

DateTime _wallDateTime(DateTime instantUtc, int offsetMinutes) {
  final wall = instantUtc.toUtc().add(Duration(minutes: offsetMinutes));
  return DateTime(wall.year, wall.month, wall.day, wall.hour, wall.minute);
}

DateTime _utcFromWallDateTime(DateTime wallDateTime, int offsetMinutes) =>
    DateTime.utc(
      wallDateTime.year,
      wallDateTime.month,
      wallDateTime.day,
      wallDateTime.hour,
      wallDateTime.minute,
    ).subtract(Duration(minutes: offsetMinutes));

/// Focused Active Workout surface for resuming and recovering a persisted
/// session. App composition supplies the auth-bound controller; the feature
/// never reaches into Auth, Supabase or routing composition.
class ActiveWorkoutPage extends StatelessWidget {
  const ActiveWorkoutPage({
    required this.controller,
    super.key,
    this.onBack,
    this.showStartPreview = false,
    this.createDraftIfMissing = true,
    this.catalogRepository,
    this.userExerciseRepository,
    this.gymLocationRepository,
    this.clock,
    this.draftController,
    this.workoutRuntimeSettingsController,
  });

  final ActiveWorkoutController? controller;
  final VoidCallback? onBack;

  /// Entry-only UI: never creates a session, exercise, or fake identity.
  final bool showStartPreview;

  /// When false, Play resume restores an existing local draft only and never
  /// starts a second ad-hoc workout while a legacy session is being resumed.
  final bool createDraftIfMissing;

  /// Optional exercise catalog repository for preview exercise selection.
  final ExerciseCatalogRepository? catalogRepository;

  /// Optional user exercise repository for custom exercises.
  final UserExerciseRepository? userExerciseRepository;
  final GymLocationRepository? gymLocationRepository;

  /// Optional clock for deterministic time formatting and testing.
  final DateTime Function()? clock;
  final ActiveWorkoutDraftController? draftController;
  final WorkoutRuntimeSettingsController? workoutRuntimeSettingsController;

  @override
  Widget build(BuildContext context) {
    return _ActiveWorkoutBody(
      controller: controller,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
      showStartPreview: showStartPreview,
      createDraftIfMissing: createDraftIfMissing,
      catalogRepository: catalogRepository,
      userExerciseRepository: userExerciseRepository,
      gymLocationRepository: gymLocationRepository,
      clock: clock,
      draftController: draftController,
      workoutRuntimeSettingsController: workoutRuntimeSettingsController,
    );
  }
}

class _ActiveWorkoutBody extends StatefulWidget {
  const _ActiveWorkoutBody({
    required this.controller,
    required this.onBack,
    required this.showStartPreview,
    required this.createDraftIfMissing,
    this.catalogRepository,
    this.userExerciseRepository,
    this.gymLocationRepository,
    this.clock,
    this.draftController,
    this.workoutRuntimeSettingsController,
  });

  final ActiveWorkoutController? controller;
  final VoidCallback onBack;
  final bool showStartPreview;
  final bool createDraftIfMissing;
  final ExerciseCatalogRepository? catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  final GymLocationRepository? gymLocationRepository;
  final DateTime Function()? clock;
  final ActiveWorkoutDraftController? draftController;
  final WorkoutRuntimeSettingsController? workoutRuntimeSettingsController;

  @override
  State<_ActiveWorkoutBody> createState() => _ActiveWorkoutBodyState();
}

class _ActiveWorkoutBodyState extends State<_ActiveWorkoutBody>
    with WidgetsBindingObserver {
  ActiveWorkoutController? _controller;
  final ValueNotifier<bool> _sessionActive = ValueNotifier<bool>(false);
  bool _draftChecked = false;
  final RestTimerCompletionGate _legacyRestGate = RestTimerCompletionGate();
  final _WorkoutModalCounter _workoutModalCounter = _WorkoutModalCounter();
  int _observedLegacyCompletionRevision = 0;
  String? _observedLegacyRestId;
  bool _vibrationForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vibrationForeground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _legacyRestGate.setForeground(_vibrationForeground);
    final settings = widget.workoutRuntimeSettingsController;
    if (settings != null) unawaited(settings.loadRestTimerVibration());
    unawaited(_restoreExistingDraft());
    _bindController(widget.controller);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _vibrationForeground = state == AppLifecycleState.resumed;
    _legacyRestGate.setForeground(_vibrationForeground);
    // Re-arm a still-positive online rest immediately on foreground return,
    // before its next ticker can observe/clear an expired rest.
    if (_vibrationForeground && _controller != null && mounted) {
      _observeLegacyRest(_controller!);
    }
    final draftController = widget.draftController;
    if (draftController == null) return;
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(draftController.markBackgrounded());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(draftController.restoreExisting());
    }
  }

  Future<void> _restoreExistingDraft() async {
    final controller = widget.draftController;
    if (controller == null) return;
    // tio-workspace style: Play starts local workout then opens Log Workout.
    // No recovery screen and no silent home-back on start.
    // Resume must not create a second draft while a legacy session restores.
    if (widget.showStartPreview && widget.createDraftIfMissing) {
      await controller.restoreOrStart();
    } else {
      await controller.restoreExisting();
    }
    if (mounted && identical(controller, widget.draftController)) {
      setState(() => _draftChecked = true);
    }
  }

  @override
  void didUpdateWidget(covariant _ActiveWorkoutBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.draftController, widget.draftController)) {
      _draftChecked = false;
      unawaited(_restoreExistingDraft());
    }
    if (!identical(oldWidget.controller, widget.controller)) {
      _bindController(widget.controller);
    }
    if (!identical(oldWidget.workoutRuntimeSettingsController,
        widget.workoutRuntimeSettingsController)) {
      final settings = widget.workoutRuntimeSettingsController;
      if (settings != null) unawaited(settings.loadRestTimerVibration());
    }
  }

  void _bindController(ActiveWorkoutController? next) {
    _sessionActive.value = false;
    _controller?.removeListener(_onControllerChanged);
    _controller?.stopDurationTicker();
    _controller = next;
    _legacyRestGate.observeRest(
      restId: null,
      remainingPositive: false,
      vibrationEnabled: false,
    );
    _observedLegacyRestId = null;
    _observedLegacyCompletionRevision =
        next?.restCompletionRevision ?? 0;
    next?.addListener(_onControllerChanged);
    _sessionActive.value = next != null;
    if (next != null) _observeLegacyRest(next);
    if (next != null) {
      Future<void>.microtask(next.restoreActiveSession);
    }
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    _sessionActive.value =
        controller.state.status != ActiveWorkoutStatus.authInvalidated;
    _observeLegacyRest(controller);
    _syncTicker(controller.state);
    setState(() {});
  }

  void _observeLegacyRest(ActiveWorkoutController controller) {
    final enabled = widget.workoutRuntimeSettingsController
            ?.restTimerVibrationEnabled ??
        false;
    final revision = controller.restCompletionRevision;
    if (revision != _observedLegacyCompletionRevision) {
      _observedLegacyCompletionRevision = revision;
      final id = _observedLegacyRestId;
      if (id != null &&
          _legacyRestGate.complete(id, vibrationEnabled: enabled) &&
          _vibrationForeground &&
          mounted &&
          // Local Save-only draft preview takes precedence over a restored
          // online session. Never buzz for the hidden legacy timer.
          !(widget.showStartPreview &&
              widget.draftController?.draft != null) &&
          ((ModalRoute.of(context)?.isCurrent ?? true) ||
              _workoutModalCounter.depth > 0)) {
        unawaited(_vibrateAtRestCompletion());
      }
    }
    final rest = controller.state.activeRestTimer;
    final restId = rest == null
        ? null
        : 'legacy:${controller.restStartRevision}';
    _observedLegacyRestId = restId;
    _legacyRestGate.observeRest(
      restId: restId,
      remainingPositive: rest != null &&
          rest.remainingDuration(
            (widget.clock?.call() ?? DateTime.now()).toUtc(),
          ) > Duration.zero,
      vibrationEnabled: enabled,
      preferenceReady:
          widget.workoutRuntimeSettingsController?.isVibrationReady ?? false,
    );
  }

  void _suppressRemovedRestFeedback(int exerciseIndex, int setIndex) {
    final rest = _controller?.state.activeRestTimer;
    if (rest != null &&
        rest.sessionExerciseIndex == exerciseIndex &&
        rest.setIndex == setIndex) {
      _legacyRestGate.suppressCurrentRest();
    }
  }

  void _syncTicker(ActiveWorkoutState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state.status == ActiveWorkoutStatus.active ||
        (state.status == ActiveWorkoutStatus.paused &&
            state.activeRestTimer != null)) {
      // Workout duration may be paused, but a current Rest countdown keeps
      // its UTC deadline until naturally complete or explicitly cancelled.
      controller.startDurationTicker();
    } else {
      controller.stopDurationTicker();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    final shouldToggle = await _withWorkoutModal(_workoutModalCounter, () => showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => WorkoutDurationBottomSheet(
        startedAtUtc: session.time.startedAtUtc,
        initialDuration: state.activeElapsedDuration,
        isPaused: state.status == ActiveWorkoutStatus.paused,
        isActionPending: state.isActionPending,
        onAction: () => Navigator.of(sheetContext).pop(true),
        clock: widget.clock,
      ),
    ));

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

    // Save review is not active training. Preserve the authoritative paused
    // duration on Back and let the user explicitly resume from Active Workout.
    if (state.status == ActiveWorkoutStatus.active) {
      final paused = await controller.pauseSession();
      if (!mounted || !identical(controller, _controller) || !paused) return;
    }
    final reviewState = controller.state;
    if (reviewState.status != ActiveWorkoutStatus.paused ||
        reviewState.isActionPending) {
      return;
    }

    final session = reviewState.session;
    var totalVolumeKg = 0.0;
    for (final s in reviewState.performedSets) {
      final w = s.loadKg;
      final r = s.reps;
      if (w != null && r != null) totalVolumeKg += w * r;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SaveWorkoutPage(
          initialTitle: session?.workoutTitle,
          duration: reviewState.activeElapsedDuration,
          volumeKg: totalVolumeKg,
          completedSets: reviewState.performedSets.length,
          startedAt: session?.time.startedAtUtc.toLocal(),
          initialWorkoutDateTime: session?.workoutAtUtc == null ||
                  session?.workoutUtcOffsetMinutes == null
              ? null
              : _wallDateTime(
                  session!.workoutAtUtc!,
                  session.workoutUtcOffsetMinutes!,
                ),
          initialWorkoutUtcOffsetMinutes: session?.workoutUtcOffsetMinutes,
          initialDescription: session?.notes,
          sessionMetadataOnly: true,
          gymLocationRepository: widget.gymLocationRepository,
          clock: widget.clock,
          onSave: ({
            required String title,
            required String? description,
            required DateTime date,
            required int utcOffsetMinutes,
            required double? rpe,
            required String activityType,
            required String? gym,
            Duration? duration,
          }) async {
            final workoutAtUtc = _utcFromWallDateTime(date, utcOffsetMinutes);
            bool matchesCompletedSave(WorkoutSession? persisted) =>
                persisted != null &&
                persisted.status == WorkoutSessionStatus.completed &&
                persisted.workoutTitle == title.trim() &&
                persisted.workoutAtUtc == workoutAtUtc &&
                persisted.workoutUtcOffsetMinutes == utcOffsetMinutes &&
                persisted.notes == description;

            if (controller.state.status ==
                ActiveWorkoutStatus.reconciliationRequired) {
              final reconciled = await controller.reconcileState();
              if (!reconciled) return false;
              final canonical = controller.state.session;
              if (matchesCompletedSave(canonical)) return true;
              if (!controller.state.isRunning) return false;
            }

            final saved = await controller.completeSession(
              notes: description,
              workoutTitle: title,
              workoutAtUtc: workoutAtUtc,
              workoutUtcOffsetMinutes: utcOffsetMinutes,
            );
            if (saved) return true;

            // Unknown outcomes are reconciled before retry. A matching canonical
            // completed row confirms success without issuing a duplicate write.
            if (controller.state.status ==
                ActiveWorkoutStatus.reconciliationRequired) {
              final reconciled = await controller.reconcileState();
              return reconciled &&
                  matchesCompletedSave(controller.state.session);
            }
            return false;
          },
          onDiscard: () => controller.discardSession(reason: 'user_cancelled'),
        ),
      ),
    );

    if (!mounted ||
        saved != true ||
        !identical(controller, _controller) ||
        !_sessionActive.value) {
      return;
    }
  }

  Future<void> _discard(ActiveWorkoutState state) async {
    final controller = _controller;
    if (controller == null || state.isActionPending || state.isTerminal) return;

    final confirmed = await _withWorkoutModal(_workoutModalCounter, () => showTioConfirmationBottomSheet(
      context: context,
      title: 'Discard workout?',
      message: 'This session and any logged sets will be discarded.',
      confirmLabel: 'Discard workout',
      cancelLabel: 'Keep working out',
      intent: TioConfirmationIntent.destructive,
      activeWhileOpen: _sessionActive,
    ));
    if (!mounted ||
        confirmed != true ||
        !identical(controller, _controller) ||
        !_sessionActive.value) {
      return;
    }
    await controller.discardSession(reason: 'user_cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final state = controller?.state;

    // Play with a local draft controller always targets Log Workout, even while
    // the online session controller is still restoring/reconciling.
    if (widget.showStartPreview &&
        widget.draftController != null &&
        (controller == null || state == null)) {
      if (!_draftChecked && widget.draftController!.draft == null) {
        return const Scaffold(body: SafeArea(child: _LoadingState()));
      }
      return Scaffold(
        body: SafeArea(child: _buildDraftPreview()),
      );
    }

    return Scaffold(
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
    final draftController = widget.draftController;
    // Owner / tio-workspace rule: Play → Log Workout only. No recovery UI.
    // Prefer an independent local draft (mini-bar / Save-only) over a legacy
    // online session. Without a local draft, never swallow canonical
    // reconciliation behind an empty preview.
    if (widget.showStartPreview && draftController != null) {
      final hasLocalDraft = draftController.draft != null;
      if (hasLocalDraft) {
        if (!_draftChecked && draftController.isBusy) {
          return const _LoadingState();
        }
        return _buildDraftPreview();
      }
      if (widget.createDraftIfMissing &&
          (state.status == ActiveWorkoutStatus.noSession ||
              state.status == ActiveWorkoutStatus.initial ||
              state.status == ActiveWorkoutStatus.restoring)) {
        if (!_draftChecked && draftController.isBusy) {
          return const _LoadingState();
        }
        return _buildDraftPreview();
      }
    }
    switch (state.status) {
      case ActiveWorkoutStatus.initial:
      case ActiveWorkoutStatus.restoring:
        return const _LoadingState();
      case ActiveWorkoutStatus.noSession:
        if (widget.showStartPreview) {
          return _buildDraftPreview();
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
          message: 'We could not confirm the latest workout state.',
          actionLabel: 'Retry',
          onAction: state.isActionPending
              ? null
              : () => unawaited(controller.reconcileState()),
          actionLoading: state.isActionPending,
          secondaryActionLabel: 'Back',
          onSecondaryAction: state.isActionPending ? null : widget.onBack,
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
          workoutModalCounter: _workoutModalCounter,
          onRestSourceRemoved: _suppressRemovedRestFeedback,
          onDurationPressed:
              state.isActionPending ? null : () => _showPauseDetails(state),
          onPauseOrResume:
              state.isActionPending ? null : () => _pauseOrResume(state),
          onComplete: state.isActionPending ||
                  state.isTerminal ||
                  state.performedSets.isEmpty
              ? null
              : () => _complete(state),
          onDiscard: state.isActionPending || state.isTerminal
              ? null
              : () => _discard(state),
          onBack: widget.onBack,
          catalogRepository: widget.catalogRepository,
          userExerciseRepository: widget.userExerciseRepository,
        );
    }
  }

  Widget _buildDraftPreview() => _StartWorkoutPreview(
        onBack: widget.onBack,
        createDraftIfMissing: widget.createDraftIfMissing,
        workoutModalCounter: _workoutModalCounter,
        catalogRepository: widget.catalogRepository,
        userExerciseRepository: widget.userExerciseRepository,
        gymLocationRepository: widget.gymLocationRepository,
        clock: widget.clock,
        draftController: widget.draftController,
        workoutRuntimeSettingsController:
            widget.workoutRuntimeSettingsController,
      );
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

class _StartWorkoutPreview extends StatefulWidget {
  const _StartWorkoutPreview({
    required this.onBack,
    required this.createDraftIfMissing,
    required this.workoutModalCounter,
    this.catalogRepository,
    this.userExerciseRepository,
    this.gymLocationRepository,
    this.clock,
    this.draftController,
    this.workoutRuntimeSettingsController,
  });

  final VoidCallback onBack;
  final bool createDraftIfMissing;
  final _WorkoutModalCounter workoutModalCounter;
  final ExerciseCatalogRepository? catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  final GymLocationRepository? gymLocationRepository;
  final DateTime Function()? clock;
  final ActiveWorkoutDraftController? draftController;
  final WorkoutRuntimeSettingsController? workoutRuntimeSettingsController;

  @override
  State<_StartWorkoutPreview> createState() => _StartWorkoutPreviewState();
}

class _StartWorkoutPreviewState extends State<_StartWorkoutPreview>
    with WidgetsBindingObserver {
  final Map<int, List<ExerciseNoteDraftSnapshot>> _exerciseNotes = {};
  Timer? _ticker;
  final RestTimerCompletionGate _draftRestGate = RestTimerCompletionGate();
  bool _vibrationForeground = true;

  void _observeDraftRest() {
    final rest = _draft?.activeRest;
    final enabled = widget.workoutRuntimeSettingsController
            ?.restTimerVibrationEnabled ??
        false;
    // The same Set rest retains its identity when the user adjusts +/-15s.
    // A new logged rest is observed after the intermediate null/clear state.
    final id =
        rest == null ? null : '${rest.exerciseId}:${rest.setId}';
    final remaining = rest?.remaining(_nowUtc()) ?? Duration.zero;
    _draftRestGate.observeRest(
      restId: id,
      remainingPositive: remaining > Duration.zero,
      vibrationEnabled: enabled,
      preferenceReady:
          widget.workoutRuntimeSettingsController?.isVibrationReady ?? false,
    );
    if (id != null &&
        remaining <= Duration.zero &&
        _draftRestGate.complete(id, vibrationEnabled: enabled) &&
        _vibrationForeground &&
        mounted &&
        ((ModalRoute.of(context)?.isCurrent ?? true) ||
            widget.workoutModalCounter.depth > 0)) {
      unawaited(_vibrateAtRestCompletion());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _vibrationForeground = state == AppLifecycleState.resumed;
    _draftRestGate.setForeground(_vibrationForeground);
    if (_vibrationForeground && mounted) _observeDraftRest();
  }

  ActiveWorkoutDraft? get _draft => widget.draftController?.draft;
  List<ActiveWorkoutDraftExercise> get _previewExercises =>
      _draft?.exercises ?? const [];
  List<RoutineCompositionSet> _setsForExercise(int index) => [
        for (final set in _previewExercises[index].sets)
          RoutineCompositionSet(id: set.id, prescription: set.prescription),
      ];
  Map<String,
          ({double? loadKg, int? reps, int? durationSeconds, double? distanceMeters})>
      get _loggedSets => {
            for (final exercise in _previewExercises)
              for (final set in exercise.sets)
                if (set.loggedAtUtc != null)
                  set.id: (
                    loadKg: set.loadKg,
                    reps: set.reps,
                    durationSeconds: set.durationSeconds,
                    distanceMeters: set.distanceMeters,
                  ),
          };
  Map<String, double?> get _setRpes => {
        for (final exercise in _previewExercises)
          for (final set in exercise.sets)
            if (set.rpe != null) set.id: set.rpe,
      };
  bool get _isPaused => _draft?.time.isPaused ?? false;
  DateTime get _startedAtUtc => _draft?.time.startedAtUtc ?? _nowUtc();
  Duration get _elapsed {
    final draft = _draft;
    if (draft == null) return Duration.zero;
    try {
      return draft.time.elapsedActiveDuration(_nowUtc());
    } on ArgumentError {
      // Device clock rollback must not crash the running UI.
      return draft.time.elapsedActiveDuration(draft.time.lastTransitionAtUtc);
    } on StateError {
      return Duration.zero;
    }
  }

  DateTime _nowUtc() => (widget.clock?.call() ?? DateTime.now()).toUtc();

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _observeDraftRest();
      final restActive =
          (_draft?.activeRest?.remaining(_nowUtc()) ?? Duration.zero) >
              Duration.zero;
      if (_isPaused && !restActive) {
        _ticker?.cancel();
        _ticker = null;
      }
      setState(() {});
    });
  }

  void _ensureTicker() {
    if (_draft != null &&
        (!_isPaused ||
            (_draft?.activeRest?.remaining(_nowUtc()) ?? Duration.zero) >
                Duration.zero) &&
        _ticker == null) {
      _startTicker();
    }
  }

  Future<void> _togglePause() async {
    final controller = widget.draftController;
    if (controller == null) return;
    if (_isPaused) {
      if (await controller.resume()) _startTicker();
    } else {
      if (await controller.pause() &&
          (_draft?.activeRest?.remaining(_nowUtc()) ?? Duration.zero) <=
              Duration.zero) {
        _ticker?.cancel();
        _ticker = null;
      }
    }
  }

  Future<void> _showPauseDetails() async {
    final shouldToggle = await _withWorkoutModal(widget.workoutModalCounter, () => showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => WorkoutDurationBottomSheet(
        startedAtUtc: _startedAtUtc,
        initialDuration: _elapsed,
        isPaused: _isPaused,
        onAction: () => Navigator.of(sheetContext).pop(true),
        clock: widget.clock,
      ),
    ));

    if (!mounted || shouldToggle != true) return;
    await _togglePause();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vibrationForeground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _draftRestGate.setForeground(_vibrationForeground);
    final settings = widget.workoutRuntimeSettingsController;
    if (settings != null) unawaited(settings.loadRestTimerVibration());
    widget.draftController?.addListener(_onDraftChanged);
    _observeDraftRest();
    _ensureDraftOrTicker();
  }

  void _onDraftChanged() {
    if (!mounted) return;
    _observeDraftRest();
    if (_draft == null) {
      _ticker?.cancel();
      _ticker = null;
    } else {
      _ensureTicker();
    }
    setState(() {});
  }

  void _ensureDraftOrTicker() {
    final controller = widget.draftController;
    if (controller != null &&
        controller.draft == null &&
        widget.createDraftIfMissing) {
      unawaited(controller.restoreOrStart());
      return;
    }
    _ensureTicker();
  }

  @override
  void didUpdateWidget(covariant _StartWorkoutPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.draftController, widget.draftController) ||
        oldWidget.createDraftIfMissing != widget.createDraftIfMissing) {
      oldWidget.draftController?.removeListener(_onDraftChanged);
      widget.draftController?.addListener(_onDraftChanged);
      _draftRestGate.observeRest(
        restId: null,
        remainingPositive: false,
        vibrationEnabled: false,
      );
      _observeDraftRest();
      _ensureDraftOrTicker();
    }
    if (!identical(oldWidget.workoutRuntimeSettingsController,
        widget.workoutRuntimeSettingsController)) {
      final settings = widget.workoutRuntimeSettingsController;
      if (settings != null) unawaited(settings.loadRestTimerVibration());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.draftController?.removeListener(_onDraftChanged);
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  Future<void> _addSet(int exerciseIndex) async {
    final controller = widget.draftController;
    if (controller == null || exerciseIndex >= _previewExercises.length) return;
    await controller.addSet(_previewExercises[exerciseIndex].id);
  }

  Future<void> _selectSetType(
    int exerciseIndex,
    int setIndex,
    RoutineCompositionSet set,
  ) async {
    final sets = _setsForExercise(exerciseIndex);
    final chosen = await _withWorkoutModal(widget.workoutModalCounter, () => showWorkoutSetTypeSheet(
      context: context,
      sets: sets,
      targetSet: set,
    ));
    if (!mounted || chosen == null) return;
    final controller = widget.draftController;
    if (controller == null || exerciseIndex >= _previewExercises.length) return;
    final exerciseId = _previewExercises[exerciseIndex].id;
    if (chosen is RoutineSetType) {
      await controller.setType(exerciseId, set.id, chosen);
    } else if (chosen == 'remove') {
      final beforeCount = controller.draft?.exercises.length ?? 0;
      final removed = await controller.removeSet(exerciseId, set.id);
      if (!mounted || !removed) return;
      final afterCount = controller.draft?.exercises.length ?? 0;
      // Last-set removal drops the exercise; keep note drafts aligned by index.
      if (afterCount < beforeCount) {
        setState(() => _reindexMapAfterRemoval(_exerciseNotes, exerciseIndex));
      }
    }
  }

  Future<void> _selectSetRpe(
    int exerciseIndex,
    int setIndex,
    RoutineCompositionSet set,
  ) async {
    final setId = set.id;
    final currentRpe = _setRpes[setId];
    final logged = _loggedSets[setId];
    final loadKg = logged?.loadKg ?? set.prescription.loadKg;
    final reps = logged?.reps ?? set.prescription.reps;

    final selected = await _withWorkoutModal(widget.workoutModalCounter, () => showWorkoutRpeSheet(
      context: context,
      setNumber: setIndex + 1,
      loadKg: loadKg,
      reps: reps,
      initialRpe: currentRpe,
    ));

    if (!mounted || selected == null) return;
    if (exerciseIndex >= _previewExercises.length) return;
    await widget.draftController?.setRpe(
      _previewExercises[exerciseIndex].id,
      setId,
      selected > 0 ? selected : null,
    );
  }

  Future<void> _showExerciseOptions(int exerciseIndex) async {
    final action = await _withWorkoutModal(widget.workoutModalCounter, () => showRoutineExerciseOptionsSheet(context));
    if (!mounted || action == null) return;
    final controller = widget.draftController;
    if (controller == null || exerciseIndex >= _previewExercises.length) return;
    final exerciseId = _previewExercises[exerciseIndex].id;
    if (action == RoutineExerciseOption.remove) {
      if (await controller.removeExercise(exerciseId)) {
        setState(() => _reindexMapAfterRemoval(_exerciseNotes, exerciseIndex));
      }
    } else if (action == RoutineExerciseOption.replace) {
      final repo = widget.catalogRepository;
      if (repo == null) return;
      final selected = await Navigator.of(context).push<List<Exercise>>(
        MaterialPageRoute<List<Exercise>>(
          builder: (routeContext) => ProviderScope(
            child: ExercisesPage(
              catalogRepository: repo,
              userExerciseRepository: widget.userExerciseRepository,
              onExercisesAdded: (chosen) =>
                  Navigator.of(routeContext).pop<List<Exercise>>(chosen),
            ),
          ),
        ),
      );
      if (selected != null && selected.isNotEmpty && mounted) {
        if (await controller.replaceExercise(exerciseId, selected.first)) {
          setState(() => _exerciseNotes.remove(exerciseIndex));
        }
      }
    }
  }

  Future<void> _addExercise() async {
    final repo = widget.catalogRepository;
    if (repo == null) {
      unawaited(_showDeferredAction(context, 'Add Exercise'));
      return;
    }
    final selected = await Navigator.of(context).push<List<Exercise>>(
      MaterialPageRoute<List<Exercise>>(
        builder: (routeContext) => ProviderScope(
          child: ExercisesPage(
            catalogRepository: repo,
            userExerciseRepository: widget.userExerciseRepository,
            onExercisesAdded: (selected) =>
                Navigator.of(routeContext).pop<List<Exercise>>(selected),
          ),
        ),
      ),
    );
    if (selected != null && selected.isNotEmpty && mounted) {
      final settings = widget.workoutRuntimeSettingsController;
      if (settings != null) {
        await settings.load();
        if (!mounted || !settings.isReady) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not load Default Rest Timer.')),
            );
          }
          return;
        }
      }
      await widget.draftController?.addExercises(
        selected,
        initialRestPreset: settings?.defaultRestPreset ??
            const RoutineRestTimerPreset(),
      );
    }
  }

  Future<void> _configureRestTimer(
    int index,
    String? exerciseName, {
    bool hasWarmUpSets = false,
    RoutineRestTimerPreset? current,
  }) async {
    if (index >= _previewExercises.length) return;
    final activePreset = current ?? _previewExercises[index].restPreset;
    final result = await _withWorkoutModal(widget.workoutModalCounter, () => showRoutineRestTimerSheet(
      context: context,
      initialNormalRestSeconds: activePreset.normalRestSeconds,
      initialWarmUpRestSeconds: activePreset.warmUpRestSeconds,
      exerciseName: exerciseName,
      hasWarmUpSets: hasWarmUpSets,
    ));
    if (result != null && mounted && index < _previewExercises.length) {
      await widget.draftController?.setRestPreset(
        _previewExercises[index].id,
        result,
      );
    }
  }

  void _reindexMapAfterRemoval<T>(Map<int, T> values, int removedIndex) {
    final shifted = <int, T>{};
    for (final entry in values.entries) {
      if (entry.key == removedIndex) continue;
      shifted[entry.key > removedIndex ? entry.key - 1 : entry.key] =
          entry.value;
    }
    values
      ..clear()
      ..addAll(shifted);
  }

  Future<void> _discard() async {
    final confirmed = await _withWorkoutModal(widget.workoutModalCounter, () => showTioConfirmationBottomSheet(
      context: context,
      title: 'Discard workout?',
      message: 'This session and any logged sets will be discarded.',
      confirmLabel: 'Discard workout',
      cancelLabel: 'Keep working out',
      intent: TioConfirmationIntent.destructive,
    ));
    if (!mounted || confirmed != true) return;
    if (await widget.draftController?.discard() == true) {
      _ticker?.cancel();
      _ticker = null;
      _exerciseNotes.clear();
      widget.onBack();
    }
  }

  double get _totalVolumeKg {
    var volume = 0.0;
    for (final logged in _loggedSets.values) {
      final load = logged.loadKg;
      final reps = logged.reps;
      if (load != null && reps != null) volume += load * reps;
    }
    return volume;
  }

  Future<void> _openSaveReview() async {
    final controller = widget.draftController;
    if (controller == null || controller.isBusy || _loggedSets.isEmpty) return;
    if (!_isPaused && !await controller.pause()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout could not be paused.')),
        );
      }
      return;
    }
    if (!mounted) return;
    final draft = controller.draft;
    if (draft == null || !draft.time.isPaused) return;
    final reviewDuration = draft.selectedDurationSeconds == null
        ? _elapsed
        : Duration(seconds: draft.selectedDurationSeconds!);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SaveWorkoutPage(
          initialTitle: draft.workoutTitle,
          initialDescription: draft.description,
          duration: reviewDuration,
          volumeKg: _totalVolumeKg,
          completedSets: _loggedSets.length,
          startedAt: draft.time.startedAtUtc.toLocal(),
          initialWorkoutDateTime: draft.workoutAtUtc == null ||
                  draft.workoutUtcOffsetMinutes == null
              ? null
              : _wallDateTime(
                  draft.workoutAtUtc!,
                  draft.workoutUtcOffsetMinutes!,
                ),
          initialWorkoutUtcOffsetMinutes: draft.workoutUtcOffsetMinutes,
          initialRpe: draft.overallRpe,
          initialActivityType: draft.activityType,
          initialGym: draft.gymName,
          gymLocationRepository: widget.gymLocationRepository,
          clock: widget.clock,
          onSave: ({
            required String title,
            required String? description,
            required DateTime date,
            required int utcOffsetMinutes,
            required double? rpe,
            required String activityType,
            required String? gym,
            Duration? duration,
          }) =>
              controller.save(resolvedTitle: title),
          onLeaveDraft: ({
            required String title,
            required String? description,
            required DateTime date,
            required int utcOffsetMinutes,
            required double? rpe,
            required String activityType,
            required String? gym,
            required Duration duration,
          }) =>
              controller.updateSaveMetadata(
            title: title,
            description: description,
            workoutAtUtc: _utcFromWallDateTime(date, utcOffsetMinutes),
            workoutUtcOffsetMinutes: utcOffsetMinutes,
            selectedDurationSeconds: duration == reviewDuration
                ? draft.selectedDurationSeconds
                : duration.inSeconds,
            gymName: gym,
            activityType: activityType,
            overallRpe: rpe,
          ),
          onDiscard: controller.discard,
        ),
      ),
    );
    if (!mounted) return;
    if (controller.draft == null && (saved == true || saved == false)) {
      widget.onBack();
    }
  }

  int get _totalPlannedSets {
    var count = 0;
    for (var i = 0; i < _previewExercises.length; i++) {
      count += _setsForExercise(i).length;
    }
    return count;
  }

  double get _workoutProgress {
    final total = _totalPlannedSets;
    if (total == 0) return 0.0;
    return (_loggedSets.length / total).clamp(0.0, 1.0);
  }

  bool get _isWorkoutComplete =>
      _totalPlannedSets > 0 && _loggedSets.length >= _totalPlannedSets;

  @override
  Widget build(BuildContext context) {
    final draftController = widget.draftController;
    if (draftController == null) {
      return const _LoadingState();
    }
    if (_draft == null && draftController.isBusy) {
      return const _LoadingState();
    }
    if (_draft == null) {
      // Discarded / awaiting start — no recovery screen and no spinner that
      // would block test settle; parent already navigates Back on discard.
      return const SizedBox.shrink();
    }
    final showRpe = MediaQuery.sizeOf(context).width >= 360;
    final canFinish = _loggedSets.isNotEmpty;
    final isComplete = _isWorkoutComplete;
    final rest = _draft?.activeRest;
    final restRemaining = rest?.remaining(_nowUtc()) ?? Duration.zero;

    return Scaffold(
      appBar: TioAppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: widget.onBack,
        ),
        title: const Text('Log Workout'),
        actions: [
          IconButton(
            key: const ValueKey('active-workout-preview-timer'),
            icon: Icon(
              Icons.timer_outlined,
              color: _isPaused ? context.tioColors.textSecondary : null,
            ),
            onPressed: _showPauseDetails,
          ),
          Padding(
            padding: const EdgeInsets.only(right: TioSpacing.md),
            child: SizedBox(
              height: TioSize.dp34,
              child: Theme(
                data: Theme.of(context).copyWith(
                  filledButtonTheme: isComplete
                      ? FilledButtonThemeData(
                          style: FilledButton.styleFrom(
                            backgroundColor: context.tioColors.success,
                            foregroundColor: TioPalette.white,
                          ),
                        )
                      : null,
                ),
                child: TioButton.primary(
                  key: const ValueKey('active-workout-preview-finish'),
                  label: 'Finish',
                  enabled: canFinish,
                  onPressed: canFinish ? _openSaveReview : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkoutProgressBar(progress: _workoutProgress),
          Expanded(
            child: SingleChildScrollView(
              key: const ValueKey('active-workout-start-preview'),
              padding: const EdgeInsets.only(
                  top: TioSpacing.lg, bottom: TioSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                    child: _WorkoutStats(
                      duration: _elapsed,
                      volumeKg: _totalVolumeKg,
                      completedSets: _loggedSets.length,
                      onDurationPressed: _showPauseDetails,
                      isPaused: _isPaused,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.lg),
                  if (_previewExercises.isEmpty) ...[
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get started',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: TioSpacing.sm),
                          Text(
                            'Add an exercise to start your workout',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: context.tioColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TioSpacing.xl),
                  ] else ...[
                    for (var i = 0; i < _previewExercises.length; i++) ...[
                      _buildPreviewExerciseCard(
                          i, _previewExercises[i], showRpe),
                      const SizedBox(height: TioSpacing.lg),
                    ],
                  ],
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                    child: TioButton.primary(
                      key:
                          const ValueKey('active-workout-preview-add-exercise'),
                      label: 'Add Exercise',
                      leading: const Icon(Icons.add_rounded),
                      onPressed: _addExercise,
                      expand: true,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.md),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: TioButton.secondary(
                            key: const ValueKey(
                                'active-workout-preview-settings'),
                            label: 'Settings',
                            onPressed: () =>
                                _showDeferredAction(context, 'Settings'),
                          ),
                        ),
                        const SizedBox(width: TioSpacing.md),
                        Expanded(
                          child: TioButton.secondary(
                            key: const ValueKey(
                                'active-workout-preview-discard'),
                            label: 'Discard workout',
                            enabled: _draft != null,
                            onPressed: _draft != null ? _discard : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: rest != null && restRemaining > Duration.zero
          ? _DraftRestCountdown(
              remaining: restRemaining,
              totalSeconds: rest.totalDurationSeconds,
              onSubtract: () => unawaited(draftController.adjustRest(-15)),
              onAdd: () => unawaited(draftController.adjustRest(15)),
              onSkip: () => unawaited(draftController.skipRest()),
            )
          : null,
    );
  }

  Widget _buildPreviewExerciseCard(
    int exerciseIndex,
    ActiveWorkoutDraftExercise exercise,
    bool showRpe,
  ) {
    final sets = _setsForExercise(exerciseIndex);
    final hasWarmUpSets =
        sets.any((s) => s.prescription.setType == RoutineSetType.warmUp);
    final restPreset = exercise.hasRestOverride
        ? exercise.restPreset
        : RoutineRestTimerPreset.fromPrescriptions(
            sets.map((s) => s.prescription),
          );

    final entry = RoutineCompositionEntry(
      id: exercise.id,
      exercise: exercise.exerciseRef,
      sets: sets,
    );

    return WorkoutExerciseCard(
      key: ValueKey('active-workout-preview-exercise-$exerciseIndex'),
      mode: WorkoutExerciseCardMode.log,
      entry: entry,
      index: exerciseIndex,
      totalEntries: _previewExercises.length,
      title: exercise.displayName,
      thumbnailUrl: exercise.thumbnailUrl,
      exerciseType: exercise.exerciseType,
      showRangeDraft: false,
      unit: WeightUnit.kg,
      enabled: !(widget.draftController?.isBusy ?? false),
      showRpe: showRpe,
      keyPrefix: 'active-workout-preview-exercise',
      moveUp: () {},
      moveDown: () {},
      showOptions: () => _showExerciseOptions(exerciseIndex),
      selectRepetitionMode: () {},
      restPreset: restPreset,
      onConfigureRestTimer: () => _configureRestTimer(
        exerciseIndex,
        exercise.displayName,
        hasWarmUpSets: hasWarmUpSets,
        current: restPreset,
      ),
      initialNoteDrafts: _exerciseNotes[exerciseIndex] ?? const [],
      onNoteDraftsChanged: (drafts) {
        setState(() {
          _exerciseNotes[exerciseIndex] = drafts;
        });
      },
      buildSetRow: (set, setIndex) {
        final setId = set.id;
        final logged = _loggedSets[setId];
        final isLogged = logged != null;

        return WorkoutSetInputRow(
          key: ValueKey('preview-set-input-${set.id}'),
          set: set,
          index: setIndex,
          normalNumber: setIndex + 1,
          unit: WeightUnit.kg,
          enabled: !(widget.draftController?.isBusy ?? false),
          exerciseType: _previewExercises[exerciseIndex].exerciseType,
          showPrevious: true,
          isExecution: true,
          isLogged: isLogged,
          showRpe: showRpe,
          performedLoadKg: logged?.loadKg,
          performedReps: logged?.reps,
          performedDurationSeconds: logged?.durationSeconds,
          performedDistanceMeters: logged?.distanceMeters,
          performedRpe: _setRpes[setId],
          onRpePressed: () => _selectSetRpe(exerciseIndex, setIndex, set),
          onTypePressed: () => _selectSetType(exerciseIndex, setIndex, set),
          rowKey: ValueKey(
            'active-workout-preview-row-$exerciseIndex-$setIndex',
          ),
          setNumberKey: ValueKey(
            'active-workout-preview-set-number-$exerciseIndex-$setIndex',
          ),
          loadKey: ValueKey(
            'active-workout-preview-load-$exerciseIndex-$setIndex',
          ),
          repsKey: ValueKey(
            'active-workout-preview-reps-$exerciseIndex-$setIndex',
          ),
          toggleKey: ValueKey(
            'active-workout-preview-set-toggle-$exerciseIndex-$setIndex',
          ),
          rpeKey: ValueKey(
            'active-workout-preview-rpe-$exerciseIndex-$setIndex',
          ),
          onToggleLogged: (
              {reps, loadKg, durationSeconds, distanceMeters}) async {
            await widget.draftController?.toggleLogged(
              exercise.id,
              setId,
              loadKg: loadKg,
              reps: reps,
              durationSeconds: durationSeconds,
              distanceMeters: distanceMeters,
            );
          },
        );
      },
      addSet: () => _addSet(exerciseIndex),
    );
  }
}

class _DraftRestCountdown extends StatelessWidget {
  const _DraftRestCountdown({
    required this.remaining,
    required this.totalSeconds,
    required this.onSubtract,
    required this.onAdd,
    required this.onSkip,
  });

  final Duration remaining;
  final int totalSeconds;
  final VoidCallback onSubtract;
  final VoidCallback onAdd;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final seconds = (remaining.inMilliseconds + 999) ~/ 1000;
    final minutesLabel = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsLabel = (seconds % 60).toString().padLeft(2, '0');
    return Material(
      key: const ValueKey('active-workout-draft-rest-countdown'),
      color: context.tioColors.surfaceVariant,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: (remaining.inMilliseconds / (totalSeconds * 1000))
                  .clamp(0.0, 1.0),
              color: context.tioColors.primary,
              backgroundColor: context.tioColors.surface,
            ),
            Padding(
              padding: const EdgeInsets.all(TioSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TioButton.supporting(
                      key: const ValueKey('active-workout-rest-minus-15'),
                      label: '-15',
                      onPressed: onSubtract,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.xs),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '$minutesLabel:$secondsLabel',
                      key: const ValueKey('active-workout-rest-remaining'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.xs),
                  Expanded(
                    child: TioButton.supporting(
                      key: const ValueKey('active-workout-rest-plus-15'),
                      label: '+15',
                      onPressed: onAdd,
                      expand: true,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.xs),
                  Expanded(
                    child: TioButton.primary(
                      key: const ValueKey('active-workout-rest-skip'),
                      label: 'Skip',
                      onPressed: onSkip,
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
    this.actionLabel,
    this.onAction,
    this.actionLoading = false,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionLoading;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

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
              if (actionLabel case final label?) ...[
                const SizedBox(height: TioSpacing.lg),
                TioButton.primary(
                  key: ValueKey('active-workout-$label'),
                  label: label,
                  onPressed: onAction,
                  loading: actionLoading,
                  expand: true,
                ),
              ],
              if (secondaryActionLabel case final label?) ...[
                const SizedBox(height: TioSpacing.sm),
                TioButton.secondary(
                  key: ValueKey('active-workout-$label'),
                  label: label,
                  onPressed: onSecondaryAction,
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

class _SessionState extends StatefulWidget {
  const _SessionState({
    required this.state,
    required this.controller,
    required this.workoutModalCounter,
    required this.onRestSourceRemoved,
    required this.onDurationPressed,
    required this.onPauseOrResume,
    required this.onComplete,
    required this.onDiscard,
    required this.onBack,
    this.catalogRepository,
    this.userExerciseRepository,
  });

  final ActiveWorkoutState state;
  final ActiveWorkoutController controller;
  final _WorkoutModalCounter workoutModalCounter;
  final void Function(int exerciseIndex, int setIndex) onRestSourceRemoved;
  final VoidCallback? onDurationPressed;
  final VoidCallback? onPauseOrResume;
  final VoidCallback? onComplete;
  final VoidCallback? onDiscard;
  final VoidCallback onBack;
  final ExerciseCatalogRepository? catalogRepository;
  final UserExerciseRepository? userExerciseRepository;

  @override
  State<_SessionState> createState() => _SessionStateState();
}

class _SessionStateState extends State<_SessionState> {
  final Map<int, RoutineRestTimerPreset> _restPresets = {};
  final Map<int, List<ExerciseNoteDraftSnapshot>> _exerciseNotes = {};
  final Map<int, Map<int, RoutineCompositionSet>> _extraSessionSets = {};
  ExerciseCatalog? _catalog;

  @override
  void initState() {
    super.initState();
    _retainPersistedAdditionalSets(widget.state);
    _loadCatalog();
  }

  @override
  void didUpdateWidget(covariant _SessionState oldWidget) {
    super.didUpdateWidget(oldWidget);
    _retainPersistedAdditionalSets(widget.state);
  }

  void _retainPersistedAdditionalSets(ActiveWorkoutState state) {
    final session = state.session;
    if (session == null) return;
    for (final performed in state.performedSets) {
      final occurrenceIndex = performed.sessionExerciseIndex;
      if (occurrenceIndex >= session.snapshot.exercises.length) continue;
      final occurrence = session.snapshot.exercises[occurrenceIndex];
      if (performed.setIndex < occurrence.prescribedSets.length) {
        continue;
      }
      _extraSessionSets
          .putIfAbsent(occurrence.occurrenceIndex, () => {})
          .putIfAbsent(
            performed.setIndex,
            () => RoutineCompositionSet(
              id: _syntheticUuid(
                occurrence.occurrenceIndex,
                performed.setIndex,
              ),
              prescription: SetPrescription(setType: RoutineSetType.normal),
            ),
          );
    }
  }

  Future<void> _loadCatalog() async {
    final repo = widget.catalogRepository;
    if (repo == null) return;
    try {
      final catalog = await repo.load();
      if (mounted) setState(() => _catalog = catalog);
    } catch (_) {}
  }

  Uri? _thumbnailFor(ExerciseRef ref) {
    final ex = _catalog?.byRef(ref);
    return ex != null ? ExercisesController.thumbnailUrlFor(ex) : null;
  }

  void _addSet(int occurrenceIndex, int currentSetCount) {
    if (currentSetCount >= RoutineCompositionLimits.maxSetsPerExercise) return;
    setState(() {
      final extra = _extraSessionSets.putIfAbsent(occurrenceIndex, () => {});
      var newIndex = currentSetCount;
      while (extra.containsKey(newIndex)) {
        newIndex++;
      }
      extra[newIndex] = RoutineCompositionSet(
        id: const Uuid().v4(),
        prescription: SetPrescription(setType: RoutineSetType.normal),
      );
    });
  }

  Future<void> _showExerciseOptions(int occurrenceIndex) async {
    final action = await _withWorkoutModal(widget.workoutModalCounter, () => showRoutineExerciseOptionsSheet(context));
    if (!mounted || action == null) return;
    if (action == RoutineExerciseOption.remove) {
      unawaited(
          _showDeferredAction(context, 'Remove exercise from active session'));
    } else if (action == RoutineExerciseOption.replace) {
      unawaited(
          _showDeferredAction(context, 'Replace exercise in active session'));
    }
  }

  PerformedSet? _performedFor(
    List<PerformedSet> performedSets,
    int occurrenceIndex,
    int setIndex,
  ) {
    for (final item in performedSets) {
      if (item.sessionExerciseIndex == occurrenceIndex &&
          item.setIndex == setIndex) {
        return item;
      }
    }
    return null;
  }

  Future<void> _configureRestTimer(
    int index,
    String? exerciseName, {
    bool hasWarmUpSets = false,
    RoutineRestTimerPreset? current,
  }) async {
    final activePreset =
        current ?? _restPresets[index] ?? const RoutineRestTimerPreset();
    final result = await _withWorkoutModal(widget.workoutModalCounter, () => showRoutineRestTimerSheet(
      context: context,
      initialNormalRestSeconds: activePreset.normalRestSeconds,
      initialWarmUpRestSeconds: activePreset.warmUpRestSeconds,
      exerciseName: exerciseName,
      hasWarmUpSets: hasWarmUpSets,
    ));
    if (result != null && mounted) {
      setState(() {
        _restPresets[index] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = widget.controller;
    final session = state.session!;
    final snapshot = session.snapshot;
    final showRpe = MediaQuery.sizeOf(context).width >= 360;

    final statusLabel = switch (state.status) {
      ActiveWorkoutStatus.active => 'In progress',
      ActiveWorkoutStatus.paused => 'Paused',
      ActiveWorkoutStatus.completed => 'Completed',
      ActiveWorkoutStatus.discarded => 'Discarded',
      _ => 'Unavailable',
    };

    final isPaused = state.status == ActiveWorkoutStatus.paused;
    final totalPlannedSets = snapshot.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.prescribedSets.length,
    );
    final workoutProgress = totalPlannedSets == 0
        ? 0.0
        : (state.performedSets.length / totalPlannedSets).clamp(0.0, 1.0);
    final isComplete =
        totalPlannedSets > 0 && state.performedSets.length >= totalPlannedSets;

    return Scaffold(
      appBar: TioAppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: widget.onBack,
        ),
        title: const Text('Log Workout'),
        actions: [
          if (!state.isTerminal) ...[
            IconButton(
              key: const ValueKey('active-workout-timer'),
              icon: Icon(
                Icons.timer_outlined,
                color: isPaused ? context.tioColors.textSecondary : null,
              ),
              onPressed: widget.onDurationPressed,
            ),
            Padding(
              padding: const EdgeInsets.only(right: TioSpacing.md),
              child: SizedBox(
                height: TioSize.dp34,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    filledButtonTheme: isComplete
                        ? FilledButtonThemeData(
                            style: FilledButton.styleFrom(
                              backgroundColor: context.tioColors.success,
                              foregroundColor: TioPalette.white,
                            ),
                          )
                        : null,
                  ),
                  child: TioButton.primary(
                    key: const ValueKey('active-workout-complete'),
                    label: 'Finish',
                    enabled: widget.onComplete != null,
                    onPressed: widget.onComplete,
                    loading: state.isActionPending,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkoutProgressBar(progress: workoutProgress),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                  top: TioSpacing.xs, bottom: TioSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                    child: Row(
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
                  ),
                  const SizedBox(height: TioSpacing.xs),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                    child: _WorkoutStats(
                      duration: state.activeElapsedDuration,
                      volumeKg: _volumeKg(state.performedSets),
                      completedSets: state.performedSets.length,
                      onDurationPressed: widget.onDurationPressed,
                      isPaused: isPaused,
                    ),
                  ),
                  if (state.errorMessage case final message?) ...[
                    const SizedBox(height: TioSpacing.xs),
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
                  const SizedBox(height: TioSpacing.sm),
                  if (snapshot.exercises.isEmpty)
                    const TioCard(
                      child:
                          Text('No exercises were captured for this session.'),
                    )
                  else
                    for (var i = 0; i < snapshot.exercises.length; i++) ...[
                      _buildExerciseCard(
                        i,
                        snapshot.exercises[i],
                        state,
                        controller,
                        showRpe,
                      ),
                      const SizedBox(height: TioSpacing.sm),
                    ],
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                    child: TioButton.supporting(
                      key: const ValueKey('active-workout-add-set'),
                      label: 'Add Set',
                      leading: const Icon(Icons.add_rounded),
                      enabled: !state.isTerminal && !state.isActionPending,
                      onPressed: state.isTerminal || state.isActionPending
                          ? null
                          : () => _showDeferredAction(context, 'Add Set'),
                      expand: true,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.sm),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                    child: TioButton.primary(
                      key: const ValueKey('active-workout-add-exercise'),
                      label: 'Add Exercise',
                      leading: const Icon(Icons.add_rounded),
                      enabled: !state.isTerminal && !state.isActionPending,
                      onPressed: state.isTerminal || state.isActionPending
                          ? null
                          : () => _showDeferredAction(context, 'Add Exercise'),
                      expand: true,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.sm),
                  if (!state.isTerminal) ...[
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                      child: TioButton.secondary(
                        key: const ValueKey('active-workout-pause-resume'),
                        label: state.status == ActiveWorkoutStatus.active
                            ? 'Pause workout'
                            : 'Resume workout',
                        enabled: widget.onPauseOrResume != null,
                        onPressed: widget.onPauseOrResume,
                        loading: state.isActionPending,
                        expand: true,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.sm),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: TioButton.secondary(
                              key: const ValueKey('active-workout-settings'),
                              label: 'Settings',
                              onPressed: () =>
                                  _showDeferredAction(context, 'Settings'),
                            ),
                          ),
                          const SizedBox(width: TioSpacing.md),
                          Expanded(
                            child: TioButton.secondary(
                              key: const ValueKey('active-workout-discard'),
                              label: 'Discard workout',
                              enabled: widget.onDiscard != null,
                              onPressed: widget.onDiscard,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.performedSets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: TioSpacing.xs),
                        child: Text(
                          'Log at least one set before finishing this workout.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.tioColors.textSecondary,
                                  ),
                        ),
                      ),
                  ] else ...[
                    TioButton.secondary(
                      label: 'Back to Workout',
                      onPressed: widget.onBack,
                      expand: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    int exerciseIndex,
    SessionExerciseSnapshot exercise,
    ActiveWorkoutState state,
    ActiveWorkoutController controller,
    bool showRpe,
  ) {
    final prescribed = exercise.prescribedSets
        .asMap()
        .entries
        .map((e) => RoutineCompositionSet(
              id: _syntheticUuid(exercise.occurrenceIndex, e.key),
              prescription: e.value,
            ))
        .toList();
    final extra = _extraSessionSets[exercise.occurrenceIndex] ?? const {};
    final maxPerformedIndex = state.performedSets
        .where((set) => set.sessionExerciseIndex == exercise.occurrenceIndex)
        .fold<int>(
            -1,
            (maxIndex, set) =>
                set.setIndex > maxIndex ? set.setIndex : maxIndex);
    final maxExtraIndex = extra.keys.fold<int>(
      -1,
      (maxIndex, setIndex) => setIndex > maxIndex ? setIndex : maxIndex,
    );
    final lastSetIndex = <int>[
      prescribed.length - 1,
      maxPerformedIndex,
      maxExtraIndex,
    ].reduce((a, b) => a > b ? a : b);
    final sets = List<RoutineCompositionSet>.generate(
      lastSetIndex + 1,
      (setIndex) => setIndex < prescribed.length
          ? prescribed[setIndex]
          : extra[setIndex] ??
              RoutineCompositionSet(
                id: _syntheticUuid(exercise.occurrenceIndex, setIndex),
                prescription: SetPrescription(setType: RoutineSetType.normal),
              ),
    );
    final hasWarmUpSets =
        sets.any((s) => s.prescription.setType == RoutineSetType.warmUp);
    final exerciseRestOverride = _restPresets[exercise.occurrenceIndex];
    final restPreset = exerciseRestOverride ??
        RoutineRestTimerPreset.fromPrescriptions(
          sets.map((s) => s.prescription),
        );

    final entry = RoutineCompositionEntry(
      id: _syntheticUuid(exercise.occurrenceIndex),
      exercise: exercise.exerciseRef,
      sets: sets,
    );

    return WorkoutExerciseCard(
      key: ValueKey('active-workout-exercise-${exercise.occurrenceIndex}'),
      mode: WorkoutExerciseCardMode.log,
      entry: entry,
      index: exerciseIndex,
      totalEntries: state.session!.snapshot.exercises.length,
      title: exercise.displayName,
      thumbnailUrl: _thumbnailFor(exercise.exerciseRef),
      exerciseType: exercise.exerciseType,
      showRangeDraft: false,
      unit: WeightUnit.kg,
      enabled: !state.isTerminal && !state.isActionPending,
      showRpe: showRpe,
      keyPrefix: 'active-workout-exercise',
      moveUp: () {},
      moveDown: () {},
      showOptions: () => _showExerciseOptions(exercise.occurrenceIndex),
      selectRepetitionMode: () {},
      restPreset: restPreset,
      onConfigureRestTimer: () => _configureRestTimer(
        exercise.occurrenceIndex,
        exercise.displayName,
        hasWarmUpSets: hasWarmUpSets,
        current: restPreset,
      ),
      initialNoteDrafts: _exerciseNotes[exercise.occurrenceIndex] ?? const [],
      onNoteDraftsChanged: (drafts) {
        setState(() {
          _exerciseNotes[exercise.occurrenceIndex] = drafts;
        });
      },
      buildSetRow: (set, setIndex) {
        final performed = _performedFor(
          state.performedSets,
          exercise.occurrenceIndex,
          setIndex,
        );
        final isComplete = performed != null;

        return WorkoutSetInputRow(
          key: ValueKey('session-set-input-$exerciseIndex-$setIndex'),
          set: set,
          index: setIndex,
          normalNumber: setIndex + 1,
          unit: WeightUnit.kg,
          enabled: !state.isTerminal && !state.isActionPending,
          exerciseType: exercise.exerciseType,
          showPrevious: true,
          isExecution: true,
          isLogged: isComplete,
          showRpe: showRpe,
          performedLoadKg: performed?.loadKg,
          performedReps: performed?.reps,
          performedDurationSeconds: performed?.durationSeconds,
          performedDistanceMeters: performed?.distanceMeters,
          performedRpe: null,
          // Set type is part of the immutable start snapshot. This session
          // contract does not persist performed RPE/type overrides.
          onRpePressed: null,
          onTypePressed: null,
          rowKey: ValueKey('active-workout-set-$setIndex'),
          setNumberKey: ValueKey('active-workout-set-number-$setIndex'),
          loadKey: ValueKey('active-workout-load-$setIndex'),
          repsKey: ValueKey('active-workout-reps-$setIndex'),
          toggleKey: ValueKey('active-workout-set-toggle-$setIndex'),
          rpeKey: ValueKey('active-workout-rpe-$setIndex'),
          onToggleLogged: (
              {reps, loadKg, durationSeconds, distanceMeters}) async {
            if (isComplete) {
              final removed = await controller.removeSet(performed.id);
              if (removed) {
                widget.onRestSourceRemoved(exercise.occurrenceIndex, setIndex);
              }
            } else {
              final logged = await controller.logSet(
                sessionExerciseIndex: exercise.occurrenceIndex,
                setIndex: setIndex,
                reps: reps,
                loadKg: loadKg,
                durationSeconds: durationSeconds,
                distanceMeters: distanceMeters,
              );
              if (logged) {
                final restSeconds = exerciseRestOverride == null
                    ? set.prescription.restSeconds
                    : exerciseRestOverride.effectiveRestFor(
                        set.prescription.setType,
                      );
                if (restSeconds == null) {
                  controller.cancelRestTimer();
                } else {
                  controller.startRestTimer(
                    durationSeconds: restSeconds,
                    sessionExerciseIndex: exercise.occurrenceIndex,
                    setIndex: setIndex,
                  );
                }
              }
            }
          },
        );
      },
      addSet: () => _addSet(exercise.occurrenceIndex, sets.length),
    );
  }
}

class _WorkoutProgressBar extends StatelessWidget {
  const _WorkoutProgressBar({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final clamped = progress.clamp(0.0, 1.0);

    return Semantics(
      label: 'Workout progress',
      value: '${(clamped * 100).round()}%',
      child: Container(
        key: const ValueKey('active-workout-progress-bar'),
        height: 3.0,
        width: double.infinity,
        color: colors.surfaceVariant,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: TioDuration.ms310),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: clamped),
          builder: (context, value, _) {
            return FractionallySizedBox(
              widthFactor: value,
              heightFactor: 1.0,
              child: Container(
                color: colors.primary,
              ),
            );
          },
        ),
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
    this.isPaused = false,
  });

  final Duration duration;
  final double volumeKg;
  final int completedSets;
  final VoidCallback? onDurationPressed;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final durationContent = _WorkoutStat(
      label: 'Duration',
      value: _formatDuration(duration),
      valueColor: isPaused
          ? context.tioColors.textSecondary
          : context.tioColors.primary,
    );
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: onDurationPressed != null,
            label: isPaused
                ? 'Workout duration paused'
                : 'Workout duration and pause controls',
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

class WorkoutDurationBottomSheet extends StatefulWidget {
  const WorkoutDurationBottomSheet({
    required this.startedAtUtc,
    required this.initialDuration,
    required this.isPaused,
    required this.onAction,
    this.clock,
    this.isActionPending = false,
    this.actionKey,
    super.key,
  });

  final DateTime startedAtUtc;
  final Duration initialDuration;
  final bool isPaused;
  final VoidCallback onAction;
  final DateTime Function()? clock;
  final bool isActionPending;
  final Key? actionKey;

  @override
  State<WorkoutDurationBottomSheet> createState() =>
      _WorkoutDurationBottomSheetState();
}

class _WorkoutDurationBottomSheetState
    extends State<WorkoutDurationBottomSheet> {
  late Duration _currentDuration;
  late final DateTime _openedAtUtc;
  Timer? _ticker;

  DateTime _nowUtc() => (widget.clock?.call() ?? DateTime.now()).toUtc();

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.initialDuration;
    _openedAtUtc = _nowUtc();
    if (!widget.isPaused) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !widget.isPaused) {
          setState(() {
            _currentDuration =
                widget.initialDuration + _nowUtc().difference(_openedAtUtc);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: TioSpacing.lg),
            _PauseDetailRow(
              label: 'Duration',
              value: _formatDuration(_currentDuration),
              valueColor: widget.isPaused
                  ? context.tioColors.textSecondary
                  : context.tioColors.primary,
            ),
            const SizedBox(height: TioSpacing.sm),
            _PauseDetailRow(
              label: 'Start time',
              value: _formatStartTime(context, widget.startedAtUtc),
            ),
            const SizedBox(height: TioSpacing.lg),
            TioButton.primary(
              key: widget.actionKey ??
                  const ValueKey('active-workout-pause-sheet-action'),
              label: widget.isPaused
                  ? 'Resume Workout Timer'
                  : 'Pause Workout Timer',
              leading: Icon(
                widget.isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
              ),
              onPressed: widget.isActionPending ? null : widget.onAction,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseDetailRow extends StatelessWidget {
  const _PauseDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: valueColor ?? context.tioColors.primary,
              ),
        ),
      ],
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

String _formatStartTime(BuildContext context, DateTime startedAtUtc) {
  final local = startedAtUtc.toLocal();
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
  );
  return '$date, $time';
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
    return '${hours}h ${minutes}min ${seconds}s';
  }
  return '${minutes}min ${seconds}s';
}

String _syntheticUuid(int exerciseIndex, [int? setIndex]) {
  final exHex = exerciseIndex.toRadixString(16).padLeft(4, '0');
  final setHex = (setIndex ?? 0).toRadixString(16).padLeft(12, '0');
  return '00000000-0000-4000-$exHex-$setHex';
}
