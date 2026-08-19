import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/src/presentation/theme/onboarding_age_dialog_tokens.dart';
import 'package:tio_feature_onboarding/src/presentation/theme/onboarding_modal_tokens.dart';

void main() {
  group('Product Onboarding modal visual contracts', () {
    test('keeps shared modal typography and spacing', () {
      expect(OnboardingModalTokens.titleFontSize, 18.0);
      expect(OnboardingModalTokens.titleFontWeight, FontWeight.w700);
      expect(OnboardingModalTokens.bodyFontSize, 14.0);
      expect(OnboardingModalTokens.titleToBodyGap, 10.0);
      expect(OnboardingModalTokens.actionTopGap, TioSpacing.extraLarge);
    });

    test('keeps exact age-dialog geometry and action palette', () {
      expect(OnboardingAgeDialogTokens.panelRadius, 20.0);
      expect(OnboardingAgeDialogTokens.horizontalInset, 28.0);
      expect(OnboardingAgeDialogTokens.panelBottomPadding, 20.0);
      expect(OnboardingAgeDialogTokens.actionHeight, 48.0);
      expect(OnboardingAgeDialogTokens.actionRadius, 30.0);
      expect(OnboardingAgeDialogTokens.outlinedActionAlpha, 90);
      expect(OnboardingAgeDialogTokens.outlinedActionWidth, 1.5);
      expect(OnboardingAgeDialogTokens.actionLabelFontSize, 15.0);
      expect(
        OnboardingAgeDialogTokens.primaryActionBackgroundColor,
        const Color(0xFFFFFFFF),
      );
      expect(
        OnboardingAgeDialogTokens.primaryActionForegroundColor,
        const Color(0xFF000000),
      );
      expect(OnboardingAgeDialogTokens.rejectionBodyLineHeight, 1.3);
    });
  });
}
