import 'package:flutter/foundation.dart';

@immutable
class WelcomeUiState {
  const WelcomeUiState({
    this.localeCode = 'en',
    this.skipText = 'Skip',
    this.featureLines = const ['AI WORKOUT', 'MEAL PLAN', 'AI COACH'],
    this.ctaText = 'Get Started',
  });

  final String localeCode;
  final String skipText;
  final List<String> featureLines;
  final String ctaText;

  WelcomeUiState copyWith({
    String? localeCode,
    String? skipText,
    List<String>? featureLines,
    String? ctaText,
  }) {
    return WelcomeUiState(
      localeCode: localeCode ?? this.localeCode,
      skipText: skipText ?? this.skipText,
      featureLines: featureLines ?? this.featureLines,
      ctaText: ctaText ?? this.ctaText,
    );
  }
}
