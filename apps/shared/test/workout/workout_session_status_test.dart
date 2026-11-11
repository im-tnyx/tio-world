import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('WorkoutSessionStatus', () {
    test('identifies terminal states correctly', () {
      expect(WorkoutSessionStatus.active.isTerminal, isFalse);
      expect(WorkoutSessionStatus.paused.isTerminal, isFalse);
      expect(WorkoutSessionStatus.completed.isTerminal, isTrue);
      expect(WorkoutSessionStatus.discarded.isTerminal, isTrue);
    });

    test('permits legal transitions', () {
      // From active
      expect(
        WorkoutSessionStatus.active.canTransitionTo(WorkoutSessionStatus.paused),
        isTrue,
      );
      expect(
        WorkoutSessionStatus.active
            .canTransitionTo(WorkoutSessionStatus.completed),
        isTrue,
      );
      expect(
        WorkoutSessionStatus.active
            .canTransitionTo(WorkoutSessionStatus.discarded),
        isTrue,
      );
      expect(
        WorkoutSessionStatus.active.canTransitionTo(WorkoutSessionStatus.active),
        isFalse,
      );

      // From paused
      expect(
        WorkoutSessionStatus.paused.canTransitionTo(WorkoutSessionStatus.active),
        isTrue,
      );
      expect(
        WorkoutSessionStatus.paused
            .canTransitionTo(WorkoutSessionStatus.completed),
        isTrue,
      );
      expect(
        WorkoutSessionStatus.paused
            .canTransitionTo(WorkoutSessionStatus.discarded),
        isTrue,
      );
      expect(
        WorkoutSessionStatus.paused.canTransitionTo(WorkoutSessionStatus.paused),
        isFalse,
      );
    });

    test('prohibits any transition from terminal states', () {
      for (final terminal in [
        WorkoutSessionStatus.completed,
        WorkoutSessionStatus.discarded,
      ]) {
        for (final target in WorkoutSessionStatus.values) {
          expect(
            terminal.canTransitionTo(target),
            isFalse,
            reason: '${terminal.name} -> ${target.name}',
          );
        }
      }
    });

    test('fromWire parses canonical tokens', () {
      expect(
        WorkoutSessionStatus.fromWire('active'),
        WorkoutSessionStatus.active,
      );
      expect(
        WorkoutSessionStatus.fromWire('paused'),
        WorkoutSessionStatus.paused,
      );
      expect(
        WorkoutSessionStatus.fromWire('completed'),
        WorkoutSessionStatus.completed,
      );
      expect(
        WorkoutSessionStatus.fromWire('discarded'),
        WorkoutSessionStatus.discarded,
      );
      expect(
        () => WorkoutSessionStatus.fromWire('unknown'),
        throwsArgumentError,
      );
    });
  });
}
