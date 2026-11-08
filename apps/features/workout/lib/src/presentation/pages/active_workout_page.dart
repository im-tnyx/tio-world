import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/exercises/exercise_catalog_repository.dart';
import '../../domain/exercises/user_exercise_repository.dart';
import '../../domain/models/routine_composition_limits.dart';
import '../../domain/models/routine_rest_timer_preset.dart';
import '../../domain/repositories/routine_composition_repository.dart';
import '../../domain/exercises/exercise_catalog.dart';
import '../controllers/active_workout_controller.dart';
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

/// Focused Active Workout surface for resuming and recovering a persisted
/// session. App composition supplies the auth-bound controller; the feature
/// never reaches into Auth, Supabase or routing composition.
class ActiveWorkoutPage extends StatelessWidget {
  const ActiveWorkoutPage({
    required this.controller,
    super.key,
    this.onBack,
    this.showStartPreview = false,
    this.catalogRepository,
    this.userExerciseRepository,
    this.clock,
  });

  final ActiveWorkoutController? controller;
  final VoidCallback? onBack;

  /// Entry-only UI: never creates a session, exercise, or fake identity.
  final bool showStartPreview;

  /// Optional exercise catalog repository for preview exercise selection.
  final ExerciseCatalogRepository? catalogRepository;

  /// Optional user exercise repository for custom exercises.
  final UserExerciseRepository? userExerciseRepository;

  /// Optional clock for deterministic time formatting and testing.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return _ActiveWorkoutBody(
      controller: controller,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
      showStartPreview: showStartPreview,
      catalogRepository: catalogRepository,
      userExerciseRepository: userExerciseRepository,
      clock: clock,
    );
  }
}

class _ActiveWorkoutBody extends StatefulWidget {
  const _ActiveWorkoutBody({
    required this.controller,
    required this.onBack,
    required this.showStartPreview,
    this.catalogRepository,
    this.userExerciseRepository,
    this.clock,
  });

  final ActiveWorkoutController? controller;
  final VoidCallback onBack;
  final bool showStartPreview;
  final ExerciseCatalogRepository? catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  final DateTime Function()? clock;

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
      builder: (sheetContext) => WorkoutDurationBottomSheet(
        startedAtUtc: session.time.startedAtUtc,
        initialDuration: state.activeElapsedDuration,
        isPaused: state.status == ActiveWorkoutStatus.paused,
        isActionPending: state.isActionPending,
        onAction: () => Navigator.of(sheetContext).pop(true),
        clock: widget.clock,
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

    final session = state.session;
    final routineTitle = session?.snapshot.routineName ?? 'Workout';
    var totalVolumeKg = 0.0;
    for (final s in state.performedSets) {
      final w = s.loadKg;
      final r = s.reps;
      if (w != null && r != null) totalVolumeKg += w * r;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (routeContext) => SaveWorkoutPage(
          initialTitle: routineTitle,
          duration: state.activeElapsedDuration,
          volumeKg: totalVolumeKg,
          completedSets: state.performedSets.length,
          startedAt: session?.time.startedAtUtc.toLocal(),
          clock: widget.clock,
          onSave: ({
            required String title,
            required String? description,
            required DateTime date,
            required double? rpe,
            required String activityType,
            required String? gym,
            Duration? duration,
          }) async {
            Navigator.of(routeContext).pop(true);
          },
          onDiscard: () async {
            await controller.discardSession(reason: 'user_cancelled');
          },
        ),
      ),
    );

