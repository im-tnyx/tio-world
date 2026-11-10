import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  group('resolveWorkoutTitle', () {
    final cases = <(DateTime, String)>[
      (DateTime(2024, 1, 1, 4, 59), 'Night Workout'),
      (DateTime(2024, 1, 1, 5), 'Morning Workout'),
      (DateTime(2024, 1, 1, 11, 59), 'Morning Workout'),
      (DateTime(2024, 1, 1, 12), 'Afternoon Workout'),
      (DateTime(2024, 1, 1, 16, 59), 'Afternoon Workout'),
      (DateTime(2024, 1, 1, 17), 'Evening Workout'),
      (DateTime(2024, 1, 1, 20, 59), 'Evening Workout'),
      (DateTime(2024, 1, 1, 21), 'Night Workout'),
      (DateTime(2024, 1, 1), 'Night Workout'),
    ];

    for (final (dateTime, expected) in cases) {
      test('$dateTime resolves to $expected', () {
        expect(
          resolveWorkoutTitle(
            customTitle: null,
            selectedLocalDateTime: dateTime,
          ),
          expected,
        );
      });
    }

    test('custom title is only trimmed at the edges', () {
      expect(
        resolveWorkoutTitle(
          customTitle: '  Upper  Body\nWorkout  ',
          selectedLocalDateTime: DateTime(2024, 1, 1, 22),
        ),
        'Upper  Body\nWorkout',
      );
    });

    test('whitespace-only custom title uses the selected local hour', () {
      expect(
        resolveWorkoutTitle(
          customTitle: ' \t\n ',
          selectedLocalDateTime: DateTime(2019, 8, 2, 12),
        ),
        'Afternoon Workout',
      );
    });
  });
}
