import '../primitive/tio_duration.dart';

/// Reusable semantic motion roles.
///
/// [TioDuration] owns the physical millisecond values. This class names the
/// reusable motion intents consumed by runtime motion schemes and components.
class TioMotion {
  const TioMotion._();

  static const fastMs = TioDuration.ms150;
  static const selectionMs = TioDuration.ms200;
  static const normalMs = TioDuration.ms250;
  static const slowMs = TioDuration.ms400;
  static const fadeThroughEnterMs = TioDuration.ms310;
  static const fadeThroughExitMs = TioDuration.ms90;
  static const progressMs = TioDuration.ms1200;
}
