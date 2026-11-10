import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

import '../../calendar_preferences.dart';
import '../../network_providers.dart';

/// Workout tab composition: keeps Play controllers alive, restores an in-progress
/// workout after relaunch, and shows the tio-workspace-style mini bar when Log
/// Workout is not on screen.
class WorkoutHomeBranch extends ConsumerStatefulWidget {
  const WorkoutHomeBranch({super.key});

  @override
  ConsumerState<WorkoutHomeBranch> createState() => _WorkoutHomeBranchState();
}

class _WorkoutHomeBranchState extends ConsumerState<WorkoutHomeBranch>
    with WidgetsBindingObserver {
  Timer? _ticker;
  var _restoreGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_restoreInProgressWorkout());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_restoreInProgressWorkout());
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(ref.read(activeWorkoutDraftControllerProvider)
          ?.markBackgrounded());
    }
  }

  Future<void> _restoreInProgressWorkout() async {
    final generation = ++_restoreGeneration;
    final draftController = ref.read(activeWorkoutDraftControllerProvider);
    final sessionController = ref.read(activeWorkoutControllerProvider);
    // Auth/session providers can still be null on the first frame after cold
    // start. A later listen re-runs this once durable controllers exist.
    if (draftController == null && sessionController == null) return;
    await draftController?.restoreExisting();
    await sessionController?.restoreActiveSession();
    if (!mounted || generation != _restoreGeneration) return;
    setState(() {});
    _syncTicker();
  }

  void _syncTicker({
    ActiveWorkoutDraftController? draftController,
    ActiveWorkoutController? sessionController,
  }) {
    final draft = draftController ??
        ref.read(activeWorkoutDraftControllerProvider);
    final session = sessionController ??
        ref.read(activeWorkoutControllerProvider);
    final active = _hasInProgress(draft: draft, session: session);
    final paused = _isPaused(draft: draft, session: session);
    final shouldTick = active && !paused;
    if (shouldTick) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        // Legacy sessions stop their own duration ticker when Log Workout
        // disposes; keep the cached elapsed value advancing on Workout home.
        final liveSession = ref.read(activeWorkoutControllerProvider);
        if (liveSession != null &&
            liveSession.state.isRunning &&
            ref.read(activeWorkoutDraftControllerProvider)?.draft == null) {
          liveSession.updateElapsedDuration();
        }
        setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  bool _hasInProgress({
    ActiveWorkoutDraftController? draft,
    ActiveWorkoutController? session,
  }) =>
      draft?.draft != null || session?.state.isRunning == true;

  bool _isPaused({
    ActiveWorkoutDraftController? draft,
    ActiveWorkoutController? session,
  }) {
    final local = draft?.draft;
    if (local != null) return local.time.isPaused;
    return session?.state.isPaused == true;
  }

  Duration _elapsed({
    required ActiveWorkoutDraftController? draft,
    required ActiveWorkoutController? session,
  }) {
    final local = draft?.draft;
    if (local != null) {
      try {
        return local.time.elapsedActiveDuration(DateTime.timestamp());
      } on ArgumentError {
        // Device clock rollback must not crash Workout home / mini bar.
        return local.time.elapsedActiveDuration(local.time.lastTransitionAtUtc);
      } on StateError {
        return Duration.zero;
      }
    }
    return session?.state.activeElapsedDuration ?? Duration.zero;
  }

  String _subtitle({
    required ActiveWorkoutDraftController? draft,
    required ActiveWorkoutController? session,
  }) {
    final local = draft?.draft;
    if (local != null) {
      if (local.exercises.isEmpty) return 'Empty Workout';
      return local.exercises.last.displayName;
    }
    final exercises = session?.state.session?.snapshot.exercises;
    if (exercises == null || exercises.isEmpty) return 'Workout in progress';
    return exercises.last.displayName;
  }

  void _openResume(BuildContext context) {
    context.push('${AppRoutes.workoutActive.path}?preview=1&resume=1');
  }

  Future<void> _discardInProgress({
    required BuildContext context,
    required ActiveWorkoutDraftController? draftController,
    required ActiveWorkoutDraftStore? draftStore,
    required ActiveWorkoutController? sessionController,
  }) async {
    final confirmed = await showTioConfirmationBottomSheet(
      context: context,
      title: 'Discard workout?',
      message:
          'This permanently deletes your in-progress workout and logged sets.',
      confirmLabel: 'Discard workout',
      cancelLabel: 'Cancel',
      intent: TioConfirmationIntent.destructive,
      cardKey: const ValueKey('active-workout-mini-bar-discard-sheet'),
    );
    if (confirmed != true || !context.mounted) return;

    // Fail closed: clear memory+store first. Never discard a legacy session
    // while a local draft may still be present or resurrectable.
    if (draftController != null) {
      final cleared = await draftController.discardForReplacement();
      if (!cleared || draftController.draft != null) return;
    } else if (draftStore != null) {
      try {
        await draftStore.delete();
      } catch (_) {
        return;
      }
    }

    if (draftStore != null) {
      try {
        if (await draftStore.load() != null) return;
      } catch (_) {
        return;
      }
    }

    if (sessionController != null) {
      if (sessionController.state.status == ActiveWorkoutStatus.initial ||
          sessionController.state.status == ActiveWorkoutStatus.restoring) {
        await sessionController.restoreActiveSession();
      }
      if (sessionController.state.isRunning) {
        final discarded = await sessionController.discardSession(
          reason: 'user_cancelled',
        );
        if (!discarded && sessionController.state.isRunning) return;
      }
    }
    if (mounted) {
      setState(() {});
      _syncTicker(
        draftController: draftController,
        sessionController: sessionController,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftController = ref.watch(activeWorkoutDraftControllerProvider);
    final draftStore = ref.watch(activeWorkoutDraftStoreProvider);
    final sessionController = ref.watch(activeWorkoutControllerProvider);

    // Cold start / auth settle / save-repo rebuild can replace autoDispose
    // controllers after the first post-frame restore. Re-load the durable
    // draft into the new instance so the mini pill appears before Play.
    ref.listen<ActiveWorkoutDraftController?>(
      activeWorkoutDraftControllerProvider,
      (previous, next) {
        if (next == null || identical(previous, next)) return;
        unawaited(_restoreInProgressWorkout());
      },
    );
    ref.listen<ActiveWorkoutController?>(
      activeWorkoutControllerProvider,
      (previous, next) {
        if (next == null || identical(previous, next)) return;
        unawaited(_restoreInProgressWorkout());
      },
    );

    final listenables = <Listenable>[
      if (draftController != null) draftController,
      if (sessionController != null) sessionController,
    ];

    Widget home({required Widget? miniBar}) => WorkoutHomePage(
          resolvedFirstDayOfWeek: ref.watch(resolvedFirstDayOfWeekProvider),
          onLibraryPressed: () => context.push(AppRoutes.workoutLibrary.path),
          activeWorkoutMiniBar: miniBar,
          onPlayPressed: () {
            unawaited(
              runWorkoutPlayStart(
                context: context,
                draftController: draftController,
                draftStore: draftStore,
                sessionController: sessionController,
                openActive: ({required bool resumeExisting}) {
                  final query = resumeExisting
                      ? '?preview=1&resume=1'
                      : '?preview=1';
                  context.push('${AppRoutes.workoutActive.path}$query');
                },
              ),
            );
          },
        );

    if (listenables.isEmpty) {
      return home(miniBar: null);
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncTicker(
            draftController: draftController,
            sessionController: sessionController,
          );
        });
        final inProgress = _hasInProgress(
          draft: draftController,
          session: sessionController,
        );
        final miniBar = !inProgress
            ? null
            : ActiveWorkoutMiniBar(
                duration: _elapsed(
                  draft: draftController,
                  session: sessionController,
                ),
                subtitle: _subtitle(
                  draft: draftController,
                  session: sessionController,
                ),
                isPaused: _isPaused(
                  draft: draftController,
                  session: sessionController,
                ),
                onResume: () => _openResume(context),
                onDiscard: () {
                  unawaited(
                    _discardInProgress(
                      context: context,
                      draftController: draftController,
                      draftStore: draftStore,
                      sessionController: sessionController,
                    ),
                  );
                },
              );
        return home(miniBar: miniBar);
      },
    );
  }
}
