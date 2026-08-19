import '../primitive/tio_size.dart';

/// Reusable semantic spacing roles.
///
/// The scale is intentionally broader than the original five roles so new UI
/// can grow without inventing feature-local spacing catalogs. Exact one-off
/// geometry can still consume [TioSize] directly when no reusable spacing role
/// is justified.
class TioSpacing {
  const TioSpacing._();

  static const none = TioSize.dp0;
  static const xxs = TioSize.dp2;
  static const xs = TioSize.dp4;
  static const sm = TioSize.dp8;
  static const md = TioSize.dp12;
  static const lg = TioSize.dp16;
  static const xl = TioSize.dp24;
  static const xxl = TioSize.dp32;
}
