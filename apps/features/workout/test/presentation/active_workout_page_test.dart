import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';
import 'package:tio_feature_workout/src/presentation/widgets/workout_exercise_card.dart';

const _userId = '11111111-1111-4111-a111-111111111111';
final _sessionId = WorkoutSessionId('22222222-2222-4222-a222-222222222222');
final _programId = ProgramId('33333333-3333-4333-a333-333333333333');
final _routineId = RoutineId('44444444-4444-4444-a444-444444444444');
final _exerciseRef = ExerciseRef.catalog('ex_barbell_bench_press');

final class _FakeSessionRepository implements WorkoutSessionRepository {
  WorkoutSessionRecord? active;
  Exception? restoreError;
  Completer<WorkoutSessionRecord?>? activeSessionCompleter;
  Exception? pauseError;
  Completer<WorkoutSessionRecord>? pauseCompleter;
  WorkoutSessionRecord? completeResult;
  WorkoutSessionRecord? discardResult;
  PerformedSet? lastLoggedSet;
  var getActiveCalls = 0;

  @override
  Future<WorkoutSessionRecord?> getActiveSession() async {
    getActiveCalls++;
    final error = restoreError;
    if (error != null) throw error;
    final pending = activeSessionCompleter;
    if (pending != null) return pending.future;
    return active;
  }

  @override
  Future<WorkoutSessionRecord?> getSession(WorkoutSessionId sessionId) async =>
      active;

  @override
  Future<WorkoutSessionRecord> startSession(WorkoutSession session) async =>
      active ??= WorkoutSessionRecord(session: session, revision: 1);

  @override
  Future<WorkoutSessionRecord> pauseSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime pausedAtUtc,
  }) async =>
      pauseError != null
          ? Future<WorkoutSessionRecord>.error(pauseError!)
          : pauseCompleter?.future ?? active!;

  @override
  Future<WorkoutSessionRecord> resumeSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime resumedAtUtc,
  }) async =>
      active!;

  @override
  Future<WorkoutSessionRecord> logPerformedSet({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required PerformedSet set,
  }) async {
    lastLoggedSet = set;
    final record = active!;
    active = record.copyWith(
      session: record.session.logSet(set),
      revision: record.revision + 1,
    );
    return active!;
  }

  @override
  Future<WorkoutSessionRecord> removePerformedSet({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required String setId,
  }) async {
    final record = active!;
    active = record.copyWith(
      session: record.session.removeSet(setId),
      revision: record.revision + 1,
    );
    return active!;
  }

  @override
  Future<WorkoutSessionRecord> completeSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime completedAtUtc,
    String? notes,
    required String workoutTitle,
    required DateTime workoutAtUtc,
    required int workoutUtcOffsetMinutes,
  }) async =>
      completeResult ?? active!;

  @override
  Future<WorkoutSessionRecord> discardSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime discardedAtUtc,
    required String reason,
  }) async =>
      discardResult ?? active!;
}

final class _PreviewCatalogRepository implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([
        Exercise(
          ref: ExerciseRef.catalog('ex_barbell_bench_press'),
          displayName: 'Bench Press',
          status: ExerciseStatus.active,
          media: ExerciseMedia(
            type: ExerciseMediaType.image,
            defaultGender: ExerciseMediaGender.male,
            male: ExerciseMediaVariant(
              thumbnailUrl: Uri.parse('https://example.com/bench.png'),
            ),
            female: ExerciseMediaVariant(
              thumbnailUrl: Uri.parse('https://example.com/bench.png'),
            ),
          ),
        ),
      ]);
}

final class _PreviewReplacementCatalogRepository
    implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([
        Exercise(
          ref: ExerciseRef.catalog('ex_barbell_bench_press'),
          displayName: 'Bench Press',
          status: ExerciseStatus.active,
        ),
        Exercise(
          ref: ExerciseRef.catalog('ex_barbell_back_squat'),
          displayName: 'Back Squat',
          status: ExerciseStatus.active,
        ),
      ]);
}

WorkoutSessionSnapshot _snapshot({
  int? restSeconds = 120,
  int? secondRestSeconds,
}) =>
    WorkoutSessionSnapshot(
      routineId: _routineId,
      routineName: 'Push Day A',
      programId: _programId,
      capturedAtUtc: DateTime.utc(2026, 11, 7, 10),
      exercises: [
        SessionExerciseSnapshot(
          exerciseRef: _exerciseRef,
          displayName: 'Bench Press',
          exerciseType: ExerciseType.weightReps,
          occurrenceIndex: 0,
          prescribedSets: [
            SetPrescription(
              setType: RoutineSetType.normal,
              reps: 8,
              loadKg: 80,
              restSeconds: restSeconds,
            ),
            if (secondRestSeconds != null)
              SetPrescription(
                setType: RoutineSetType.normal,
                reps: 8,
                loadKg: 80,
                restSeconds: secondRestSeconds,
              ),
          ],
        ),
      ],
    );

