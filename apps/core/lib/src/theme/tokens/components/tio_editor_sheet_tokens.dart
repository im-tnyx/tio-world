import '../foundation/tio_radius.dart';
import '../foundation/tio_spacing.dart';
import '../primitive/tio_size.dart';

/// Geometry for [TioEditorSheet], the editable modal surface.
///
/// Deliberately separate from `TioSheetTokens`: the display sheet and the
/// editor sheet are different surfaces with different roles, and collapsing
/// them into one token bag would force one to drift toward the other.
///
/// Values are carried over unchanged from the two feature-local shells this
/// component replaces, so the migration is pixel-preserving. The single
/// exception is [actionGap] — see the note there.
class TioEditorSheetTokens {
  const TioEditorSheetTokens._();

  /// Top corner radius. Note this is `lg`, not `TioSheetTokens.radius` (`xl`):
  /// the editor family has always been the tighter of the two.
  static const radius = TioRadius.lg;

  static const padding = TioSpacing.lg;

  /// Gap between the drag handle and the header.
  static const handleGap = TioSpacing.md;

  /// Gap between the header block and the content.
  static const headerGap = TioSpacing.lg;

  /// Gap used instead of [headerGap] when a title trailing affordance is
  /// present. Such a row is a 48dp minimum tap target, so it is ~22dp taller
  /// than a plain title and already contributes space below the title text.
  /// Compensating here lands both header variants at the same optical gap.
  static const headerGapWithTrailing = TioSpacing.xs;

  /// Gap between the content and the pinned action region.
  ///
  /// The commit action is a distinct step from the input above it. Sitting
  /// flush under the content reads as part of it and invites a mistap, so it
  /// gets more room than the sheet's internal spacing.
  static const actionGap = TioSpacing.xl;

  static const handleWidth = TioSize.dp36;
  static const handleHeight = TioSize.dp4;
  static const handleRadius = TioSize.dp2;
  static const handlePadding = TioSpacing.xs;

  /// Vertical drag distance past which the handle dismisses the sheet.
  static const handleDismissThreshold = TioSize.dp36;
}
