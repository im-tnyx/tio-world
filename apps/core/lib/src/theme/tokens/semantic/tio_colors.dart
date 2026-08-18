import 'package:flutter/material.dart';

import '../foundation/tio_palette.dart';

class TioColors extends ThemeExtension<TioColors> {
  const TioColors({
    required this.isDark,
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceVariant,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.workout,
    required this.nutrition,
    required this.progress,
    required this.coach,
  });

  final bool isDark;
  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceVariant;
  final Color outlineStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color workout;
  final Color nutrition;
  final Color progress;
  final Color coach;

  static const light = TioColors(
    isDark: false,
    primary: TioPalette.neutral900,
    onPrimary: TioPalette.white,
    background: TioPalette.slate50,
    surface: TioPalette.white,
    surfaceRaised: TioPalette.white,
    surfaceVariant: TioPalette.neutral200,
    outlineStrong: TioPalette.neutral500,
    textPrimary: TioPalette.neutral900,
    textSecondary: TioPalette.neutral600,
    textMuted: TioPalette.neutral400,
    success: TioPalette.green600,
    warning: TioPalette.amber500,
    danger: TioPalette.red600,
    info: TioPalette.sky600,
    workout: TioPalette.red500,
    nutrition: TioPalette.green500,
    progress: TioPalette.violet500,
    coach: TioPalette.cyan500,
  );

  static const dark = TioColors(
    isDark: true,
    primary: TioPalette.white,
    onPrimary: TioPalette.neutral900,
    background: TioPalette.neutral950,
    surface: TioPalette.neutral900,
    surfaceRaised: TioPalette.neutral800,
    surfaceVariant: TioPalette.neutral700,
    outlineStrong: TioPalette.neutral400,
    textPrimary: TioPalette.neutral50,
    textSecondary: TioPalette.neutral300,
    textMuted: TioPalette.neutral400,
    success: TioPalette.green500,
    warning: TioPalette.amber400,
    danger: TioPalette.red400,
    info: TioPalette.sky400,
    workout: TioPalette.red400,
    nutrition: TioPalette.green400,
    progress: TioPalette.violet400,
    coach: TioPalette.cyan400,
  );

  static const oled = TioColors(
    isDark: true,
    primary: TioPalette.white,
    onPrimary: TioPalette.black,
    background: TioPalette.black,
    surface: TioPalette.gray005,
    surfaceRaised: TioPalette.gray016,
    surfaceVariant: TioPalette.gray031,
    outlineStrong: TioPalette.neutral400,
    textPrimary: TioPalette.white,
    textSecondary: TioPalette.neutral200,
    textMuted: TioPalette.neutral400,
    success: TioPalette.green500,
    warning: TioPalette.amber400,
    danger: TioPalette.red400,
    info: TioPalette.sky400,
    workout: TioPalette.red400,
    nutrition: TioPalette.green400,
    progress: TioPalette.violet400,
    coach: TioPalette.cyan400,
  );

  ColorScheme toColorScheme() => ColorScheme.fromSeed(
        seedColor: primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
      ).copyWith(
        onSurface: textPrimary,
        outline: outlineStrong,
        surfaceContainer: surfaceRaised,
      );

  TioColors get highContrast {
    if (isDark) {
      return copyWith(
        primary: TioPalette.white,
        onPrimary: TioPalette.black,
        background: TioPalette.black,
        surface: TioPalette.gray005,
        surfaceRaised: TioPalette.gray017,
        surfaceVariant: TioPalette.neutral300,
        outlineStrong: TioPalette.white,
        textPrimary: TioPalette.white,
        textSecondary: TioPalette.neutral50,
        textMuted: TioPalette.neutral300,
      );
    }

    return copyWith(
      primary: TioPalette.black,
      onPrimary: TioPalette.white,
      background: TioPalette.white,
      surface: TioPalette.white,
      surfaceRaised: TioPalette.neutral50,
      surfaceVariant: TioPalette.neutral700,
      outlineStrong: TioPalette.black,
      textPrimary: TioPalette.black,
      textSecondary: TioPalette.neutral900,
      textMuted: TioPalette.neutral700,
    );
  }

  @override
  TioColors copyWith({
    bool? isDark,
    Color? primary,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceVariant,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? workout,
    Color? nutrition,
    Color? progress,
    Color? coach,
  }) {
    return TioColors(
      isDark: isDark ?? this.isDark,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      workout: workout ?? this.workout,
      nutrition: nutrition ?? this.nutrition,
      progress: progress ?? this.progress,
      coach: coach ?? this.coach,
    );
  }

  @override
  TioColors lerp(ThemeExtension<TioColors>? other, double t) => this;
}
