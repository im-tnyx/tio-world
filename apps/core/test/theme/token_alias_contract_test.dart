import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('foundation token contracts', () {
    test('spacing scale keeps the approved rhythm', () {
      expect(TioSpacing.extraSmall, 4.0);
      expect(TioSpacing.small, 8.0);
      expect(TioSpacing.medium, 12.0);
      expect(TioSpacing.large, 16.0);
      expect(TioSpacing.extraLarge, 24.0);
    });
  });

  group('component token foundation aliases', () {
    test('spacing aliases stay aligned with foundation semantics', () {
      expect(TioButtonTokens.contentGap, TioSpacing.small);
      expect(TioCardTokens.padding, TioSpacing.large);
      expect(TioInputTokens.horizontalPadding, TioSpacing.large);
      expect(TioSheetTokens.padding, TioSpacing.large);
      expect(TioSheetTokens.titleGap, TioSpacing.medium);
    });

    test('radius aliases stay aligned with foundation semantics', () {
      expect(TioButtonTokens.radius, TioRadius.full);
      expect(TioCardTokens.radius, TioRadius.large);
      expect(TioCardTokens.radiusItem, TioRadius.small);
      expect(TioNavigationTokens.itemRadius, TioRadius.large);
      expect(TioSheetTokens.radius, TioRadius.extraLarge);
    });

    test('component-owned values keep audited runtime contracts', () {
      expect(TioCardTokens.materialThemeRadius, 20.0);
      expect(TioCardTokens.materialThemeElevation, 0.0);
      expect(TioInputTokens.radius, 14.0);
      expect(TioNavigationTokens.labelTopPadding, 2.0);
    });
  });
}
