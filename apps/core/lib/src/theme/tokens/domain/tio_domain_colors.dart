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
}
