import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical palette physical values', () {
    test('newly centralized theme/effect colors preserve exact ARGB values', () {
      expect(TioPalette.slate50, const Color(0xFFF8FAFC));
      expect(TioPalette.green600, const Color(0xFF16A34A));
      expect(TioPalette.red600, const Color(0xFFDC2626));
      expect(TioPalette.amber400, const Color(0xFFFBBF24));
      expect(TioPalette.red400, const Color(0xFFF87171));
      expect(TioPalette.sky400, const Color(0xFF38BDF8));
      expect(TioPalette.green400, const Color(0xFF4ADE80));
      expect(TioPalette.violet400, const Color(0xFFA78BFA));
      expect(TioPalette.cyan400, const Color(0xFF22D3EE));
      expect(TioPalette.gray005, const Color(0xFF050505));
      expect(TioPalette.gray016, const Color(0xFF101010));
      expect(TioPalette.gray017, const Color(0xFF111111));
      expect(TioPalette.gray031, const Color(0xFF1F1F1F));
      expect(TioPalette.blackAlpha26, const Color(0x1A000000));
    });
  });

  group('theme colors alias the canonical palette', () {
    test('light scheme keeps exact current mappings', () {
      expect(TioColors.light.primary, TioPalette.neutral900);
      expect(TioColors.light.background, TioPalette.slate50);
      expect(TioColors.light.success, TioPalette.green600);
      expect(TioColors.light.danger, TioPalette.red600);
      expect(TioColors.light.workout, TioPalette.red500);
      expect(TioColors.light.coach, TioPalette.cyan500);
    });

    test('dark scheme keeps exact current mappings', () {
      expect(TioColors.dark.background, TioPalette.neutral950);
      expect(TioColors.dark.warning, TioPalette.amber400);
      expect(TioColors.dark.danger, TioPalette.red400);
      expect(TioColors.dark.info, TioPalette.sky400);
      expect(TioColors.dark.nutrition, TioPalette.green400);
      expect(TioColors.dark.progress, TioPalette.violet400);
      expect(TioColors.dark.coach, TioPalette.cyan400);
    });

    test('oled and high-contrast mappings keep exact current values', () {
      expect(TioColors.oled.background, TioPalette.black);
      expect(TioColors.oled.surface, TioPalette.gray005);
      expect(TioColors.oled.surfaceRaised, TioPalette.gray016);
      expect(TioColors.oled.surfaceVariant, TioPalette.gray031);

      final darkHighContrast = TioColors.dark.highContrast;
      expect(darkHighContrast.surface, TioPalette.gray005);
      expect(darkHighContrast.surfaceRaised, TioPalette.gray017);
      expect(darkHighContrast.outlineStrong, TioPalette.white);

      final lightHighContrast = TioColors.light.highContrast;
      expect(lightHighContrast.primary, TioPalette.black);
      expect(lightHighContrast.surfaceRaised, TioPalette.neutral50);
      expect(lightHighContrast.surfaceVariant, TioPalette.neutral700);
    });
  });

  group('domain and effect roles do not own duplicate raw colors', () {
    test('domain defaults alias palette values', () {
      expect(TioDomainColors.workout, TioPalette.red500);
      expect(TioDomainColors.nutrition, TioPalette.green500);
      expect(TioDomainColors.progress, TioPalette.violet500);
      expect(TioDomainColors.coach, TioPalette.cyan500);
      expect(TioDomainColors.recovery, TioPalette.sky400);
    });

    test('soft shadow color aliases exact palette alpha color', () {
      expect(TioAlpha.alpha26, 26);
      expect(TioShadowTokens.softColor, TioPalette.blackAlpha26);
      expect(TioShadows.standard.soft, same(TioShadowTokens.soft));
    });
  });
}
