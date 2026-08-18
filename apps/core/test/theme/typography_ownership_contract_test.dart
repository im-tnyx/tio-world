import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical typography physical values', () {
    test('font sizes remain exact', () {
      expect(TioFontSize.size12, 12.0);
      expect(TioFontSize.size13, 13.0);
      expect(TioFontSize.size14, 14.0);
      expect(TioFontSize.size15, 15.0);
      expect(TioFontSize.size16, 16.0);
      expect(TioFontSize.size17, 17.0);
      expect(TioFontSize.size18, 18.0);
      expect(TioFontSize.size20, 20.0);
      expect(TioFontSize.size22, 22.0);
      expect(TioFontSize.size24, 24.0);
      expect(TioFontSize.size28, 28.0);
      expect(TioFontSize.size34, 34.0);
      expect(TioFontSize.size36, 36.0);
    });

    test('font weights alias Flutter physical weights exactly', () {
      expect(TioFontWeight.w400, FontWeight.w400);
      expect(TioFontWeight.w500, FontWeight.w500);
      expect(TioFontWeight.w600, FontWeight.w600);
      expect(TioFontWeight.w700, FontWeight.w700);
      expect(TioFontWeight.w800, FontWeight.w800);
      expect(TioFontWeight.w900, FontWeight.w900);
    });

    test('letter spacing and line height values remain exact', () {
      expect(TioLetterSpacing.negative05, -0.5);
      expect(TioLetterSpacing.negative03, -0.3);
      expect(TioLetterSpacing.negative02, -0.2);
      expect(TioLetterSpacing.positive05, 0.5);
      expect(TioLetterSpacing.positive08, 0.8);
      expect(TioLetterSpacing.positive60, 6.0);

      expect(TioLineHeight.height125, 1.25);
      expect(TioLineHeight.height130, 1.30);
      expect(TioLineHeight.height135, 1.35);
      expect(TioLineHeight.height140, 1.40);
      expect(TioLineHeight.height150, 1.50);
    });

    test('system and named font-family contracts stay distinct', () {
      expect(TioFontFamily.system, isNull);
      expect(TioFontFamily.roboto, 'Roboto');
    });
  });

  test('semantic TextTheme aliases canonical typography primitives', () {
    final textTheme = TioTypography.textTheme(TioColors.light);

    expect(textTheme.displayLarge?.fontFamily, TioFontFamily.system);
    expect(textTheme.displayLarge?.fontSize, TioFontSize.size36);
    expect(textTheme.displayLarge?.fontWeight, TioFontWeight.w800);

    expect(textTheme.headlineMedium?.fontSize, TioFontSize.size24);
    expect(textTheme.headlineMedium?.fontWeight, TioFontWeight.w700);
    expect(textTheme.titleLarge?.fontSize, TioFontSize.size20);
    expect(textTheme.titleMedium?.fontSize, TioFontSize.size16);
    expect(textTheme.titleMedium?.fontWeight, TioFontWeight.w600);
    expect(textTheme.bodyLarge?.fontSize, TioFontSize.size16);
    expect(textTheme.bodyLarge?.fontWeight, TioFontWeight.w400);
    expect(textTheme.bodyMedium?.fontSize, TioFontSize.size14);
    expect(textTheme.labelLarge?.fontSize, TioFontSize.size14);
    expect(textTheme.labelLarge?.fontWeight, TioFontWeight.w700);
    expect(textTheme.labelSmall?.fontSize, TioFontSize.size12);
    expect(textTheme.labelSmall?.fontWeight, TioFontWeight.w600);
  });

  group('reusable component typography contracts', () {
    test('input roles alias canonical typography primitives', () {
      expect(TioInputTokens.compactTextFontSize, TioFontSize.size16);
      expect(TioInputTokens.labelFontSize, TioFontSize.size14);
      expect(TioInputTokens.compactHintFontSize, TioFontSize.size15);
      expect(TioInputTokens.mobileCountryFlagFontSize, TioFontSize.size22);
      expect(TioInputTokens.mobileVerifyLabelFontSize, TioFontSize.size12);
      expect(TioInputTokens.usernameSuggestionFontSize, TioFontSize.size13);
      expect(
        TioInputTokens.mobileTextLetterSpacing,
        TioLetterSpacing.positive05,
      );
    });

    test('dialog roles alias canonical typography primitives', () {
      expect(TioDialogTokens.otpTitleFontSize, TioFontSize.size16);
      expect(
        TioDialogTokens.otpTitleLetterSpacing,
        TioLetterSpacing.negative02,
      );
      expect(TioDialogTokens.otpInputFontSize, TioFontSize.size20);
      expect(
        TioDialogTokens.otpInputLetterSpacing,
        TioLetterSpacing.positive60,
      );
      expect(TioDialogTokens.otpSubtitleLineHeight, TioLineHeight.height135);
      expect(TioDialogTokens.deleteHeadlineFontSize, TioFontSize.size28);
      expect(TioDialogTokens.deleteBodyLineHeight, TioLineHeight.height140);
      expect(TioDialogTokens.deleteCountdownFontSize, TioFontSize.size34);
      expect(
        TioDialogTokens.deleteHoldHeadlineLineHeight,
        TioLineHeight.height125,
      );
    });

    test('picker and supporting roles alias canonical typography primitives', () {
      expect(TioWheelPickerTokens.selectedFontSize, TioFontSize.size22);
      expect(TioDobPickerTokens.titleFontSize, TioFontSize.size22);
      expect(
        TioDobPickerTokens.titleLetterSpacing,
        TioLetterSpacing.negative02,
      );
      expect(TioDobPickerTokens.unselectedFontSize, TioFontSize.size17);
      expect(TioMeasurementPickerTokens.titleFontSize, TioFontSize.size24);
      expect(
        TioMeasurementPickerTokens.titleLetterSpacing,
        TioLetterSpacing.negative03,
      );
      expect(
        TioMeasurementPickerTokens.subtitleLineHeight,
        TioLineHeight.height135,
      );
      expect(TioLegalTokens.defaultFontSize, TioFontSize.size12);
      expect(TioLegalTokens.bodyLineHeight, TioLineHeight.height150);
      expect(
        TioMeasurementPreferenceTokens.sectionLabelFontSize,
        TioFontSize.size13,
      );
      expect(TioRemoveImageSheetTokens.titleFontSize, TioFontSize.size22);
      expect(
        TioRemoveImageSheetTokens.titleLetterSpacing,
        TioLetterSpacing.negative03,
      );
      expect(
        TioAvatarActionSheetTokens.titleFontSize,
        TioFontSize.size18,
      );
    });
  });
}
