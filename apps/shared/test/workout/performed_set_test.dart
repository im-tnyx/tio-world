import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const uuid = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';
  final exRef = ExerciseRef.catalog('ex_barbell_bench_press');

  group('PerformedSet', () {
    test('accepts valid performed set values and normalizes UUID to lowercase', () {
      final set = PerformedSet(
        id: uuid.toUpperCase(),
        exerciseRef: exRef,
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
        loadKg: 80.5,
        durationSeconds: 45,
        distanceMeters: 0,
        completedAtUtc: DateTime.utc(2026, 11, 5, 10, 30, 0),
        notes: ' Clean lockout ',
      );

      expect(set.id, uuid);
      expect(set.reps, 10);
      expect(set.loadKg, 80.5);
      expect(set.durationSeconds, 45);
      expect(set.distanceMeters, 0.0);
      expect(set.isSkipped, isFalse);
      expect(set.notes, 'Clean lockout');
      expect(set.completedAtUtc, DateTime.utc(2026, 11, 5, 10, 30, 0));
    });

    test('rejects non-canonical or malformed UUIDs', () {
      for (final badId in ['', '  ', 'not-a-uuid', '3f2c8e4a-9b1d-4c7e-8a5f']) {
        expect(
          () => PerformedSet(
            id: badId,
            exerciseRef: exRef,
            sessionExerciseIndex: 0,
            setIndex: 0,
          ),
          throwsArgumentError,
          reason: badId,
        );
      }
    });

    test('rejects negative indices and values', () {
      expect(
        () => PerformedSet(
          id: uuid,
          exerciseRef: exRef,
          sessionExerciseIndex: -1,
          setIndex: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => PerformedSet(
          id: uuid,
          exerciseRef: exRef,
          sessionExerciseIndex: 0,
          setIndex: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => PerformedSet(
          id: uuid,
          exerciseRef: exRef,
          sessionExerciseIndex: 0,
          setIndex: 0,
          reps: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => PerformedSet(
          id: uuid,
          exerciseRef: exRef,
          sessionExerciseIndex: 0,
          setIndex: 0,
          loadKg: -5.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => PerformedSet(
          id: uuid,
          exerciseRef: exRef,
          sessionExerciseIndex: 0,
          setIndex: 0,
          durationSeconds: -10,
        ),
        throwsArgumentError,
      );
      expect(
        () => PerformedSet(
          id: uuid,
          exerciseRef: exRef,
          sessionExerciseIndex: 0,
          setIndex: 0,
          distanceMeters: -100.0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-UTC completedAtUtc', () {
      final local = DateTime(2026, 11, 5, 10, 0, 0);
      expect(
        () => PerformedSet(
          id: uuid,
          exerciseRef: exRef,
          sessionExerciseIndex: 0,
          setIndex: 0,
          completedAtUtc: local,
        ),
        throwsArgumentError,
      );
    });

    test('distinguishes repeated Exercise references via sessionExerciseIndex', () {
      final set1 = PerformedSet(
        id: '01920f3e-7c4a-7b2d-9e1f-2a3b4c5d6e7f',
        exerciseRef: exRef,
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
        loadKg: 60,
      );
      final set2 = PerformedSet(
        id: 'c232ab00-9414-11ec-b3c8-9f6bdeced846',
        exerciseRef: exRef,
        sessionExerciseIndex: 2, // Second occurrence of the same exercise in the routine
        setIndex: 0,
        reps: 8,
        loadKg: 60,
      );

      expect(set1.exerciseRef, set2.exerciseRef);
      expect(set1.sessionExerciseIndex, 0);
      expect(set2.sessionExerciseIndex, 2);
      expect(set1, isNot(set2));
    });

    test('implements value equality', () {
      final a = PerformedSet(
        id: uuid,
        exerciseRef: exRef,
        sessionExerciseIndex: 0,
        setIndex: 1,
        reps: 12,
        loadKg: 50,
      );
      final b = PerformedSet(
        id: uuid,
        exerciseRef: exRef,
        sessionExerciseIndex: 0,
        setIndex: 1,
        reps: 12,
        loadKg: 50,
      );
      final c = PerformedSet(
        id: uuid,
        exerciseRef: exRef,
        sessionExerciseIndex: 0,
        setIndex: 1,
        reps: 10, // different reps
        loadKg: 50,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
