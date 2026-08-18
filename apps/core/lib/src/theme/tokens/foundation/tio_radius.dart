import '../primitive/tio_size.dart';

/// Reusable semantic radius roles.
///
/// Radius semantics are independent from spacing semantics even when both alias
/// the same physical [TioSize] value. Existing role names remain transitional
/// compatibility aliases so current UI geometry does not change during
/// migration.
class TioRadius {
  const TioRadius._();

  static const none = TioSize.dp0;
  static const xs = TioSize.dp4;
  static const sm = TioSize.dp8;
  static const md = TioSize.dp12;
  static const lg = TioSize.dp16;
  static const xl = TioSize.dp24;
  static const full = TioSize.dp999;

  // Transitional compatibility aliases.
  static const small = sm;
  static const medium = md;
  static const large = lg;
  static const extraLarge = xl;
}
