import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  test('TrainingDays parse only supported source-grounded IDs', () {
    expect(
      WorkoutTrainingDay.fromStorageValue('monday'),
      WorkoutTrainingDay.monday,
    );
    expect(
      WorkoutTrainingDay.fromStorageValue('sunday'),
      WorkoutTrainingDay.sunday,
    );
    expect(WorkoutTrainingDay.fromStorageValue('mon'), isNull);
  });

  test('WorkoutDuration parse only supported source-grounded IDs', () {
    expect(
      WorkoutDuration.fromStorageValue('auto'),
      WorkoutDuration.auto,
    );
    expect(
      WorkoutDuration.fromStorageValue('120_min'),
      WorkoutDuration.oneHundredTwentyMinutes,
    );
    expect(WorkoutDuration.fromStorageValue('45_min'), isNull);
  });

  test('WorkoutSplit parse only supported source-grounded IDs', () {
    expect(
      WorkoutSplit.fromStorageValue('auto'),
      WorkoutSplit.auto,
    );
    expect(
      WorkoutSplit.fromStorageValue('upper_lower'),
      WorkoutSplit.upperLower,
    );
    expect(WorkoutSplit.fromStorageValue('bro_split'), isNull);
  });
}