WorkoutSession _session({
  WorkoutSessionStatus status = WorkoutSessionStatus.active,
  bool withPerformedSet = true,
  int? restSeconds = 120,
  int? secondRestSeconds,
}) {
  final start = DateTime.utc(2026, 11, 7, 10);
  final paused = status == WorkoutSessionStatus.paused ? start : null;
  return WorkoutSession(
    id: _sessionId,
    userId: _userId,
    programId: _programId,
    routineId: _routineId,
    status: status,
    time: WorkoutTime(
      startedAtUtc: start,
      pausedAtUtc: paused,
      completedAtUtc: status.isTerminal ? start : null,
      lastTransitionAtUtc: start,
    ),
    localDate: '2026-11-07',
    snapshot: _snapshot(
      restSeconds: restSeconds,
      secondRestSeconds: secondRestSeconds,
    ),
    performedSets: withPerformedSet
        ? [
            PerformedSet(
              id: '55555555-5555-4555-a555-555555555555',
              exerciseRef: _exerciseRef,
              sessionExerciseIndex: 0,
              setIndex: 0,
              reps: 8,
              loadKg: 80,
              completedAtUtc: start,
            ),
          ]
        : const [],
    discardReason:
        status == WorkoutSessionStatus.discarded ? 'Test discard' : null,
  );
}

