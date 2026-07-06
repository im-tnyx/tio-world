import 'package:flutter/material.dart';

import 'tio_colors.dart';

class TioTypography {
  const TioTypography._();

  static TextTheme textTheme(TioColors colors) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: colors.textPrimary),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colors.textPrimary),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colors.textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colors.textSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textMuted),
    );
  }
}
