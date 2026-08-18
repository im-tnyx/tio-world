import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical opacity primitives', () {
    test('normalized opacity values stay exact', () {
      expect(TioOpacity.opacity08, 0.08);
      expect(TioOpacity.opacity09, 0.09);
      expect(TioOpacity.opacity10, 0.10);
      expect(TioOpacity.opacity12, 0.12);
      expect(TioOpacity.opacity14, 0.14);
      expect(TioOpacity.opacity16, 0.16);
      expect(TioOpacity.opacity30, 0.30);
      expect(TioOpacity.opacity35, 0.35);
      expect(TioOpacity.opacity38, 0.38);
      expect(TioOpacity.opacity40, 0.40);
      expect(TioOpacity.opacity45, 0.45);
      expect(TioOpacity.opacity50, 0.50);
      expect(TioOpacity.opacity60, 0.60);
      expect(TioOpacity.opacity70, 0.70);
      expect(TioOpacity.opacity72, 0.72);
    });
  });

  group('canonical exact alpha primitives', () {
    test('0-255 alpha contracts stay byte-exact', () {
      expect(TioAlpha.alpha25, 25);
      expect(TioAlpha.alpha30, 30);
      expect(TioAlpha.alpha35, 35);
      expect(TioAlpha.alpha40, 40);
      expect(TioAlpha.alpha50, 50);
      expect(TioAlpha.alpha80, 80);
      expect(TioAlpha.alpha90, 90);
      expect(TioAlpha.alpha120, 120);
      expect(TioAlpha.alpha200, 200);
      expect(TioAlpha.alpha245, 245);
    });
  });
}
