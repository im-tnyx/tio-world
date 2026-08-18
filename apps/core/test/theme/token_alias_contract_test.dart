import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('component token foundation aliases', () {
    test('spacing aliases stay aligned with foundation semantics', () {
      expect(TioButtonTokens.contentGap, TioSpacing.small);
      expect(TioCardTokens.padding, TioSpacing.large);
      expect(TioSheetTokens.padding, TioSpacing.extraLarge);
    });

    test('radius aliases stay aligned with foundation semantics', () {
      expect(TioButtonTokens.radius, TioRadius.full);
      expect(TioCardTokens.radius, TioRadius.large);
      expect(TioCardTokens.radiusItem, TioRadius.small);
      expect(TioNavigationTokens.itemRadius, TioRadius.large);
    });
  });
}
