import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/calendar_preferences_providers.dart';
import 'package:tio_app/app/composition/workout_providers.dart';
import 'package:tio_app/app/routing/shell/workout_home_branch.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final class _Store implements ActiveWorkoutDraftStore {
  ActiveWorkoutDraft? saved;

  @override
  Future<ActiveWorkoutDraft?> load() async => saved;

  @override
  Future<void> save(ActiveWorkoutDraft draft) async => saved = draft;

  @override
  Future<void> delete() async => saved = null;
}

String _id(int n) =>
    '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';

ActiveWorkoutDraft _draft() => ActiveWorkoutDraft(
      id: _id(1),
      ownerId: _id(2),
      saveRequestId: _id(3),
      time: WorkoutTime.start(startedAtUtc: DateTime.utc(2026, 11, 10, 8)),
      exercises: [
        ActiveWorkoutDraftExercise(
          id: _id(4),
          exerciseRef: ExerciseRef.catalog('ex_a'),
          displayName: 'Bench Press',
          sets: [
            ActiveWorkoutDraftSet(
              id: _id(5),
              prescription: SetPrescription(reps: 8),
            ),
          ],
        ),
      ],
    );

final _controllersReadyProvider = StateProvider<bool>((ref) => false);

void main() {
  testWidgets('backgrounded Workout home pauses a local draft after two hours',
      (tester) async {
    var now = DateTime.utc(2026, 11, 10, 8);
    final store = _Store()..saved = _draft();
    late ActiveWorkoutDraftController controller;
    final container = ProviderContainer(
      overrides: [
        resolvedFirstDayOfWeekProvider.overrideWithValue(DateTime.monday),
        activeWorkoutDraftStoreProvider.overrideWithValue(store),
        activeWorkoutControllerProvider.overrideWith((ref) => null),
        activeWorkoutDraftControllerProvider.overrideWith((ref) {
          controller = ActiveWorkoutDraftController(
            store: store,
            ownerId: _id(2),
            clock: () => now,
          );
          ref.onDispose(controller.dispose);
          return controller;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: WorkoutHomeBranch()),
      ),
    ));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(store.saved!.backgroundedAtUtc, now);
    now = now.add(const Duration(days: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(controller.draft!.time.isPaused, isTrue);
    expect(store.saved!.time.pausedAtUtc,
        DateTime.utc(2026, 11, 10, 10));
  });

  testWidgets(
      'cold-start auth settle restores durable draft into the mini pill',
      (tester) async {
    final store = _Store()..saved = _draft();
    final container = ProviderContainer(
      overrides: [
        resolvedFirstDayOfWeekProvider.overrideWithValue(DateTime.monday),
        activeWorkoutDraftStoreProvider.overrideWithValue(store),
        activeWorkoutControllerProvider.overrideWith((ref) => null),
        activeWorkoutDraftControllerProvider.overrideWith((ref) {
          if (!ref.watch(_controllersReadyProvider)) return null;
          final controller = ActiveWorkoutDraftController(
            store: store,
            ownerId: _id(2),
            newUuid: () => _id(40),
          );
          ref.onDispose(controller.dispose);
          return controller;
        }),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: WorkoutHomeBranch()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-workout-mini-bar')), findsNothing);
    expect(find.byKey(const ValueKey('workout-home-play-action')), findsOneWidget);

    // Simulate auth/session providers becoming ready after cold start.
    container.read(_controllersReadyProvider.notifier).state = true;
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-workout-mini-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('workout-home-play-action')), findsNothing);
    expect(find.text('Bench Press'), findsOneWidget);
  });
}
