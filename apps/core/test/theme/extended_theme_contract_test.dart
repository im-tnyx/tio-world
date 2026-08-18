import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical extended physical values', () {
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

  group('runtime media color semantics', () {
    test('light scheme resolves current media contract through semantics', () {
      expect(TioColors.light.mediaBackground, TioPalette.black);
      expect(TioColors.light.onMediaPrimary, TioPalette.white);
      expect(TioColors.light.onMediaSecondary, TioPalette.whiteAlpha179);
    });

    test('dark scheme resolves current media contract through semantics', () {
      expect(TioColors.dark.mediaBackground, TioPalette.black);
      expect(TioColors.dark.onMediaPrimary, TioPalette.white);
      expect(TioColors.dark.onMediaSecondary, TioPalette.whiteAlpha179);
    });

    test('oled scheme resolves current media contract through semantics', () {
      expect(TioColors.oled.mediaBackground, TioPalette.black);
      expect(TioColors.oled.onMediaPrimary, TioPalette.white);
      expect(TioColors.oled.onMediaSecondary, TioPalette.whiteAlpha179);
    });
  });
}
