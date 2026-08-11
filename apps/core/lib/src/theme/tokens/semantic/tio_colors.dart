import 'package:flutter/material.dart';

class TioColors extends ThemeExtension<TioColors> {
  const TioColors({
    required this.isDark,
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceVariant,
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
    primary: Color(0xFF111827),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF9CA3AF),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFDC2626),
    info: Color(0xFF0284C7),
    workout: Color(0xFFEF4444),
    nutrition: Color(0xFF22C55E),
    progress: Color(0xFF8B5CF6),
    coach: Color(0xFF06B6D4),
  );

  static const dark = TioColors(
    isDark: true,
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF111827),
    background: Color(0xFF0B1120),
    surface: Color(0xFF111827),
    surfaceRaised: Color(0xFF1F2937),
    surfaceVariant: Color(0xFF374151),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFFD1D5DB),
    textMuted: Color(0xFF9CA3AF),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF38BDF8),
    workout: Color(0xFFF87171),
    nutrition: Color(0xFF4ADE80),
    progress: Color(0xFFA78BFA),
    coach: Color(0xFF22D3EE),
  );

  static const oled = TioColors(
    isDark: true,
    primary: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    background: Color(0xFF000000),
    surface: Color(0xFF050505),
    surfaceRaised: Color(0xFF101010),
    surfaceVariant: Color(0xFF1F1F1F),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFE5E7EB),
    textMuted: Color(0xFF9CA3AF),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF38BDF8),
    workout: Color(0xFFF87171),
    nutrition: Color(0xFF4ADE80),
    progress: Color(0xFFA78BFA),
    coach: Color(0xFF22D3EE),
  );

  ColorScheme toColorScheme() => ColorScheme.fromSeed(
        seedColor: primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
      ).copyWith(
        onSurface: textPrimary,
        outline: surfaceVariant,
        surfaceContainer: surfaceRaised,
      );

  TioColors get highContrast {
    if (isDark) {
      return copyWith(
        primary: const Color(0xFFFFFFFF),
        onPrimary: const Color(0xFF000000),
        background: const Color(0xFF000000),
        surface: const Color(0xFF050505),
        surfaceRaised: const Color(0xFF111111),
        surfaceVariant: const Color(0xFFD1D5DB),
        textPrimary: const Color(0xFFFFFFFF),
        textSecondary: const Color(0xFFF9FAFB),
        textMuted: const Color(0xFFD1D5DB),
      );
    }

    return copyWith(
      primary: const Color(0xFF000000),
      onPrimary: const Color(0xFFFFFFFF),
      background: const Color(0xFFFFFFFF),
      surface: const Color(0xFFFFFFFF),
      surfaceRaised: const Color(0xFFF9FAFB),
      surfaceVariant: const Color(0xFF374151),
      textPrimary: const Color(0xFF000000),
      textSecondary: const Color(0xFF111827),
      textMuted: const Color(0xFF374151),
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