    if (!mounted ||
        saved != true ||
        !identical(controller, _controller) ||
        !_sessionActive.value) {
      return;
    }
    await controller.completeSession();
  }

  Future<void> _discard(ActiveWorkoutState state) async {
    final controller = _controller;
    if (controller == null || state.isActionPending || state.isTerminal) return;

    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      title: 'Discard workout?',
      message: 'This session and any logged sets will be discarded.',
      confirmLabel: 'Discard workout',
      cancelLabel: 'Keep working out',
      intent: TioConfirmationIntent.destructive,
      activeWhileOpen: _sessionActive,
    );
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
    switch (state.status) {
      case ActiveWorkoutStatus.initial:
      case ActiveWorkoutStatus.restoring:
        return const _LoadingState();
      case ActiveWorkoutStatus.noSession:
        if (widget.showStartPreview) {
          return _StartWorkoutPreview(
            onBack: widget.onBack,
            catalogRepository: widget.catalogRepository,
            userExerciseRepository: widget.userExerciseRepository,
            clock: widget.clock,
          );
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
        if (widget.showStartPreview) {
          return _StartWorkoutPreview(
            onBack: widget.onBack,
            catalogRepository: widget.catalogRepository,
            userExerciseRepository: widget.userExerciseRepository,
            clock: widget.clock,
          );
        }
        return const _MessageState(
          key: ValueKey('active-workout-reconciliation'),
          title: 'Workout needs to reconnect',
          message: 'We could not confirm the latest workout state.',
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
          onDiscard: state.isActionPending || state.isTerminal
              ? null
              : () => _discard(state),
          onBack: widget.onBack,
          catalogRepository: widget.catalogRepository,
          userExerciseRepository: widget.userExerciseRepository,
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

SetPrescription _withSetType(SetPrescription p, RoutineSetType type) =>
    SetPrescription(
      reps: p.reps,
      repsMax: p.repsMax,
      setType: type,
      loadKg: p.loadKg,
      distanceMeters: p.distanceMeters,
      durationSeconds: p.durationSeconds,
      restSeconds: p.restSeconds,
    );

class _StartWorkoutPreview extends StatefulWidget {
  const _StartWorkoutPreview({
    required this.onBack,
    this.catalogRepository,
    this.userExerciseRepository,
    this.clock,
  });

  final VoidCallback onBack;
  final ExerciseCatalogRepository? catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  final DateTime Function()? clock;

  @override
  State<_StartWorkoutPreview> createState() => _StartWorkoutPreviewState();
}

class _StartWorkoutPreviewState extends State<_StartWorkoutPreview> {
  final List<Exercise> _previewExercises = [];
  final Map<int, List<RoutineCompositionSet>> _previewExerciseSets = {};
  final Map<String, ({double? loadKg, int? reps})> _loggedSets = {};
  final Map<int, RoutineRestTimerPreset> _restPresets = {};
  final Map<int, List<ExerciseNoteDraftSnapshot>> _exerciseNotes = {};
  final Map<String, double?> _setRpes = {};

  late final DateTime _startedAtUtc;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  bool _isPaused = false;
  DateTime? _pausedAtUtc;
  Duration _totalPausedDuration = Duration.zero;

  DateTime _nowUtc() => (widget.clock?.call() ?? DateTime.now()).toUtc();

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isPaused) {
        setState(() {
          _elapsed = _nowUtc().difference(_startedAtUtc) - _totalPausedDuration;
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _isPaused = false;
        if (_pausedAtUtc != null) {
          _totalPausedDuration += _nowUtc().difference(_pausedAtUtc!);
          _pausedAtUtc = null;
        }
        _startTicker();
      } else {
        _isPaused = true;
        _pausedAtUtc = _nowUtc();
        _ticker?.cancel();
        _ticker = null;
      }
    });
  }

  Future<void> _showPauseDetails() async {
    final shouldToggle = await showModalBottomSheet<bool>(
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
    );

    if (!mounted || shouldToggle != true) return;
    _togglePause();
  }

  @override
  void initState() {
    super.initState();
    _startedAtUtc = _nowUtc();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }

  List<RoutineCompositionSet> _setsForExercise(int exerciseIndex) {
    return _previewExerciseSets.putIfAbsent(
      exerciseIndex,
      () => [
        RoutineCompositionSet(
          id: _syntheticUuid(exerciseIndex, 0),
          prescription: SetPrescription(setType: RoutineSetType.normal),
        ),
      ],
    );
  }

  void _addSet(int exerciseIndex) {
    final sets = _setsForExercise(exerciseIndex);
    if (sets.length >= RoutineCompositionLimits.maxSetsPerExercise) return;
    setState(() {
      final newIndex = sets.length;
      sets.add(
        RoutineCompositionSet(
          id: _syntheticUuid(exerciseIndex, newIndex),
          prescription: SetPrescription(setType: RoutineSetType.normal),
        ),
      );
    });
  }

  Future<void> _selectSetType(
    int exerciseIndex,
    int setIndex,
    RoutineCompositionSet set,
  ) async {
    final sets = _setsForExercise(exerciseIndex);
    final chosen = await showWorkoutSetTypeSheet(
      context: context,
      sets: sets,
      targetSet: set,
    );
    if (!mounted || chosen == null) return;
    setState(() {
      if (chosen is RoutineSetType) {
        final idx = sets.indexWhere((s) => s.id == set.id);
        if (idx != -1) {
          sets[idx] = RoutineCompositionSet(
            id: set.id,
            prescription: _withSetType(set.prescription, chosen),
          );
        }
      } else if (chosen == 'remove') {
        sets.removeWhere((s) => s.id == set.id);
        _loggedSets.remove('$exerciseIndex-$setIndex');
        _setRpes.remove('$exerciseIndex-$setIndex');
      }
    });
  }

  Future<void> _selectSetRpe(
    int exerciseIndex,
    int setIndex,
    RoutineCompositionSet set,
  ) async {
    final setId = '$exerciseIndex-$setIndex';
    final currentRpe = _setRpes[setId];
    final logged = _loggedSets[setId];
    final loadKg = logged?.loadKg ?? set.prescription.loadKg;
    final reps = logged?.reps ?? set.prescription.reps;

    final selected = await showWorkoutRpeSheet(
      context: context,
      setNumber: setIndex + 1,
      loadKg: loadKg,
      reps: reps,
      initialRpe: currentRpe,
    );

    if (!mounted || selected == null) return;
    setState(() {
      if (selected > 0) {
        _setRpes[setId] = selected;
      } else {
        _setRpes.remove(setId);
      }
    });
  }

  Future<void> _showExerciseOptions(int exerciseIndex) async {
    final action = await showRoutineExerciseOptionsSheet(context);
    if (!mounted || action == null) return;
    if (action == RoutineExerciseOption.remove) {
      setState(() {
        _previewExercises.removeAt(exerciseIndex);
        _previewExerciseSets.remove(exerciseIndex);
        _restPresets.remove(exerciseIndex);
        _exerciseNotes.remove(exerciseIndex);
        _loggedSets.removeWhere((k, _) => k.startsWith('$exerciseIndex-'));
        _setRpes.removeWhere((k, _) => k.startsWith('$exerciseIndex-'));
      });
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
        setState(() {
          _previewExercises[exerciseIndex] = selected.first;
          _loggedSets.removeWhere((k, _) => k.startsWith('$exerciseIndex-'));
          _setRpes.removeWhere((k, _) => k.startsWith('$exerciseIndex-'));
        });
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
      setState(() {
        _previewExercises.addAll(selected);
      });
    }
  }

  Future<void> _configureRestTimer(
    int index,
    String? exerciseName, {
    bool hasWarmUpSets = false,
    RoutineRestTimerPreset? current,
  }) async {
    final activePreset =
        current ?? _restPresets[index] ?? const RoutineRestTimerPreset();
    final result = await showRoutineRestTimerSheet(
      context: context,
      initialNormalRestSeconds: activePreset.normalRestSeconds,
      initialWarmUpRestSeconds: activePreset.warmUpRestSeconds,
      exerciseName: exerciseName,
      hasWarmUpSets: hasWarmUpSets,
    );
    if (result != null && mounted) {
      setState(() {
        _restPresets[index] = result;
      });
    }
  }

  Future<void> _navigateToSaveWorkout() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (routeContext) => SaveWorkoutPage(
          initialTitle: null,
          duration: _elapsed,
          volumeKg: _totalVolumeKg,
          completedSets: _loggedSets.length,
          startedAt: _startedAtUtc.toLocal(),
          clock: widget.clock,
          onSave: ({
            required String title,
            required String? description,
            required DateTime date,
            required double? rpe,
            required String activityType,
            required String? gym,
            Duration? duration,
          }) {
            Navigator.of(routeContext).pop(true);
          },
          onDiscard: () {
            _ticker?.cancel();
            _ticker = null;
            widget.onBack();
          },
        ),
      ),
    );

    if (result == true && mounted) {
      _ticker?.cancel();
      _ticker = null;
      widget.onBack();
    }
  }

  Future<void> _discard() async {
    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      title: 'Discard workout?',
      message: 'This session and any logged sets will be discarded.',
      confirmLabel: 'Discard workout',
      cancelLabel: 'Keep working out',
      intent: TioConfirmationIntent.destructive,
    );
    if (!mounted || confirmed != true) return;
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _previewExercises.clear();
      _previewExerciseSets.clear();
      _loggedSets.clear();
      _setRpes.clear();
      _restPresets.clear();
      _exerciseNotes.clear();
    });
    widget.onBack();
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
    final showRpe = MediaQuery.sizeOf(context).width >= 360;
    final canFinish = _loggedSets.isNotEmpty;
    final isComplete = _isWorkoutComplete;

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
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: TioPalette.white,
                          ),
                        )
                      : null,
                ),
                child: TioButton.primary(
                  key: const ValueKey('active-workout-preview-finish'),
                  label: 'Finish',
                  enabled: canFinish,
                  onPressed: canFinish
                      ? () => _navigateToSaveWorkout()
                      : null,
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
              padding: const EdgeInsets.only(top: TioSpacing.lg, bottom: TioSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
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
                padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.tioColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TioSpacing.xl),
            ] else ...[
              for (var i = 0; i < _previewExercises.length; i++) ...[
                _buildPreviewExerciseCard(i, _previewExercises[i], showRpe),
                const SizedBox(height: TioSpacing.lg),
              ],
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
              child: TioButton.primary(
                key: const ValueKey('active-workout-preview-add-exercise'),
                label: 'Add Exercise',
                leading: const Icon(Icons.add_rounded),
                onPressed: _addExercise,
                expand: true,
              ),
            ),
            const SizedBox(height: TioSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: TioButton.secondary(
                      key: const ValueKey('active-workout-preview-settings'),
                      label: 'Settings',
                      onPressed: () => _showDeferredAction(context, 'Settings'),
                    ),
                  ),
                  const SizedBox(width: TioSpacing.md),
                  Expanded(
                    child: TioButton.secondary(
                      key: const ValueKey('active-workout-preview-discard'),
                      label: 'Discard workout',
                      enabled: _previewExercises.isNotEmpty,
                      onPressed: _previewExercises.isNotEmpty ? _discard : null,
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
    );
  }

  Widget _buildPreviewExerciseCard(
    int exerciseIndex,
    Exercise exercise,
    bool showRpe,
  ) {
    final sets = _setsForExercise(exerciseIndex);
    final hasWarmUpSets =
        sets.any((s) => s.prescription.setType == RoutineSetType.warmUp);
    final restPreset = _restPresets[exerciseIndex] ??
        RoutineRestTimerPreset.fromPrescriptions(
          sets.map((s) => s.prescription),
        );

    final entry = RoutineCompositionEntry(
      id: _syntheticUuid(exerciseIndex),
      exercise: exercise.ref,
      sets: sets,
    );

    return WorkoutExerciseCard(
      key: ValueKey('active-workout-preview-exercise-$exerciseIndex'),
      mode: WorkoutExerciseCardMode.log,
      entry: entry,
      index: exerciseIndex,
      totalEntries: _previewExercises.length,
      title: exercise.displayName,
      thumbnailUrl: ExercisesController.thumbnailUrlFor(exercise),
      exerciseType: exercise.exerciseType,
      showRangeDraft: false,
      unit: WeightUnit.kg,
      enabled: true,
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
        final setId = '$exerciseIndex-$setIndex';
        final logged = _loggedSets[setId];
        final isLogged = logged != null;

        return WorkoutSetInputRow(
          key: ValueKey('preview-set-input-$exerciseIndex-$setIndex'),
          set: set,
          index: setIndex,
          normalNumber: setIndex + 1,
          unit: WeightUnit.kg,
          enabled: true,
          showPrevious: true,
          isExecution: true,
          isLogged: isLogged,
          showRpe: showRpe,
          performedLoadKg: logged?.loadKg,
          performedReps: logged?.reps,
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
          onToggleLogged: (reps, loadKg) async {
            setState(() {
              if (isLogged) {
                _loggedSets.remove(setId);
              } else {
                _loggedSets[setId] = (loadKg: loadKg, reps: reps);
              }
            });
          },
        );
      },
      addSet: () => _addSet(exerciseIndex),
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
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
  final Map<String, double?> _setRpes = {};
  final Map<int, List<RoutineCompositionSet>> _extraSessionSets = {};
  final Map<String, RoutineSetType> _sessionSetTypeOverrides = {};
  ExerciseCatalog? _catalog;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
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
      final extra = _extraSessionSets.putIfAbsent(occurrenceIndex, () => []);
      extra.add(
        RoutineCompositionSet(
          id: _syntheticUuid(occurrenceIndex, currentSetCount),
          prescription: SetPrescription(setType: RoutineSetType.normal),
        ),
      );
    });
  }

  Future<void> _showExerciseOptions(int occurrenceIndex) async {
    final action = await showRoutineExerciseOptionsSheet(context);
    if (!mounted || action == null) return;
    if (action == RoutineExerciseOption.remove) {
      unawaited(_showDeferredAction(context, 'Remove exercise from active session'));
    } else if (action == RoutineExerciseOption.replace) {
      unawaited(_showDeferredAction(context, 'Replace exercise in active session'));
    }
  }

  Future<void> _selectSetType(
    int occurrenceIndex,
    int setIndex,
    RoutineCompositionSet set,
    List<RoutineCompositionSet> sets,
  ) async {
    final chosen = await showWorkoutSetTypeSheet(
      context: context,
      sets: sets,
      targetSet: set,
    );
    if (!mounted || chosen == null) return;
    setState(() {
      if (chosen is RoutineSetType) {
        _sessionSetTypeOverrides['$occurrenceIndex-$setIndex'] = chosen;
      }
    });
  }

  Future<void> _selectSessionSetRpe(
    int occurrenceIndex,
    int setIndex,
    RoutineCompositionSet set,
    PerformedSet? performed,
  ) async {
    final setId = '$occurrenceIndex-$setIndex';
    final currentRpe = _setRpes[setId];
    final loadKg = performed?.loadKg ?? set.prescription.loadKg;
    final reps = performed?.reps ?? set.prescription.reps;

    final selected = await showWorkoutRpeSheet(
      context: context,
      setNumber: setIndex + 1,
      loadKg: loadKg,
      reps: reps,
      initialRpe: currentRpe,
    );

    if (!mounted || selected == null) return;
    setState(() {
      if (selected > 0) {
        _setRpes[setId] = selected;
      } else {
        _setRpes.remove(setId);
      }
    });
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
    final result = await showRoutineRestTimerSheet(
      context: context,
      initialNormalRestSeconds: activePreset.normalRestSeconds,
      initialWarmUpRestSeconds: activePreset.warmUpRestSeconds,
      exerciseName: exerciseName,
      hasWarmUpSets: hasWarmUpSets,
    );
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
                              backgroundColor: const Color(0xFF43A047),
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
              padding: const EdgeInsets.only(top: TioSpacing.xs, bottom: TioSpacing.lg),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
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
              padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
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
                child: Text('No exercises were captured for this session.'),
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
              padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
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
              padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
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
                padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
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
                padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        .map(
          (e) {
            final override = _sessionSetTypeOverrides[
                '${exercise.occurrenceIndex}-${e.key}'];
            return RoutineCompositionSet(
              id: _syntheticUuid(exercise.occurrenceIndex, e.key),
              prescription: override != null
                  ? _withSetType(e.value, override)
                  : e.value,
            );
          },
        )
        .toList();
    final extra =
        _extraSessionSets[exercise.occurrenceIndex] ?? const [];
    final sets = [...prescribed, ...extra];
    final hasWarmUpSets =
        sets.any((s) => s.prescription.setType == RoutineSetType.warmUp);
    final restPreset = _restPresets[exercise.occurrenceIndex] ??
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
          showPrevious: true,
          isExecution: true,
          isLogged: isComplete,
          showRpe: showRpe,
          performedLoadKg: performed?.loadKg,
          performedReps: performed?.reps,
          performedRpe: _setRpes['${exercise.occurrenceIndex}-$setIndex'],
          onRpePressed: () => _selectSessionSetRpe(
            exercise.occurrenceIndex,
            setIndex,
            set,
            performed,
          ),
          onTypePressed: () => _selectSetType(
            exercise.occurrenceIndex,
            setIndex,
            set,
            sets,
          ),
          rowKey: ValueKey('active-workout-set-$setIndex'),
          setNumberKey: ValueKey('active-workout-set-number-$setIndex'),
          loadKey: ValueKey('active-workout-load-$setIndex'),
          repsKey: ValueKey('active-workout-reps-$setIndex'),
          toggleKey: ValueKey('active-workout-set-toggle-$setIndex'),
          rpeKey: ValueKey('active-workout-rpe-$setIndex'),
          onToggleLogged: (reps, loadKg) async {
            if (isComplete) {
              await controller.removeSet(performed.id);
            } else {
              await controller.logSet(
                sessionExerciseIndex: exercise.occurrenceIndex,
                setIndex: setIndex,
                reps: reps,
                loadKg: loadKg,
              );
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
          duration: const Duration(milliseconds: 300),
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
