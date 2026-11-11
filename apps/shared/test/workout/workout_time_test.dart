import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 5, 10, 0, 0);
  final t1 = DateTime.utc(2026, 11, 5, 10, 10, 0); // +10 min
  final t2 = DateTime.utc(2026, 11, 5, 10, 15, 0); // +15 min (5 min pause)
  final t3 = DateTime.utc(2026, 11, 5, 10, 45, 0); // +45 min
  final t4 = DateTime.utc(2026, 11, 5, 10, 50, 0); // +50 min (5 min pause)
  final t5 = DateTime.utc(2026, 11, 5, 11, 0, 0); // +60 min finish

  group('WorkoutTime', () {
    test('enforces UTC timestamps', () {
      final local = DateTime(2026, 11, 5, 10, 0, 0);
      expect(
        () => WorkoutTime(startedAtUtc: local),
        throwsArgumentError,
      );
      expect(
        () => WorkoutTime(startedAtUtc: t0, pausedAtUtc: local),
        throwsArgumentError,
      );
      expect(
        () => WorkoutTime(startedAtUtc: t0, completedAtUtc: local),
        throwsArgumentError,
      );
      expect(
        () => WorkoutTime(startedAtUtc: t0, lastTransitionAtUtc: local),
        throwsArgumentError,
      );
    });

    test('enforces chronological monotonicity', () {
      final earlier = DateTime.utc(2026, 11, 5, 9, 59, 0);
      expect(
        () => WorkoutTime(startedAtUtc: t0, pausedAtUtc: earlier),
        throwsArgumentError,
      );
      expect(
        () => WorkoutTime(startedAtUtc: t0, completedAtUtc: earlier),
        throwsArgumentError,
      );
      expect(
        () => WorkoutTime(startedAtUtc: t0, lastTransitionAtUtc: earlier),
        throwsArgumentError,
      );
      expect(
        () => WorkoutTime(
          startedAtUtc: t0,
          pausedAtUtc: t1,
          completedAtUtc: t2,
        ),
        throwsArgumentError,
      );
    });

    test('accurately accounts for single pause and resume', () {
      final start = WorkoutTime.start(startedAtUtc: t0);
      expect(start.isPaused, isFalse);
      expect(start.isCompleted, isFalse);
      expect(start.lastTransitionAtUtc, t0);

      // Active for 10 minutes, then pause at t1
      final paused = start.pause(t1);
      expect(paused.isPaused, isTrue);
      expect(paused.pausedAtUtc, t1);
      expect(paused.lastTransitionAtUtc, t1);
      expect(paused.accumulatedPausedDuration, Duration.zero);

      // During pause (at t2 = +15 min), active duration is still 10 min
      expect(
        paused.elapsedActiveDuration(t2),
        const Duration(minutes: 10),
      );
      // Wall-clock total elapsed is 15 min
      expect(
        paused.totalElapsedDuration(t2),
        const Duration(minutes: 15),
      );

      // Resume at t2 (+15 min)
      final resumed = paused.resume(t2);
      expect(resumed.isPaused, isFalse);
      expect(resumed.pausedAtUtc, isNull);
      expect(resumed.lastTransitionAtUtc, t2);
      expect(
        resumed.accumulatedPausedDuration,
        const Duration(minutes: 5),
      );

      // At t3 (+45 min), active duration is 45 - 5 = 40 min
      expect(
        resumed.elapsedActiveDuration(t3),
        const Duration(minutes: 40),
      );
      expect(
        resumed.totalElapsedDuration(t3),
        const Duration(minutes: 45),
      );
    });

    test('accurately accounts for multiple pause intervals and finish', () {
      // t0: start
      // t1: pause (10m active)
      // t2: resume (5m pause)
      // t3: active until 45m
      // t4: pause (another 30m active, total active 40m)
      // t5: finish while paused at 60m (+10m pause, total pause 15m)
      final time = WorkoutTime.start(startedAtUtc: t0)
          .pause(t1)
          .resume(t2)
          .pause(t4)
          .finish(t5);

      expect(time.isCompleted, isTrue);
      expect(time.isPaused, isFalse);
      expect(time.completedAtUtc, t5);
      expect(time.lastTransitionAtUtc, t5);
      expect(
        time.accumulatedPausedDuration,
        const Duration(minutes: 15), // 5 min + 10 min
      );
      // Active duration = 60m - 15m = 45m
      expect(
        time.elapsedActiveDuration(t5),
        const Duration(minutes: 45),
      );
      // Wall-clock duration = 60m
      expect(
        time.totalElapsedDuration(t5),
        const Duration(minutes: 60),
      );
    });

    test('finish directly from active state', () {
      final time = WorkoutTime.start(startedAtUtc: t0).finish(t3);

      expect(time.isCompleted, isTrue);
      expect(time.isPaused, isFalse);
      expect(time.completedAtUtc, t3);
      expect(time.lastTransitionAtUtc, t3);
      expect(
        time.elapsedActiveDuration(t5), // evaluating at t5 returns completed duration
        const Duration(minutes: 45),
      );
      expect(
        time.totalElapsedDuration(t5),
        const Duration(minutes: 45),
      );
    });

    test('rejects illegal operations and backdated transitions after resume (Bugbot regression)', () {
      final active = WorkoutTime.start(startedAtUtc: t0);
      expect(() => active.resume(t1), throwsStateError);

      final paused = active.pause(t1);
      expect(() => paused.pause(t2), throwsStateError);

      // Non-monotonic resume before pause
      expect(
        () => paused.resume(DateTime.utc(2026, 11, 5, 10, 5, 0)),
        throwsArgumentError,
      );

      final resumed = paused.resume(t2); // Resumed at 10:15 (t2)

      // Regression: pause backdated before resume instant (e.g. 10:12) must be rejected
      final backdatedPause = DateTime.utc(2026, 11, 5, 10, 12, 0);
      expect(
        () => resumed.pause(backdatedPause),
        throwsArgumentError,
      );

      // Regression: finish backdated before resume instant (e.g. 10:12) must be rejected
      expect(
        () => resumed.finish(backdatedPause),
        throwsArgumentError,
      );

      // Regression: duration evaluation before resume instant must be rejected
      expect(
        () => resumed.elapsedActiveDuration(backdatedPause),
        throwsArgumentError,
      );

      final finished = resumed.finish(t3);
      expect(() => finished.pause(t4), throwsStateError);
      expect(() => finished.resume(t4), throwsStateError);
      expect(() => finished.finish(t4), throwsStateError);
    });

    test('direct constructor validates accumulatedPausedDuration against elapsed window', () {
      // accumulatedPausedDuration cannot exceed elapsed time to pause
      expect(
        () => WorkoutTime(
          startedAtUtc: t0,
          pausedAtUtc: t1, // 10 minutes elapsed
          accumulatedPausedDuration: const Duration(minutes: 15), // invalid!
        ),
        throwsArgumentError,
      );

      // accumulatedPausedDuration cannot exceed elapsed time to finish
      expect(
        () => WorkoutTime(
          startedAtUtc: t0,
          completedAtUtc: t1, // 10 minutes elapsed
          accumulatedPausedDuration: const Duration(minutes: 12), // invalid!
        ),
        throwsArgumentError,
      );

      // Active session with accumulated pause requires lastTransitionAtUtc >= start + pause
      expect(
        () => WorkoutTime(
          startedAtUtc: t0,
          accumulatedPausedDuration: const Duration(minutes: 20),
          lastTransitionAtUtc: t1, // 10 minutes elapsed, but pause was 20m!
        ),
        throwsArgumentError,
      );
    });

    test('direct constructor requires explicit lastTransitionAtUtc watermark for active resumed sessions (im-tio review regression)', () {
      // t0 = 10:00, t1 = 10:10 (pause), t2 = 10:15 (resume after 5m pause)
      const pausedDuration = Duration(minutes: 5);

      // Reconstructing active resumed session without lastTransitionAtUtc must be rejected
      expect(
        () => WorkoutTime(
          startedAtUtc: t0,
          accumulatedPausedDuration: pausedDuration,
        ),
        throwsArgumentError,
      );

      // Reconstruction with the actual 10:15 watermark succeeds
      final reconstructed = WorkoutTime(
        startedAtUtc: t0,
        accumulatedPausedDuration: pausedDuration,
        lastTransitionAtUtc: t2,
      );
      expect(reconstructed.startedAtUtc, t0);
      expect(reconstructed.pausedAtUtc, isNull);
      expect(reconstructed.accumulatedPausedDuration, pausedDuration);
      expect(reconstructed.completedAtUtc, isNull);
      expect(reconstructed.lastTransitionAtUtc, t2);
      expect(reconstructed.isPaused, isFalse);
      expect(reconstructed.isCompleted, isFalse);

      // Backdated pause at 10:12 is rejected
      final backdated = DateTime.utc(2026, 11, 5, 10, 12, 0);
      expect(() => reconstructed.pause(backdated), throwsArgumentError);

      // Backdated finish at 10:12 is rejected
      expect(() => reconstructed.finish(backdated), throwsArgumentError);

      // Backdated active-duration evaluation at 10:12 is rejected
      expect(
        () => reconstructed.elapsedActiveDuration(backdated),
        throwsArgumentError,
      );
      expect(
        () => reconstructed.totalElapsedDuration(backdated),
        throwsArgumentError,
      );

      // Subsequent valid pause at 10:20 succeeds
      final subsequentPause = DateTime.utc(2026, 11, 5, 10, 20, 0);
      final pausedAgain = reconstructed.pause(subsequentPause);
      expect(pausedAgain.isPaused, isTrue);
      expect(pausedAgain.pausedAtUtc, subsequentPause);
      expect(pausedAgain.lastTransitionAtUtc, subsequentPause);

      // Fresh start with zero paused duration does not require lastTransitionAtUtc
      final fresh = WorkoutTime(startedAtUtc: t0);
      expect(fresh.lastTransitionAtUtc, t0);

      // Currently paused session resolves lastTransitionAtUtc to pausedAtUtc if omitted
      final pausedSession = WorkoutTime(
        startedAtUtc: t0,
        pausedAtUtc: t1,
        accumulatedPausedDuration: pausedDuration,
      );
      expect(pausedSession.lastTransitionAtUtc, t1);

      // Completed session resolves lastTransitionAtUtc to completedAtUtc if omitted
      final completedSession = WorkoutTime(
        startedAtUtc: t0,
        completedAtUtc: t5,
        accumulatedPausedDuration: pausedDuration,
      );
      expect(completedSession.lastTransitionAtUtc, t5);
    });

    test('implements value equality', () {
      final a = WorkoutTime(
        startedAtUtc: t0,
        pausedAtUtc: t1,
        accumulatedPausedDuration: const Duration(minutes: 5),
        lastTransitionAtUtc: t1,
      );
      final b = WorkoutTime(
        startedAtUtc: t0,
        pausedAtUtc: t1,
        accumulatedPausedDuration: const Duration(minutes: 5),
        lastTransitionAtUtc: t1,
      );
      final c = WorkoutTime(
        startedAtUtc: t0,
        pausedAtUtc: t2,
        accumulatedPausedDuration: const Duration(minutes: 5),
        lastTransitionAtUtc: t2,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
