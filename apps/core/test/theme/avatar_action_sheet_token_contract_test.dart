import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('Avatar Action sheet visual contracts', () {
    test('keeps the audited sheet and drag-handle geometry', () {
      expect(TioAvatarActionSheetTokens.sheetRadius, TioRadius.lg);
      expect(TioAvatarActionSheetTokens.dragHandleWidth, 36.0);
      expect(TioAvatarActionSheetTokens.dragHandleHeight, 4.0);
      expect(TioAvatarActionSheetTokens.dragHandleAlpha, 50);
      expect(TioAvatarActionSheetTokens.dragHandleRadius, 2.0);
    });

    test('keeps the audited title and option presentation', () {
      expect(TioAvatarActionSheetTokens.titleFontSize, 18.0);
      expect(TioAvatarActionSheetTokens.handleToTitleGap, TioSpacing.lg);
      expect(TioAvatarActionSheetTokens.titleToOptionsGap, TioSpacing.md);
      expect(TioAvatarActionSheetTokens.optionIconPadding, TioSpacing.sm);
      expect(TioAvatarActionSheetTokens.optionIconSize, 20.0);
    });
  });
}
