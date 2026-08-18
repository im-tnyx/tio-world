import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical geometry primitives', () {
    test('foundation physical values remain pixel-exact', () {
      expect(TioSize.dp4, 4.0);
      expect(TioSize.dp8, 8.0);
      expect(TioSize.dp12, 12.0);
      expect(TioSize.dp16, 16.0);
      expect(TioSize.dp24, 24.0);
      expect(TioSize.dp999, 999.0);
    });

    test('spacing roles alias canonical geometry primitives', () {
      expect(TioSpacing.extraSmall, TioSize.dp4);
      expect(TioSpacing.small, TioSize.dp8);
      expect(TioSpacing.medium, TioSize.dp12);
      expect(TioSpacing.large, TioSize.dp16);
      expect(TioSpacing.extraLarge, TioSize.dp24);
    });

    test('radius roles alias canonical geometry primitives', () {
      expect(TioRadius.small, TioSize.dp8);
      expect(TioRadius.medium, TioSize.dp12);
      expect(TioRadius.large, TioSize.dp16);
      expect(TioRadius.extraLarge, TioSize.dp24);
      expect(TioRadius.full, TioSize.dp999);
    });
  });
}
