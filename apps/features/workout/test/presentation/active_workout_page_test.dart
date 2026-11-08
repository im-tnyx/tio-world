import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _userId = '11111111-1111-4111-a111-111111111111';
final _sessionId = WorkoutSessionId('22222222-2222-4222-a222-222222222222');
final _programId = ProgramId('33333333-3333-4333-a333-333333333333');
final _routineId = RoutineId('44444444-4444-4444-a444-444444444444');
final _exerciseRef = ExerciseRef.catalog('ex_barbell_bench_press');

final class _FakeSessionRepository implements WorkoutSessionRepository {
  WorkoutSessionRecord? active;
  Exception? restoreError;
  Exception? pauseError;
  Completer<WorkoutSessionRecord>? pauseCompleter;
  WorkoutSessionRecord? completeResult;
  var getActiveCalls = 0;

  @override
  Future<WorkoutSessionRecord?> getActiveSession() async {
    getActiveCalls++;
    final error = restoreError;
    if (error != null) throw error;
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
  }) async =>
      active!;

  @override
  Future<WorkoutSessionRecord> removePerformedSet({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required String setId,
  }) async =>
      active!;

  @override
  Future<WorkoutSessionRecord> completeSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime completedAtUtc,
    String? notes,
  }) async =>
      completeResult ?? active!;

  @override
  Future<WorkoutSessionRecord> discardSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime discardedAtUtc,
    required String reason,
  }) async =>
      active!;
}

WorkoutSessionSnapshot _snapshot() => WorkoutSessionSnapshot(
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
              restSeconds: 120,
            ),
          ],
        ),
      ],
    );

WorkoutSession _session({
  WorkoutSessionStatus status = WorkoutSessionStatus.active,
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
    snapshot: _snapshot(),
    discardReason:
        status == WorkoutSessionStatus.discarded ? 'Test discard' : null,
  );
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required ActiveWorkoutController controller,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: ActiveWorkoutPage(controller: controller),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
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

  testWidgets('offers explicit reconciliation retry', (tester) async {
    final repository = _FakeSessionRepository()
      ..restoreError = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'offline',
      );
    final controller = ActiveWorkoutController(
      repository: repository,
      currentUserId: () => _userId,
    );

    await _pumpPage(tester, controller: controller);
    expect(
      find.byKey(const ValueKey('active-workout-reconciliation')),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    repository
      ..restoreError = null
      ..active = WorkoutSessionRecord(session: _session(), revision: 1);
    await tester.tap(find.byKey(const ValueKey('active-workout-Retry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(repository.getActiveCalls, 2);
    expect(find.text('Push Day A'), findsOneWidget);
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
    await tester.tap(find.byKey(const ValueKey('active-workout-complete')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Finish workout'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.byKey(const ValueKey('active-workout-complete')), findsNothing);
    expect(find.byKey(const ValueKey('active-workout-pause-resume')),
        findsNothing);
    expect(find.text('Back to Workout'), findsOneWidget);
  });
}
