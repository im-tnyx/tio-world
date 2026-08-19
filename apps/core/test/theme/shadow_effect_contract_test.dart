import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical shadow effects', () {
    test('soft shadow keeps the audited physical contract', () {
      expect(TioShadowTokens.soft, hasLength(1));

      final shadow = TioShadowTokens.soft.single;
      expect(shadow.blurRadius, TioSize.dp24);
      expect(shadow.spreadRadius, TioSize.dp0);
      expect(shadow.offset, const Offset(TioSize.dp0, TioSize.dp12));
      expect(shadow.color, const Color(0x1A000000));
    });

    test('runtime standard scheme aliases the canonical static contract', () {
      expect(TioShadows.standard.soft, same(TioShadowTokens.soft));
    });
  });
}
