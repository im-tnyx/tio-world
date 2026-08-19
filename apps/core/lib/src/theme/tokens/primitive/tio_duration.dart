/// Canonical fixed-duration values used by the Tio design system.
///
/// This primitive owns physical millisecond values. Semantic motion roles must
/// alias these values instead of redefining timings independently.
abstract final class TioDuration {
  static const ms90 = 90;
  static const ms150 = 150;
  static const ms180 = 180;
  static const ms200 = 200;
  static const ms250 = 250;
  static const ms310 = 310;
  static const ms400 = 400;
  static const ms1200 = 1200;
  static const ms3600 = 3600;
}
