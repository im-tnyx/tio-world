import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('Shared wheel picker visual contracts', () {
    test('keeps audited cross-picker roles', () {
      expect(TioWheelPickerTokens.viewportHeight, 200.0);
      expect(TioWheelPickerTokens.selectionHeight, 48.0);
      expect(TioWheelPickerTokens.selectionHorizontalMargin, TioSpacing.large);
      expect(TioWheelPickerTokens.selectionSurfaceAlpha, 200);
      expect(TioWheelPickerTokens.itemExtent, 44.0);
      expect(TioWheelPickerTokens.selectedFontSize, 22.0);
    });

    test('DOB aliases shared roles without changing specialized treatment', () {
      expect(TioDobPickerTokens.wheelHeight, TioWheelPickerTokens.viewportHeight);
      expect(
        TioDobPickerTokens.selectionHeight,
        TioWheelPickerTokens.selectionHeight,
      );
      expect(TioDobPickerTokens.itemExtent, TioWheelPickerTokens.itemExtent);
      expect(
        TioDobPickerTokens.selectedFontSize,
        TioWheelPickerTokens.selectedFontSize,
      );
      expect(TioDobPickerTokens.perspective, 0.004);
      expect(TioDobPickerTokens.diameterRatio, 1.3);
      expect(TioDobPickerTokens.unselectedFontSize, 17.0);
      expect(TioDobPickerTokens.unselectedTextAlpha, 120);
    });
  });
}
