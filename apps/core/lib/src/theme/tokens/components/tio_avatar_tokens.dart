import '../primitive/tio_size.dart';

class TioAvatarTokens {
  const TioAvatarTokens._();

  // Reusable Avatar size contracts alias the canonical physical geometry
  // registry. Avatar owns the semantic roles; TioSize owns the numbers.
  static const compactSize = TioSize.dp24;
  static const smallSize = TioSize.dp36;
  static const mediumSize = TioSize.dp48;
  static const largeSize = TioSize.dp100;
  static const extraLargeSize = TioSize.dp160;

  static const roundedRadiusFactor = 0.28;

  static const plusRingWidth = 3.0;
  static const smallPlusRingWidth = 1.5;
  static const plusRingGap = 4.0;
  static const smallPlusRingGap = 2.0;

  static const proFrameWidth = 4.0;
  static const smallProFrameWidth = 1.5;
  static const smallProFramePadding = 2.0;

  static const iconSizeFactor = 0.5;
  static const textSizeFactor = 0.36;
}
