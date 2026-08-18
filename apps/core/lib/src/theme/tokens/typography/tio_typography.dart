import 'package:flutter/material.dart';

import '../semantic/tio_colors.dart';
import 'tio_font_family.dart';
import 'tio_font_size.dart';
import 'tio_font_weight.dart';

class TioTypography {
  const TioTypography._();

  static TextTheme textTheme(TioColors colors) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: TioFontFamily.system,
        fontSize: TioFontSize.size36,
        fontWeight: TioFontWeight.w800,
        color: colors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: TioFontFamily.system,
        fontSize: TioFontSize.size24,
        fontWeight: TioFontWeight.w700,
        color: colors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: TioFontFamily.system,
        fontSize: TioFontSize.size20,
        fontWeight: TioFontWeight.w700,
        color: colors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: TioFontFamily.system,
        fontSize: TioFontSize.size16,
        fontWeight: TioFontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: TioFontFamily.system,
        fontSize: TioFontSize.size16,
        fontWeight: TioFontWeight.w400,
        color: colors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: TioFontFamily.system,
        fontSize: TioFontSize.size14,
        fontWeight: TioFontWeight.w400,
        color: colors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: TioFontFamily.system,
        fontSize: TioFontSize.size14,
        fontWeight: TioFontWeight.w700,
        color: colors.textPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: TioFontFamily.system,
        fontSize: TioFontSize.size12,
        fontWeight: TioFontWeight.w600,
        color: colors.textMuted,
      ),
    );
  }
}
