import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('retries a generated ProgramId that is already retained', () {
    final existing = ProgramId('00000000-0000-4000-8000-000000000001');
    var calls = 0;
    final generator = UuidProgramIdGenerator(
      uuidV4: () {
        calls++;
        return calls == 1
            ? existing.value
            : '00000000-0000-4000-8000-000000000002';
      },
    );

    expect(
      generator.generate([existing]),
      ProgramId('00000000-0000-4000-8000-000000000002'),
    );
    expect(calls, 2);
  });

  test('fails after the configured collision attempt limit', () {
    final existing = ProgramId('00000000-0000-4000-8000-000000000001');
    final generator = UuidProgramIdGenerator(
      uuidV4: () => existing.value,
      maxAttempts: 1,
    );

    expect(() => generator.generate([existing]), throwsStateError);
  });
}
