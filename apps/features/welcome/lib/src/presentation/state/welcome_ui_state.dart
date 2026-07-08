import 'package:flutter/foundation.dart';

@immutable
class WelcomeUiState {
  const WelcomeUiState({
    this.localeCode = 'en',
    this.skipText = 'Skip',
    this.title = 'TRAIN.\nEAT.\nEVOLVE.',
    this.featureLines = const ['AI WORKOUT', 'MEAL PLAN', 'AI COACH'],
    this.ctaText = 'Get Started',
    this.signInText = 'Sign In',
    this.termsPrefix = 'By continuing, you agree to our ',
    this.termsText = 'Terms & Conditions',
    this.andText = ' and ',
    this.privacyText = 'Privacy Policy',
  });

  final String localeCode;
  final String skipText;
  final String title;
  final List<String> featureLines;
  final String ctaText;
  final String signInText;
  final String termsPrefix;
  final String termsText;
  final String andText;
  final String privacyText;

  WelcomeUiState copyWith({
    String? localeCode,
    String? skipText,
    String? title,
    List<String>? featureLines,
    String? ctaText,
    String? signInText,
    String? termsPrefix,
    String? termsText,
    String? andText,
    String? privacyText,
  }) {
    return WelcomeUiState(
      localeCode: localeCode ?? this.localeCode,
      skipText: skipText ?? this.skipText,
      title: title ?? this.title,
      featureLines: featureLines ?? this.featureLines,
      ctaText: ctaText ?? this.ctaText,
      signInText: signInText ?? this.signInText,
      termsPrefix: termsPrefix ?? this.termsPrefix,
      termsText: termsText ?? this.termsText,
      andText: andText ?? this.andText,
      privacyText: privacyText ?? this.privacyText,
    );
  }
}
