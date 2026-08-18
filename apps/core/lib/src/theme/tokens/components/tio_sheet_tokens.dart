import '../foundation/tio_radius.dart';
import '../foundation/tio_spacing.dart';

class TioSheetTokens {
  const TioSheetTokens._();

  // Audited against the current TioSheet runtime contract. Keep these values
  // pixel-preserving unless a separate visual-design decision changes them.
  static const radius = TioRadius.extraLarge;
  static const padding = TioSpacing.large;
  static const titleGap = TioSpacing.medium;
}
