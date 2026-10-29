import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/src/domain/models/routine_rest_timer_preset.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('RoutineRestTimerPreset', () {
    test('both OFF produces isOff true and null for all set types', () {
      const preset = RoutineRestTimerPreset();
      expect(preset.isOff, isTrue);
      expect(preset.normalRestSeconds, isNull);
      expect(preset.warmUpRestSeconds, isNull);

      expect(preset.effectiveRestFor(RoutineSetType.warmUp), isNull);
      expect(preset.effectiveRestFor(RoutineSetType.normal), isNull);
      expect(preset.effectiveRestFor(RoutineSetType.failure), isNull);
      expect(preset.effectiveRestFor(RoutineSetType.drop), isNull);
    });

    test('Normal ON and Warm-up OFF: Warm-up falls back to Normal', () {
      const preset = RoutineRestTimerPreset(normalRestSeconds: 90);
      expect(preset.isOff, isFalse);
      expect(preset.normalRestSeconds, 90);
      expect(preset.warmUpRestSeconds, isNull);

      // Warm-up falls back to Normal
      expect(preset.effectiveRestFor(RoutineSetType.warmUp), 90);
      // Non-warm-up types use Normal
      expect(preset.effectiveRestFor(RoutineSetType.normal), 90);
      expect(preset.effectiveRestFor(RoutineSetType.failure), 90);
      expect(preset.effectiveRestFor(RoutineSetType.drop), 90);
    });

    test('Normal OFF and Warm-up ON: only Warm-up has active rest', () {
      const preset = RoutineRestTimerPreset(warmUpRestSeconds: 45);
      expect(preset.isOff, isFalse);
      expect(preset.normalRestSeconds, isNull);
      expect(preset.warmUpRestSeconds, 45);

      expect(preset.effectiveRestFor(RoutineSetType.warmUp), 45);
      expect(preset.effectiveRestFor(RoutineSetType.normal), isNull);
      expect(preset.effectiveRestFor(RoutineSetType.failure), isNull);
      expect(preset.effectiveRestFor(RoutineSetType.drop), isNull);
    });

    test('Both ON: Warm-up uses warm-up, non-warm-up use normal', () {
      const preset = RoutineRestTimerPreset(
        normalRestSeconds: 90,
        warmUpRestSeconds: 45,
      );
      expect(preset.isOff, isFalse);
      expect(preset.normalRestSeconds, 90);
      expect(preset.warmUpRestSeconds, 45);

      expect(preset.effectiveRestFor(RoutineSetType.warmUp), 45);
      expect(preset.effectiveRestFor(RoutineSetType.normal), 90);
      expect(preset.effectiveRestFor(RoutineSetType.failure), 90);
      expect(preset.effectiveRestFor(RoutineSetType.drop), 90);
    });

    test('supports explicit 0 seconds distinct from null', () {
      const preset = RoutineRestTimerPreset(normalRestSeconds: 0);
      expect(preset.isOff, isFalse);
      expect(preset.normalRestSeconds, 0);
      expect(preset.warmUpRestSeconds, isNull);

      // Warm-up falls back to 0
      expect(preset.effectiveRestFor(RoutineSetType.warmUp), 0);
      expect(preset.effectiveRestFor(RoutineSetType.normal), 0);
      expect(preset.effectiveRestFor(RoutineSetType.failure), 0);
      expect(preset.effectiveRestFor(RoutineSetType.drop), 0);
    });

    test('equality and hashCode contract', () {
      const a = RoutineRestTimerPreset(normalRestSeconds: 60, warmUpRestSeconds: 30);
      const b = RoutineRestTimerPreset(normalRestSeconds: 60, warmUpRestSeconds: 30);
      const c = RoutineRestTimerPreset(normalRestSeconds: 60);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('RoutineRestTimerFormatter', () {
    test('formatSeconds formats seconds correctly', () {
      expect(RoutineRestTimerFormatter.formatSeconds(0), '0s');
      expect(RoutineRestTimerFormatter.formatSeconds(5), '5s');
      expect(RoutineRestTimerFormatter.formatSeconds(45), '45s');
      expect(RoutineRestTimerFormatter.formatSeconds(60), '1min');
      expect(RoutineRestTimerFormatter.formatSeconds(75), '1min 15s');
      expect(RoutineRestTimerFormatter.formatSeconds(90), '1min 30s');
      expect(RoutineRestTimerFormatter.formatSeconds(120), '2min');
      expect(RoutineRestTimerFormatter.formatSeconds(150), '2min 30s');
      expect(RoutineRestTimerFormatter.formatSeconds(300), '5min');
    });

    test('formatWheelItem formats 5s wheel intervals correctly', () {
      expect(RoutineRestTimerFormatter.formatWheelItem(0), 'Off');
      expect(RoutineRestTimerFormatter.formatWheelItem(1), '5s');
      expect(RoutineRestTimerFormatter.formatWheelItem(2), '10s');
      expect(RoutineRestTimerFormatter.formatWheelItem(11), '55s');
      expect(RoutineRestTimerFormatter.formatWheelItem(12), '1m 0s');
      expect(RoutineRestTimerFormatter.formatWheelItem(13), '1m 5s');
      expect(RoutineRestTimerFormatter.formatWheelItem(18), '1m 30s');
      expect(RoutineRestTimerFormatter.formatWheelItem(59), '4m 55s');
      expect(RoutineRestTimerFormatter.formatWheelItem(60), '5m 0s');
      expect(RoutineRestTimerFormatter.formatWheelItem(120), '10m 0s');
    });

    test('formatSummary covers all 4 combinations and matches reference style', () {
      // 1. Both OFF
      expect(
        RoutineRestTimerFormatter.formatSummary(
          normalSeconds: null,
          warmUpSeconds: null,
        ),
        'Rest: OFF',
      );

      // 2. Normal only
      expect(
        RoutineRestTimerFormatter.formatSummary(
          normalSeconds: 90,
          warmUpSeconds: null,
        ),
        'Rest: 1min 30s',
      );

      // 3. Warm-up only
      expect(
        RoutineRestTimerFormatter.formatSummary(
          normalSeconds: null,
          warmUpSeconds: 45,
        ),
        'Rest: (45s)',
      );

      // 4. Both active
      expect(
        RoutineRestTimerFormatter.formatSummary(
          normalSeconds: 90,
          warmUpSeconds: 45,
        ),
        'Rest: 1min 30s (45s)',
      );

      // Explicit 0 seconds
      expect(
        RoutineRestTimerFormatter.formatSummary(
          normalSeconds: 0,
          warmUpSeconds: null,
        ),
        'Rest: 0s',
      );
    });

    test('formatSemantics produces accessible category-specific labels', () {
      expect(
        RoutineRestTimerFormatter.formatSemantics(
          normalSeconds: null,
          warmUpSeconds: null,
        ),
        'Rest: OFF',
      );

      expect(
        RoutineRestTimerFormatter.formatSemantics(
          normalSeconds: 90,
          warmUpSeconds: null,
        ),
        'Rest: Normal set 1min 30s, Warm-up set OFF',
      );

      expect(
        RoutineRestTimerFormatter.formatSemantics(
          normalSeconds: null,
          warmUpSeconds: 45,
        ),
        'Rest: Normal set OFF, Warm-up set 45s',
      );

      expect(
        RoutineRestTimerFormatter.formatSemantics(
          normalSeconds: 90,
          warmUpSeconds: 45,
        ),
        'Rest: Normal set 1min 30s, Warm-up set 45s',
      );
    });
  });
}
