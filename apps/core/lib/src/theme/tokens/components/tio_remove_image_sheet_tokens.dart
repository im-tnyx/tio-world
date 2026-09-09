import '../foundation/tio_radius.dart';
import '../foundation/tio_spacing.dart';
import '../primitive/tio_size.dart';
import '../typography/tio_font_size.dart';
import '../typography/tio_letter_spacing.dart';

/// Shell, copy and icon geometry for the remove-image confirmation sheet.
///
/// Action chrome is deliberately absent: the Remove and Cancel actions are
/// [TioButton]s, so their height, radius, outline, padding and label
/// typography belong to `TioButtonTokens`. Only the two icon sizes remain
/// here, because they are this sheet's content rather than button chrome.
class TioRemoveImageSheetTokens {
  const TioRemoveImageSheetTokens._();

  static const sheetRadius = TioRadius.xl;
  static const contentHorizontalPadding = TioSize.dp20;
  static const contentTopPadding = TioSpacing.lg;
  static const contentBottomPadding = TioSpacing.xl;
  static const closeButtonSize = TioSize.dp32;
  static const closeIconSize = TioSize.dp18;
  static const closeToTitleGap = TioSize.dp6;
  static const titleFontSize = TioFontSize.size22;
  static const titleLetterSpacing = TioLetterSpacing.negative03;
  static const titleToSubtitleGap = TioSpacing.sm;
  static const subtitleFontSize = TioFontSize.size15;
  static const subtitleToActionsGap = TioSize.dp26;
  static const removeIconSize = TioSize.dp20;
  static const cancelIconSize = TioSize.dp18;
  static const actionGap = TioSpacing.md;
}
