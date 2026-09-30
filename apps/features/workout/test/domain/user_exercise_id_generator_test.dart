import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('UUID generator skips existing user Exercise identities', () {
    final existing = UserCreatedExerciseRef(
      '00000000-0000-4000-8000-000000000001',
    );
    final generator = UuidUserExerciseIdGenerator(
      uuidV4: _QueueUuid([
        existing.value,
        '00000000-0000-4000-8000-000000000002',
      ]).next,
    );

    final generated = generator.generate([existing]);

    expect(
      generated,
      UserCreatedExerciseRef('00000000-0000-4000-8000-000000000002'),
    );
  });

  test('UUID generator rejects non-positive maxAttempts', () {
    expect(
      () => UuidUserExerciseIdGenerator(maxAttempts: 0),
      throwsArgumentError,
    );
  });

  test('UUID generator fails after exhausting collision attempts', () {
    final existing = UserCreatedExerciseRef(
      '00000000-0000-4000-8000-000000000001',
    );
    final generator = UuidUserExerciseIdGenerator(
      uuidV4: () => existing.value,
      maxAttempts: 2,
    );

    expect(
      () => generator.generate([existing]),
      throwsA(isA<StateError>()),
    );
  });
}

final class _QueueUuid {
  _QueueUuid(this.values);

  final List<String> values;
  var index = 0;

  String next() => values[index++];
}