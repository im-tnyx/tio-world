import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical duration primitives', () {
    test('physical millisecond values remain exact', () {
      expect(TioDuration.ms90, 90);
      expect(TioDuration.ms150, 150);
      expect(TioDuration.ms250, 250);
      expect(TioDuration.ms310, 310);
      expect(TioDuration.ms400, 400);
      expect(TioDuration.ms1200, 1200);
    });

    test('semantic motion roles alias duration primitives', () {
      expect(TioMotion.fastMs, TioDuration.ms150);
      expect(TioMotion.normalMs, TioDuration.ms250);
      expect(TioMotion.slowMs, TioDuration.ms400);
      expect(TioMotion.fadeThroughEnterMs, TioDuration.ms310);
      expect(TioMotion.fadeThroughExitMs, TioDuration.ms90);
      expect(TioMotion.progressMs, TioDuration.ms1200);
    });
  });

  group('runtime motion scheme', () {
    test('standard scheme preserves audited timings', () {
      const motion = TioMotionScheme.standard();

      expect(motion.reducedMotion, isFalse);
      expect(motion.fast, const Duration(milliseconds: TioDuration.ms150));
      expect(motion.normal, const Duration(milliseconds: TioDuration.ms250));
      expect(motion.slow, const Duration(milliseconds: TioDuration.ms400));
      expect(
        motion.fadeThroughEnter,
        const Duration(milliseconds: TioDuration.ms310),
      );
      expect(
        motion.fadeThroughExit,
        const Duration(milliseconds: TioDuration.ms90),
      );
      expect(
        motion.progress,
        const Duration(milliseconds: TioDuration.ms1200),
      );
    });

    test('reduced scheme resolves every animation duration to zero', () {
      const motion = TioMotionScheme.reduced();

      expect(motion.reducedMotion, isTrue);
      expect(motion.fast, Duration.zero);
      expect(motion.normal, Duration.zero);
      expect(motion.slow, Duration.zero);
      expect(motion.fadeThroughEnter, Duration.zero);
      expect(motion.fadeThroughExit, Duration.zero);
      expect(motion.progress, Duration.zero);
    });
  });
}
