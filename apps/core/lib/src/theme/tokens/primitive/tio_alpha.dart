/// Canonical exact 0–255 alpha values used by the Tio design system.
///
/// Keep these integer contracts separate from normalized opacity values so
/// APIs such as Color.withAlpha and exact ARGB palette primitives can preserve
/// current rendering without introducing rounding during ownership migration.
abstract final class TioAlpha {
  static const alpha25 = 25;
  static const alpha26 = 26;
  static const alpha30 = 30;
  static const alpha35 = 35;
  static const alpha40 = 40;
  static const alpha50 = 50;
  static const alpha80 = 80;
  static const alpha90 = 90;
  static const alpha120 = 120;
  static const alpha200 = 200;
  static const alpha245 = 245;
}
