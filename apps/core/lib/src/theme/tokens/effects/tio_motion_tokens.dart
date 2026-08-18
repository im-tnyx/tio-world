import 'tio_motion.dart';

/// Transitional compatibility facade for the original motion-token API.
///
/// New code should use [TioMotion] semantic roles or the runtime
/// [TioMotionScheme]. This facade must not own physical duration values.
class TioMotionTokens {
  const TioMotionTokens._();

  static const fastMs = TioMotion.fastMs;
  static const normalMs = TioMotion.normalMs;
  static const slowMs = TioMotion.slowMs;
}
