import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('Shared wheel picker visual contracts', () {
    test('keeps audited cross-picker roles', () {
      expect(TioWheelPickerTokens.viewportHeight, 200.0);
      expect(TioWheelPickerTokens.selectionHeight, 48.0);
      expect(TioWheelPickerTokens.selectionHorizontalMargin, TioSpacing.lg);
      expect(TioWheelPickerTokens.selectionSurfaceAlpha, 200);
      expect(TioWheelPickerTokens.itemExtent, 44.0);
      expect(TioWheelPickerTokens.selectedFontSize, 22.0);
    });
  });
}
