import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('Welcome-evidenced core physical values', () {
    test('geometry stays exact', () {
      expect(TioSize.dp60, 60.0);
    });

    test('normalized opacity stays exact', () {
      expect(TioOpacity.opacity0, 0.0);
      expect(TioOpacity.opacity18, 0.18);
      expect(TioOpacity.opacity94, 0.94);
      expect(TioOpacity.opacity100, 1.0);
    });

    test('media secondary color stays byte exact', () {
      expect(TioAlpha.alpha179, 179);
      expect(TioPalette.whiteAlpha179, const Color(0xB3FFFFFF));
    });

    test('typography values stay exact', () {
      expect(TioFontSize.size9_5, 9.5);
      expect(TioFontSize.size10_5, 10.5);
      expect(TioFontSize.size42, 42.0);
      expect(TioLineHeight.height110, 1.10);
    });
  });
}
