import 'package:flutter/material.dart';

import 'tio_theme_config.dart';
import 'tokens/effects/tio_shadows.dart';
import 'tokens/semantic/tio_colors.dart';
import 'tokens/typography/tio_typography.dart';

class TioTheme extends StatelessWidget {
  const TioTheme({
    super.key,
    this.config = const TioThemeConfig(),
    required this.child,
  });

  final TioThemeConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final colors = _resolveColors(systemBrightness);

    return Theme(
      data: ThemeData(
        useMaterial3: config.useMaterial3,
        colorScheme: colors.toColorScheme(),
        scaffoldBackgroundColor: colors.background,
        textTheme: TioTypography.textTheme(colors),
        cardTheme: CardThemeData(
          color: colors.surface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.surfaceVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.surfaceVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
        extensions: <ThemeExtension<dynamic>>[
          colors,
          TioShadows.standard,
        ],
      ),
      child: child,
    );
  }

  TioColors _resolveColors(Brightness systemBrightness) {
    if (config.mode == TioThemeMode.light) return TioColors.light;
    if (config.mode == TioThemeMode.dark) return TioColors.dark;
    if (config.mode == TioThemeMode.oled) return TioColors.oled;
    return systemBrightness == Brightness.dark ? TioColors.dark : TioColors.light;
  }
}