WorkoutSession _cardioSession() {
  final start = DateTime.utc(2026, 11, 7, 10);
  final snapshot = WorkoutSessionSnapshot(
    routineId: _routineId,
    routineName: 'Cardio Day',
    programId: _programId,
    capturedAtUtc: start,
    exercises: [
      SessionExerciseSnapshot(
        exerciseRef: _exerciseRef,
        displayName: 'Treadmill',
        exerciseType: ExerciseType.distanceDuration,
        occurrenceIndex: 0,
        prescribedSets: [
          SetPrescription(distanceMeters: 1200, durationSeconds: 60),
        ],
      ),
    ],
  );
  return WorkoutSession(
    id: _sessionId,
    userId: _userId,
    programId: _programId,
    routineId: _routineId,
    status: WorkoutSessionStatus.active,
    time: WorkoutTime.start(startedAtUtc: start),
    localDate: '2026-11-07',
    snapshot: snapshot,
    performedSets: [
      PerformedSet(
        id: '88888888-8888-4888-a888-888888888888',
        exerciseRef: _exerciseRef,
        sessionExerciseIndex: 0,
        setIndex: 0,
        distanceMeters: 2500,
        durationSeconds: 905,
        completedAtUtc: start.add(const Duration(minutes: 1)),
      ),
    ],
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required ActiveWorkoutController controller,
  ExerciseCatalogRepository? catalogRepository,
  bool showStartPreview = false,
  TioThemeMode themeMode = TioThemeMode.light,
  VoidCallback? onBack,
  DateTime Function()? clock,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: themeMode),
        child: child ?? const SizedBox.shrink(),
      ),
      home: ActiveWorkoutPage(
        controller: controller,
        catalogRepository: catalogRepository,
        showStartPreview: showStartPreview,
        onBack: onBack,
        clock: clock ?? () => tester.binding.clock.now(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _addPreviewBench(WidgetTester tester) async {
  await tester
      .tap(find.byKey(const ValueKey('active-workout-preview-add-exercise')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester
      .tap(find.byKey(const ValueKey('exercise-row-ex_barbell_bench_press')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('removing a preview Set preserves performed state on later Sets',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      catalogRepository: _PreviewCatalogRepository(),
      showStartPreview: true,
    );
    await _addPreviewBench(tester);
    await tester.tap(find.widgetWithText(TioButton, 'Add Set'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TioButton, 'Add Set'));
    await tester.pumpAndSettle();

    Future<void> logSet(String suffix, String load, String reps) async {
      await tester.enterText(
        find.descendant(
          of: find.byKey(ValueKey('active-workout-preview-load-$suffix')),
          matching: find.byType(EditableText),
        ),
        load,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(ValueKey('active-workout-preview-reps-$suffix')),
          matching: find.byType(EditableText),
        ),
        reps,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('active-workout-preview-set-toggle-$suffix')),
      );
      await tester.pumpAndSettle();
    }

    await logSet('0-0', '40', '8');
    await logSet('0-2', '45', '9');
    await tester.tap(
        find.byKey(const ValueKey('active-workout-preview-set-number-0-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-type-remove-set')));
    await tester.pumpAndSettle();

    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('active-workout-progress-bar')),
          )
          .value,
      '100%',
    );
    expect(find.text('45'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('re-adding a preview Set after removal creates a unique UUID',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      catalogRepository: _PreviewCatalogRepository(),
      showStartPreview: true,
    );
    await _addPreviewBench(tester);
    await tester.tap(find.widgetWithText(TioButton, 'Add Set'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TioButton, 'Add Set'));
    await tester.pumpAndSettle();
    await tester.tap(
        find.byKey(const ValueKey('active-workout-preview-set-number-0-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-type-remove-set')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TioButton, 'Add Set'));
    await tester.pumpAndSettle();

    final card = tester.widget<WorkoutExerciseCard>(
      find.byKey(const ValueKey('active-workout-preview-exercise-0')),
    );
    final setIds = card.entry.sets.map((set) => set.id).toList();
    expect(setIds, hasLength(3));
    expect(setIds.toSet(), hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing a preview exercise keeps remaining logged state',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      catalogRepository: _PreviewReplacementCatalogRepository(),
      showStartPreview: true,
    );
    await _addPreviewBench(tester);

    await tester.tap(
      find.byKey(const ValueKey('active-workout-preview-add-exercise')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
      find.byKey(const ValueKey('exercise-row-ex_barbell_back_squat')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();

    Future<void> logPreviewSet({
      required String loadKey,
      required String repsKey,
      required String toggleKey,
      required String load,
      required String reps,
    }) async {
      await tester.enterText(
        find.descendant(
          of: find.byKey(ValueKey(loadKey)),
          matching: find.byType(EditableText),
        ),
        load,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(ValueKey(repsKey)),
          matching: find.byType(EditableText),
        ),
        reps,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(toggleKey)));
      await tester.pumpAndSettle();
    }

    await logPreviewSet(
      loadKey: 'active-workout-preview-load-0-0',
      repsKey: 'active-workout-preview-reps-0-0',
      toggleKey: 'active-workout-preview-set-toggle-0-0',
      load: '45',
      reps: '8',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('active-workout-preview-set-toggle-1-0')),
    );
    await logPreviewSet(
      loadKey: 'active-workout-preview-load-1-0',
      repsKey: 'active-workout-preview-reps-1-0',
      toggleKey: 'active-workout-preview-set-toggle-1-0',
      load: '100',
      reps: '5',
    );

    final firstExercise =
        find.byKey(const ValueKey('active-workout-preview-exercise-0'));
    await tester.ensureVisible(firstExercise);
    await tester.tap(
      find.descendant(
        of: firstExercise,
        matching: find.byTooltip('Exercise options'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('routine-exercise-option-remove')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bench Press'), findsNothing);
    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('active-workout-progress-bar')),
          )
          .value,
      '100%',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing an edited preview exercise clears its local drafts',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      catalogRepository: _PreviewReplacementCatalogRepository(),
      showStartPreview: true,
    );
    await _addPreviewBench(tester);

    await tester.tap(
      find.byKey(const ValueKey('exercise-note-action-ex_barbell_bench_press')),
    );
    await tester.pumpAndSettle();
    final noteInput = find.byKey(
      const ValueKey('exercise-note-input-ex_barbell_bench_press'),
    );
    await tester.enterText(noteInput, 'Bench-specific draft');
    await tester.pumpAndSettle();

    final card = find.byKey(
      const ValueKey('active-workout-preview-exercise-0'),
    );
    await tester.tap(
      find.descendant(of: card, matching: find.byTooltip('Exercise options')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('routine-exercise-option-replace')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
      find.byKey(const ValueKey('exercise-row-ex_barbell_back_squat')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();

    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('Bench-specific draft'), findsNothing);
    expect(
      find.byKey(const ValueKey('exercise-note-input-ex_barbell_back_squat')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Play preview has no fabricated session or exercise',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      catalogRepository: _PreviewCatalogRepository(),
      showStartPreview: true,
    );
    expect(find.byKey(const ValueKey('active-workout-start-preview')),
        findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Add an exercise to start your workout'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    final finish = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-preview-finish')),
    );
    expect(finish.enabled, isFalse);
    expect(
      tester
          .getSize(
            find.descendant(
              of: find.byKey(const ValueKey('active-workout-preview-finish')),
              matching: find.byType(FilledButton),
            ),
          )
          .height,
      TioSize.dp34,
    );
    expect(find.text('Bench Press'), findsNothing);
    final addExercise = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-preview-add-exercise')),
    );
    expect(addExercise.enabled, isTrue);
    final discard = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-preview-discard')),
    );
    expect(discard.enabled, isFalse);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Back to Workout'), findsNothing);
    expect(find.byType(TioCard), findsNothing);
  });

  testWidgets('performed set logs typed values, not prescribed targets',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(
        session: _session(withPerformedSet: false),
        revision: 1,
      );
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );
    await _pumpPage(tester, controller: controller);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-load-0')),
        matching: find.byType(EditableText),
      ),
      '12',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-reps-0')),
        matching: find.byType(EditableText),
      ),
      '6',
    );
    await tester.tap(find.byKey(const ValueKey('active-workout-set-toggle-0')));
    await tester.pumpAndSettle();
    expect(repository.lastLoggedSet?.loadKg, 12);
    expect(repository.lastLoggedSet?.reps, 6);
    expect(controller.state.performedSets.single.loadKg, 12);
    expect(controller.state.performedSets.single.reps, 6);
    expect(find.byKey(const ValueKey('active-workout-load-0')), findsNothing);
    expect(find.byKey(const ValueKey('active-workout-reps-0')), findsNothing);
  });

  testWidgets('logging a set starts its configured rest timer', (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(
        session: _session(withPerformedSet: false, restSeconds: 90),
        revision: 1,
      );
    final now = DateTime.utc(2026, 11, 7, 10, 5);
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
      clock: () => now,
    );
    await _pumpPage(tester, controller: controller, clock: () => now);

    await tester.tap(find.byKey(const ValueKey('active-workout-set-toggle-0')));
    await tester.pumpAndSettle();

    expect(repository.lastLoggedSet, isNotNull);
    expect(controller.state.activeRestTimer?.totalDurationSeconds, 90);
    expect(controller.state.activeRestTimer?.sessionExerciseIndex, 0);
    expect(controller.state.activeRestTimer?.setIndex, 0);
  });

  testWidgets('logging a set without a rest preset leaves timer off',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(
        session: _session(withPerformedSet: false, restSeconds: null),
        revision: 1,
      );
    final now = DateTime.utc(2026, 11, 7, 10, 5);
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
      clock: () => now,
    );
    await _pumpPage(tester, controller: controller, clock: () => now);

    await tester.tap(find.byKey(const ValueKey('active-workout-set-toggle-0')));
    await tester.pumpAndSettle();

    expect(repository.lastLoggedSet, isNotNull);
    expect(controller.state.activeRestTimer, isNull);
  });

  testWidgets('logging sets uses each mixed prescribed rest duration',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(
        session: _session(
          withPerformedSet: false,
          restSeconds: 60,
          secondRestSeconds: 90,
        ),
        revision: 1,
      );
    final now = DateTime.utc(2026, 11, 7, 10, 5);
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
      clock: () => now,
    );
    await _pumpPage(tester, controller: controller, clock: () => now);

    await tester.tap(find.byKey(const ValueKey('active-workout-set-toggle-0')));
    await tester.pumpAndSettle();
    expect(controller.state.activeRestTimer?.totalDurationSeconds, 60);

    await tester.ensureVisible(
      find.byKey(const ValueKey('active-workout-set-toggle-1')),
    );
    await tester.tap(find.byKey(const ValueKey('active-workout-set-toggle-1')));
    await tester.pumpAndSettle();
    expect(controller.state.activeRestTimer?.totalDurationSeconds, 90);
    expect(controller.state.activeRestTimer?.setIndex, 1);
  });

  testWidgets('adds selected exercises from the routine picker to preview',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      catalogRepository: _PreviewCatalogRepository(),
      showStartPreview: true,
    );

    await tester.tap(
      find.byKey(const ValueKey('active-workout-preview-add-exercise')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('exercises-page')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('exercise-row-ex_barbell_bench_press')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('exercise-selected-ex_barbell_bench_press')),
      findsOneWidget,
    );
    final addSelected = tester.widget<TioButton>(
      find.byKey(const ValueKey('exercises-add-selected')),
    );
    expect(addSelected.enabled, isTrue);
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('exercises-page')), findsNothing);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('active-workout-preview-exercise-0')),
      findsOneWidget,
    );
    expect(find.text('1 sets'), findsNothing);
    expect(find.text('SET'), findsOneWidget);
    expect(find.text('PREVIOUS'), findsOneWidget);
    expect(find.text('KG'), findsOneWidget);
    expect(find.text('REPS'), findsOneWidget);
    expect(find.text('RPE'), findsOneWidget);

    final exerciseCard = find.byKey(
      const ValueKey('active-workout-preview-exercise-0'),
    );
    final cardRect = tester.getRect(exerciseCard);
    final thumbnailFinder = find.descendant(
      of: exerciseCard,
      matching: find.byType(ExerciseThumbnail),
    );
    expect(thumbnailFinder, findsOneWidget);
    final thumbRect = tester.getRect(thumbnailFinder);

    final previewRow = find.byKey(
      const ValueKey('active-workout-preview-row-0-0'),
    );
    final logSet = find.byKey(
      const ValueKey('active-workout-preview-set-toggle-0-0'),
    );
    final rowRect = tester.getRect(previewRow);
    final setBadgeRect = tester.getRect(
      find.byKey(const ValueKey('active-workout-preview-set-number-0-0')),
    );
    final checkRect = tester.getRect(logSet);
    expect(rowRect.left, closeTo(cardRect.left, 0.1));
    expect(rowRect.right, closeTo(cardRect.right, 0.1));
    expect(thumbRect.left, closeTo(setBadgeRect.left, 0.1));
    expect(setBadgeRect.left, closeTo(rowRect.left + TioSpacing.lg, 0.1));
    expect(checkRect.right, closeTo(rowRect.right - TioSpacing.lg, 0.1));
    expect(tester.widget<IconButton>(logSet).onPressed, isNotNull);
    await tester.tap(logSet);
    await tester.pump();
    expect(find.byKey(const ValueKey('active-workout-preview-load-0-0')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-preview-reps-0-0')),
        findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-preview-load-0-0')),
        matching: find.byType(EditableText),
      ),
      '12',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-preview-reps-0-0')),
        matching: find.byType(EditableText),
      ),
      '6',
    );
    await tester.tap(logSet);
    await tester.pump();

    expect(find.byKey(const ValueKey('active-workout-preview-load-0-0')),
        findsNothing);
    expect(find.byKey(const ValueKey('active-workout-preview-reps-0-0')),
        findsNothing);
    expect(find.text('72 kg'), findsOneWidget);
    final loggedRow = tester.widget<Container>(
      find.byKey(const ValueKey('active-workout-preview-row-0-0')),
    );
    expect(loggedRow.color, isNot(TioPalette.transparent));

    await tester.tap(logSet);
    await tester.pump();
    expect(find.byKey(const ValueKey('active-workout-preview-load-0-0')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-preview-reps-0-0')),
        findsOneWidget);
    expect(find.text('0 kg'), findsOneWidget);

    final addSet = find.widgetWithText(TioButton, 'Add Set');
    expect(addSet, findsOneWidget);
    await tester.tap(addSet);
    await tester.pump();

    final row0 = find.byKey(const ValueKey('active-workout-preview-row-0-0'));
    final row1 = find.byKey(const ValueKey('active-workout-preview-row-0-1'));
    expect(row0, findsOneWidget);
    expect(row1, findsOneWidget);

    final check0 =
        find.byKey(const ValueKey('active-workout-preview-set-toggle-0-0'));
    final check1 =
        find.byKey(const ValueKey('active-workout-preview-set-toggle-0-1'));
    final c0Rect = tester.getRect(check0);
    final c1Rect = tester.getRect(check1);
    // Row 0 checkmark height is 38dp, row minHeight is 48dp with 5dp vertical padding.
    // Row 0 bottom padding is 5dp, margin is 8dp (TioSpacing.sm), Row 1 top padding is 5dp.
    // So distance between c0 bottom and c1 top is 5 + 8 + 5 = 18dp.
    expect(c1Rect.top - c0Rect.bottom, closeTo(TioSpacing.sm, 0.1));
  });

  testWidgets('does not log an invalid immediate draft from stale input state',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(
        session: _session(withPerformedSet: false),
        revision: 1,
      );
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );
    await _pumpPage(tester, controller: controller);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-load-0')),
        matching: find.byType(EditableText),
      ),
      '',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-reps-0')),
        matching: find.byType(EditableText),
      ),
      '',
    );
    await tester.tap(find.byKey(const ValueKey('active-workout-set-toggle-0')));
    await tester.pumpAndSettle();

    expect(repository.lastLoggedSet, isNull);
    expect(controller.state.performedSets, isEmpty);
  });

  testWidgets('restored performed values remain distinct from prescriptions',
      (tester) async {
    final restoredSet = PerformedSet(
      id: '66666666-6666-4666-a666-666666666666',
      exerciseRef: _exerciseRef,
      sessionExerciseIndex: 0,
      setIndex: 0,
      reps: 6,
      loadKg: 12,
      completedAtUtc: DateTime.utc(2026, 11, 7, 10, 1),
    );
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(
        session: _session(withPerformedSet: false).logSet(restoredSet),
        revision: 2,
      );
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );
    await _pumpPage(tester, controller: controller);

    expect(find.byKey(const ValueKey('active-workout-load-0')), findsNothing);
    expect(find.byKey(const ValueKey('active-workout-reps-0')), findsNothing);
    expect(controller.state.performedSets.single.loadKg, 12);
    expect(controller.state.performedSets.single.reps, 6);
  });

  testWidgets('restored real sessions do not expose unpersisted RPE or type',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(
        session: _session(withPerformedSet: false),
        revision: 1,
      );
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );
    await _pumpPage(tester, controller: controller);

    final setType = tester.widget<InkWell>(
      find.byKey(const ValueKey('active-workout-set-number-0')),
    );
    final rpe = tester.widget<InkWell>(
      find.byKey(const ValueKey('active-workout-rpe-0')),
    );
    expect(setType.onTap, isNull);
    expect(rpe.onTap, isNull);

    await tester.tap(find.byKey(const ValueKey('active-workout-rpe-0')));
    await tester.pumpAndSettle();
    expect(find.text('Log Set RPE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores all additional performed sets beyond the snapshot',
      (tester) async {
    final start = DateTime.utc(2026, 11, 7, 10);
    final session = _session(withPerformedSet: false)
        .logSet(
          PerformedSet(
            id: '66666666-6666-4666-a666-666666666666',
            exerciseRef: _exerciseRef,
            sessionExerciseIndex: 0,
            setIndex: 1,
            reps: 7,
            loadKg: 31,
            completedAtUtc: start.add(const Duration(minutes: 1)),
          ),
        )
        .logSet(
          PerformedSet(
            id: '77777777-7777-4777-a777-777777777777',
            exerciseRef: _exerciseRef,
            sessionExerciseIndex: 0,
            setIndex: 2,
            reps: 9,
            loadKg: 33,
            completedAtUtc: start.add(const Duration(minutes: 2)),
          ),
        );
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(session: session, revision: 3);
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );

    await _pumpPage(tester, controller: controller);
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -280),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-workout-set-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-set-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-set-2')), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('33'), findsOneWidget);
  });

  testWidgets('restored cardio values seed inputs and survive re-log at 320dp',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(session: _cardioSession(), revision: 2);
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      themeMode: TioThemeMode.light,
    );
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -280),
    );
    await tester.pumpAndSettle();

    expect(find.text('2.5'), findsOneWidget);
    expect(find.text('15:05'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('active-workout-set-toggle-0')));
    await tester.pumpAndSettle();

    const setRowId = '00000000-0000-4000-0000-000000000000';
    final distanceInput = tester.widget<EditableText>(find.descendant(
      of: find.byKey(const ValueKey('routine-set-distance-$setRowId')),
      matching: find.byType(EditableText),
    ));
    final durationInput = tester.widget<EditableText>(find.descendant(
      of: find.byKey(const ValueKey('routine-set-duration-$setRowId')),
      matching: find.byType(EditableText),
    ));
    expect(distanceInput.controller.text, '2.5');
    expect(durationInput.controller.text, '15:05');

    await tester.tap(find.byKey(const ValueKey('active-workout-set-toggle-0')));
    await tester.pumpAndSettle();
    expect(repository.lastLoggedSet?.distanceMeters, 2500);
    expect(repository.lastLoggedSet?.durationSeconds, 905);
    expect(tester.takeException(), isNull);
  });

  for (final themeMode in [TioThemeMode.light, TioThemeMode.dark]) {
    testWidgets(
        'execution headers follow cardio measurement columns in ${themeMode.name}',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => TioTheme(
          config: TioThemeConfig(mode: themeMode),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: ListView(
            children: [
              for (final type in [
                ExerciseType.distanceDuration,
                ExerciseType.duration,
              ])
                WorkoutExerciseCard(
                  key: ValueKey('cardio-header-${type.name}'),
                  mode: WorkoutExerciseCardMode.log,
                  entry: RoutineCompositionEntry(
                    id: type == ExerciseType.distanceDuration
                        ? '11111111-1111-4111-a111-111111111111'
                        : '22222222-2222-4222-a222-222222222222',
                    exercise: _exerciseRef,
                    sets: [
                      RoutineCompositionSet(
                        id: type == ExerciseType.distanceDuration
                            ? '33333333-3333-4333-a333-333333333333'
                            : '44444444-4444-4444-a444-444444444444',
                        prescription: SetPrescription(),
                      ),
                    ],
                  ),
                  index: type.index,
                  totalEntries: 2,
                  title: 'Cardio ${type.name}',
                  thumbnailUrl: null,
                  exerciseType: type,
                  showRangeDraft: false,
                  unit: WeightUnit.kg,
                  enabled: true,
                  buildSetRow: (_, __) => const SizedBox(height: 40),
                  addSet: () {},
                  keyPrefix: 'header-${type.name}',
                ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final distanceCard = find.byKey(
        const ValueKey('cardio-header-distanceDuration'),
      );
      final timeCard = find.byKey(
        const ValueKey('cardio-header-duration'),
      );
      expect(distanceCard, findsOneWidget);
      expect(timeCard, findsOneWidget);
      expect(find.descendant(of: distanceCard, matching: find.text('KM')),
          findsOneWidget);
      expect(find.descendant(of: distanceCard, matching: find.text('TIME')),
          findsOneWidget);
      expect(find.descendant(of: distanceCard, matching: find.text('KG')),
          findsNothing);
      expect(find.descendant(of: distanceCard, matching: find.text('REPS')),
          findsNothing);
      expect(find.descendant(of: timeCard, matching: find.text('TIME')),
          findsOneWidget);
      expect(find.descendant(of: timeCard, matching: find.text('KM')),
          findsNothing);
      expect(find.descendant(of: timeCard, matching: find.text('KG')),
          findsNothing);
      expect(find.descendant(of: timeCard, matching: find.text('REPS')),
          findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders active snapshot and controller-backed actions',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(session: _session(), revision: 1);
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
      clock: () => DateTime.utc(2026, 11, 7, 10, 1),
    );

    await _pumpPage(tester, controller: controller);

    expect(find.text('Push Day A'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-pause-resume')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('active-workout-complete')), findsOneWidget);
  });

  testWidgets('renders the execution UI on a compact dark viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(session: _session(), revision: 1);
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      themeMode: TioThemeMode.dark,
    );

    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-set-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.drag(
        find.byType(SingleChildScrollView).last, const Offset(0, -240));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the empty start UI on a compact dark viewport',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      showStartPreview: true,
      themeMode: TioThemeMode.dark,
    );

    expect(find.text('Get started'), findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-preview-add-exercise')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-preview-settings')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-preview-discard')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders paused state without changing snapshot identity',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(
        session: _session(status: WorkoutSessionStatus.paused),
        revision: 2,
      );
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
      clock: () => DateTime.utc(2026, 11, 7, 10, 1),
    );

    await _pumpPage(tester, controller: controller);

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Resume workout'), findsOneWidget);
  });

  testWidgets('keeps Finish disabled until a set is logged', (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(
        session: _session(withPerformedSet: false),
        revision: 1,
      );
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );

    await _pumpPage(tester, controller: controller);

    final finish = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-complete')),
    );
    expect(finish.enabled, isFalse);
    expect(find.text('Log at least one set before finishing this workout.'),
        findsOneWidget);
  });

  testWidgets(
      'disables duplicate actions while a controller command is pending',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(session: _session(), revision: 1)
      ..pauseCompleter = Completer<WorkoutSessionRecord>();
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );

    await _pumpPage(tester, controller: controller);
    await tester.tap(find.byKey(const ValueKey('active-workout-pause-resume')));
    await tester.pump();

    final pauseButton = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-pause-resume')),
    );
    final completeButton = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-complete')),
    );
    expect(pauseButton.loading, isTrue);
    expect(completeButton.loading, isTrue);

    repository.pauseCompleter!.complete(repository.active!);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('renders recoverable action errors for an active session',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(session: _session(), revision: 1)
      ..pauseError = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'Workout could not be paused while offline.',
      );
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );

    await _pumpPage(tester, controller: controller);
    await tester.tap(find.byKey(const ValueKey('active-workout-pause-resume')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('active-workout-action-error')),
      findsOneWidget,
    );
    expect(find.text('Workout could not be paused while offline.'),
        findsOneWidget);
  });

  testWidgets('renders explicit no-session state', (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );

    await _pumpPage(tester, controller: controller);

    expect(find.byKey(const ValueKey('active-workout-no-session')),
        findsOneWidget);
    expect(find.text('No active workout'), findsOneWidget);
    expect(find.text('There is no workout session to resume right now.'),
        findsOneWidget);
  });

  testWidgets('reconciliation provides guarded Retry and Back actions',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..restoreError = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'PGRST205: user_workout_sessions is unavailable',
      )
      ..active = WorkoutSessionRecord(session: _session(), revision: 1);
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );

    await _pumpPage(tester, controller: controller);
    final back = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-Back')),
    );
    expect(
      find.byKey(const ValueKey('active-workout-reconciliation')),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(back.onPressed, isNotNull);
    expect(find.textContaining('PGRST205'), findsNothing);

    final pending = Completer<WorkoutSessionRecord?>();
    repository
      ..restoreError = null
      ..activeSessionCompleter = pending;
    await tester.tap(find.byKey(const ValueKey('active-workout-Retry')));
    await tester.pump();

    final retry = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-Retry')),
    );
    final backWhilePending = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-Back')),
    );
    expect(retry.loading, isTrue);
    expect(backWhilePending.onPressed, isNull);

    pending.complete(repository.active);
    await tester.pumpAndSettle();
    expect(find.text('Push Day A'), findsOneWidget);
    expect(controller.state.status, ActiveWorkoutStatus.active);
  });

  testWidgets('reconciliation Back returns control to the caller',
      (tester) async {
    final repository = _FakeSessionRepository()
      ..restoreError = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
      );
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );
    var backed = false;
    await _pumpPage(
      tester,
      controller: controller,
      onBack: () => backed = true,
    );

    await tester.tap(find.byKey(const ValueKey('active-workout-Back')));

    expect(backed, isTrue);
  });

  testWidgets('load failure keeps reconciliation state instead of preview',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository()
        ..restoreError = const WorkoutSessionPersistenceException(
          WorkoutSessionPersistenceFailureKind.networkUnavailable,
          message: 'PGRST205: user_workout_sessions is unavailable',
        ),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      showStartPreview: true,
    );

    expect(find.byKey(const ValueKey('active-workout-reconciliation')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-start-preview')),
        findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('PGRST205'), findsNothing);
  });

  testWidgets('preview timer ticks and formats seconds, minutes and hours',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      showStartPreview: true,
    );

    expect(find.text('0s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 44));
    expect(find.text('44s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 24));
    expect(find.text('1min 8s'), findsOneWidget);

    // Pump to 1h 47min 47s (107 minutes 47 seconds = 6467 total seconds, 6467 - 68 = 6399 seconds)
    await tester.pump(const Duration(seconds: 6399));
    expect(find.text('1h 47min 47s'), findsOneWidget);
  });

  testWidgets(
      'preview timer pause and resume toggles via timer click and bottom sheet',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      showStartPreview: true,
    );

    // Initial 10s
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('10s'), findsOneWidget);
    final runningDuration = tester.widget<Text>(find.text('10s'));
    expect(runningDuration.style?.color, TioColors.light.primary);

    // Tap Duration stat to open bottom sheet
    await tester
        .tap(find.byKey(const ValueKey('active-workout-duration-stat')));
    await tester.pumpAndSettle();

    expect(find.text('Duration'), findsWidgets);
    expect(find.text('Pause Workout Timer'), findsOneWidget);
    // 10s is displayed on both main screen and the open bottom sheet
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('10s'),
      ),
      findsOneWidget,
    );

    // Live timer ticking inside open bottom sheet
    await tester.pump(const Duration(seconds: 3));
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('13s'),
      ),
      findsOneWidget,
    );

    // Tap Pause Workout Timer
    await tester
        .tap(find.byKey(const ValueKey('active-workout-pause-sheet-action')));
    await tester.pumpAndSettle();

    expect(find.text('Pause Workout Timer'), findsNothing);

    // Advance time by 15 seconds while paused
    await tester.pump(const Duration(seconds: 15));
    // Time must remain frozen at 13s and show disabled color
    expect(find.text('13s'), findsOneWidget);
    final pausedDuration = tester.widget<Text>(find.text('13s'));
    expect(pausedDuration.style?.color, TioColors.light.textSecondary);

    // Tap top timer icon to open bottom sheet again
    await tester
        .tap(find.byKey(const ValueKey('active-workout-preview-timer')));
    await tester.pumpAndSettle();

    expect(find.text('Resume Workout Timer'), findsOneWidget);
    final sheetPausedDuration = tester.widget<Text>(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('13s'),
      ),
    );
    expect(sheetPausedDuration.style?.color, TioColors.light.textSecondary);

    // Tap Resume Workout Timer
    await tester
        .tap(find.byKey(const ValueKey('active-workout-pause-sheet-action')));
    await tester.pumpAndSettle();

    // Advance time by 5 seconds after resume
    await tester.pump(const Duration(seconds: 5));
    // Time resumed and reached 18s with active color
    expect(find.text('18s'), findsOneWidget);
    final resumedDuration = tester.widget<Text>(find.text('18s'));
    expect(resumedDuration.style?.color, TioColors.light.primary);
  });

  testWidgets('preview discard asks confirmation and calls onBack on confirm',
      (tester) async {
    var backed = false;
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      catalogRepository: _PreviewCatalogRepository(),
      showStartPreview: true,
      onBack: () => backed = true,
    );

    // Add an exercise so discard is enabled
    await tester.tap(
      find.byKey(const ValueKey('active-workout-preview-add-exercise')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
      find.byKey(const ValueKey('exercise-row-ex_barbell_bench_press')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Bench Press'), findsOneWidget);

    final discard = tester.widget<TioButton>(
      find.byKey(const ValueKey('active-workout-preview-discard')),
    );
    expect(discard.enabled, isTrue);

    await tester
        .tap(find.byKey(const ValueKey('active-workout-preview-discard')));
    await tester.pumpAndSettle();

    expect(find.text('Discard workout?'), findsOneWidget);
    expect(find.text('This session and any logged sets will be discarded.'),
        findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(TioButton, 'Discard workout'),
      ),
    );
    await tester.pumpAndSettle();

    expect(backed, isTrue);
  });

  testWidgets('tapping RPE button opens Log Set RPE sheet and updates value',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      catalogRepository: _PreviewCatalogRepository(),
      showStartPreview: true,
    );

    // Add an exercise
    await tester.tap(
      find.byKey(const ValueKey('active-workout-preview-add-exercise')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
      find.byKey(const ValueKey('exercise-row-ex_barbell_bench_press')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('active-workout-preview-rpe-0-0')),
        findsOneWidget);

    // Tap RPE icon
    await tester.tap(
      find.byKey(const ValueKey('active-workout-preview-rpe-0-0')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log Set RPE'), findsOneWidget);
    expect(find.text('Set 1: 0kg x 0 reps'), findsOneWidget);
    expect(find.text('Select RPE'), findsOneWidget);

    // Select 7.5
    await tester.tap(find.byKey(const ValueKey('rpe-option-7.5')));
    await tester.pumpAndSettle();

    expect(find.text('Vigorous Effort'), findsOneWidget);
    expect(find.text('Could have maybe done 3 more reps'), findsOneWidget);

    // Tap Done
    await tester.tap(find.byKey(const ValueKey('rpe-sheet-done-button')));
    await tester.pumpAndSettle();

    expect(find.text('Log Set RPE'), findsNothing);
    // Value 7.5 is displayed in the set row
    expect(find.text('7.5'), findsOneWidget);
  });

  testWidgets('discards a real active workout after confirmation',
      (tester) async {
    final discarded = WorkoutSessionRecord(
      session: _session(status: WorkoutSessionStatus.discarded),
      revision: 2,
    );
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(session: _session(), revision: 1)
      ..discardResult = discarded;
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );
    await _pumpPage(tester, controller: controller);

    await tester.ensureVisible(
      find.byKey(const ValueKey('active-workout-discard')),
    );
    await tester.tap(find.byKey(const ValueKey('active-workout-discard')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.widgetWithText(TioButton, 'Discard workout'),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.state.status, ActiveWorkoutStatus.discarded);
    expect(find.byKey(const ValueKey('active-workout-discard')), findsNothing);
  });

  testWidgets('auth invalidation never renders stale session data',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository()
        ..active = WorkoutSessionRecord(session: _session(), revision: 1),
      currentUserId: () => null,
    );

    await _pumpPage(tester, controller: controller);

    expect(
      find.byKey(const ValueKey('active-workout-auth-invalidated')),
      findsOneWidget,
    );
    expect(find.text('Push Day A'), findsNothing);
    expect(find.text('Bench Press'), findsNothing);
  });

  testWidgets('terminal state restricts mutating actions', (tester) async {
    final terminalRecord = WorkoutSessionRecord(
      session: _session(status: WorkoutSessionStatus.completed),
      revision: 3,
    );
    final repository = _FakeSessionRepository()
      ..active = WorkoutSessionRecord(session: _session(), revision: 1)
      ..completeResult = terminalRecord;
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
      clock: () => DateTime.utc(2026, 11, 7, 10, 1),
    );

    await _pumpPage(tester, controller: controller);
    await tester.ensureVisible(
      find.byKey(const ValueKey('active-workout-complete')),
    );
    await tester.tap(find.byKey(const ValueKey('active-workout-complete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-workout-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-complete')), findsNothing);
    expect(find.byKey(const ValueKey('active-workout-pause-resume')),
        findsNothing);
    expect(find.text('Back to Workout'), findsOneWidget);
  });

  testWidgets(
      'progress bar updates as sets are logged and Finish button turns green when workout is complete',
      (tester) async {
    final controller = ActiveWorkoutController(
      repository: _FakeSessionRepository(),
      currentUserId: () => _userId,
    );
    await _pumpPage(
      tester,
      controller: controller,
      catalogRepository: _PreviewCatalogRepository(),
      showStartPreview: true,
    );

    // Add Bench Press exercise
    await tester
        .tap(find.byKey(const ValueKey('active-workout-preview-add-exercise')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester
        .tap(find.byKey(const ValueKey('exercise-row-ex_barbell_bench_press')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exercises-add-selected')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('active-workout-progress-bar')),
        findsOneWidget);

    // Initial state: 0 of 1 set logged -> progress 0%
    var semantics = tester.getSemantics(
        find.byKey(const ValueKey('active-workout-progress-bar')));
    expect(semantics.value, '0%');

    // Add a second set so there are 2 sets in total
    await tester.tap(find.widgetWithText(TioButton, 'Add Set'));
    await tester.pumpAndSettle();

    // Log Set 1: progress becomes 1/2 = 50%
    final toggle0 =
        find.byKey(const ValueKey('active-workout-preview-set-toggle-0-0'));
    await tester.tap(toggle0);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-preview-load-0-0')),
        matching: find.byType(EditableText),
      ),
      '50',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-preview-reps-0-0')),
        matching: find.byType(EditableText),
      ),
      '10',
    );
    await tester.pumpAndSettle();
    await tester.tap(toggle0);
    await tester.pumpAndSettle();

    semantics = tester.getSemantics(
        find.byKey(const ValueKey('active-workout-progress-bar')));
    expect(semantics.value, '50%');

    // Finish button should be enabled, but not yet green (workout is 50% complete)
    final finishFinder =
        find.byKey(const ValueKey('active-workout-preview-finish'));
    expect(tester.widget<TioButton>(finishFinder).enabled, isTrue);

    // Now log Set 2: progress becomes 2/2 = 100%
    final toggle1 =
        find.byKey(const ValueKey('active-workout-preview-set-toggle-0-1'));
    await tester.tap(toggle1);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-preview-load-0-1')),
        matching: find.byType(EditableText),
      ),
      '50',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('active-workout-preview-reps-0-1')),
        matching: find.byType(EditableText),
      ),
      '10',
    );
    await tester.pumpAndSettle();
    await tester.tap(toggle1);
    await tester.pumpAndSettle();

    semantics = tester.getSemantics(
        find.byKey(const ValueKey('active-workout-progress-bar')));
    expect(semantics.value, '100%');

    // When 100% complete, Finish button's theme has green background (0xFF43A047)
    final themeFinder = find.ancestor(
      of: finishFinder,
      matching: find.byType(Theme),
    );
    final theme = tester.widget<Theme>(themeFinder.first);
    expect(
      theme.data.filledButtonTheme.style?.backgroundColor?.resolve({}),
      tester.element(finishFinder).tioColors.success,
    );

    await tester.tap(finishFinder);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('active-workout-start-preview')),
        findsOneWidget);
    expect(find.textContaining('This preview is not a saved workout'),
        findsOneWidget);
  });
}
