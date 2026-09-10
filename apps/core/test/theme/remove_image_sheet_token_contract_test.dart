import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('Remove Image sheet visual contracts', () {
    test('keeps the audited sheet and action geometry', () {
      expect(TioRemoveImageSheetTokens.sheetRadius, TioRadius.xl);
      expect(TioRemoveImageSheetTokens.contentHorizontalPadding, 20.0);
      expect(TioRemoveImageSheetTokens.closeButtonSize, 32.0);
      expect(TioRemoveImageSheetTokens.closeIconSize, 18.0);
      expect(TioRemoveImageSheetTokens.removeIconSize, 20.0);
      expect(TioRemoveImageSheetTokens.cancelIconSize, 18.0);
    });

    test('keeps the audited typography and spacing', () {
      expect(TioRemoveImageSheetTokens.titleFontSize, 22.0);
      expect(TioRemoveImageSheetTokens.titleLetterSpacing, -0.3);
      expect(TioRemoveImageSheetTokens.subtitleFontSize, 15.0);
      expect(TioRemoveImageSheetTokens.subtitleToActionsGap, 26.0);
      // Action label size, radius and outline are no longer asserted here:
      // the Remove and Cancel actions are TioButtons, so TioButtonTokens
      // owns that contract now. Only the gap between them remains this
      // sheet's own layout.
      expect(TioRemoveImageSheetTokens.actionGap, TioSpacing.md);
    });
  });
}
