/// Pure Dart helper for water unit display conversions.
///
/// Canonical storage is always Int millilitres (ml).
/// Display units (L, ml, oz) are a presentation-layer concern.
///
/// oz factor: 0.033814 fl oz per ml (matches Android WaterTargetScreen reference).
///
/// This helper is onboarding-local infrastructure.
/// Migrate to the owning nutrition domain when that package grows a domain layer.
class WaterUnitConverter {
  const WaterUnitConverter._();

  /// Fluid ounces per millilitre.
  static const double ozPerMl = 0.033814;

  /// Convert ml to litres (precise float, not lossy int-rounding).
  static double mlToLitres(int ml) => ml / 1000.0;

  /// Convert ml to fluid ounces.
  static double mlToOz(int ml) => ml * ozPerMl;

  /// Convert litres to ml.
  static int litresToMl(double litres) => (litres * 1000).round();

  /// Convert fluid ounces to ml.
  static int ozToMl(double oz) => (oz / ozPerMl).round();

  /// Format a litre value for display: one decimal place (e.g. "2.5").
  static String formatLitres(int ml) => mlToLitres(ml).toStringAsFixed(1);

  /// Format an oz value for display: zero decimal places (e.g. "85").
  static String formatOz(int ml) => mlToOz(ml).toStringAsFixed(0);

  /// Format an ml value for display: zero decimal places (e.g. "2500").
  static String formatMl(int ml) => ml.toString();
}
