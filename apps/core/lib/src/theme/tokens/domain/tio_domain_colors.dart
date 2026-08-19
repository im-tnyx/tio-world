import '../foundation/tio_palette.dart';

/// Compatibility domain color roles backed by the canonical physical palette.
///
/// Theme-dependent domain presentation should prefer the resolved TioColors
/// roles. These static roles retain existing exact light/default contracts
/// without independently owning raw ARGB values.
class TioDomainColors {
  const TioDomainColors._();

  static const workout = TioPalette.red500;
  static const nutrition = TioPalette.green500;
  static const progress = TioPalette.violet500;
  static const coach = TioPalette.cyan500;
  static const recovery = TioPalette.sky400;

  // Exact health-analysis colors used by current onboarding status surfaces.
  static const healthInfo = TioPalette.sky400;
  static const healthPositive = TioPalette.green400;
  static const healthWarning = TioPalette.amber400;
  static const healthDanger = TioPalette.red400;

  // Exact celebratory accent colors used by confetti/media celebrations.
  static const celebrationGoldPrimary = TioPalette.gold400;
  static const celebrationGoldSecondary = TioPalette.amber600;
  static const celebrationWarmAccent = TioPalette.orange500;
  static const celebrationGoldHighlight = TioPalette.amber300;
  static const celebrationGoldMetallic = TioPalette.gold500;
}
